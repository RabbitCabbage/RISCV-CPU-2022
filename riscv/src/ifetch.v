`include "define.v"
module IF(
    input wire clk,
    input wire rst,
    input wire rdy,
    // with regard to jumping
    // from ROB
    input wire jump_wrong,
    input wire[`ADDR] jump_pc_from_rob,
    
    // fetch instr from ICache
    // give out an addr and get an instr
    output reg icache_enable,
    output reg [`ADDR] pc_to_fetch,
    input wire [`INSTRLEN] instr_fetched,
    input wire icache_success,

    // send instr to decoder
    // send out instr and wether jumping
    // if lsb or rob is full, then fetching should be stalled
    input wire stall_IF,
    output wire [`INSTRLEN] instr_to_decode,
    output reg [`ADDR] pc_to_decoder,
    output wire IF_success,

    // from predictor
    
    output wire[`ADDR] instr_to_predictor,
    output wire [`ADDR] instr_pc_to_predictor,
    input wire is_jump_instr,
    input wire jump_prediction,
    input wire [`ADDR] jump_pc_from_predictor
    //表示的是上一个指令是否是跳转指令，以及predict是否跳转
);
reg [`ADDR] pc;

assign IF_success = icache_success;
assign instr_to_decode = instr_fetched;
assign instr_to_predictor = instr_fetched;
assign instr_pc_to_predictor = pc;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        icache_enable <= `FALSE;
        pc <= `NULL32;
    end else if(rdy==`TRUE && stall_IF==`FALSE) begin
        if(jump_wrong==`TRUE) begin
            pc = jump_pc_from_rob;
        end else begin
            if(IF_success == `TRUE) begin//如果之前已经fetch成功了
                pc_to_decoder = pc;
                if(is_jump_instr==`TRUE) begin
                    if(jump_prediction==`TRUE)begin
                        pc = jump_pc_from_predictor;
                    end else begin
                        pc = pc + 4;
                    end
                end else begin
                    pc = pc + 4;
                end
            end
        end
        icache_enable = `TRUE;
        pc_to_fetch = pc;//再去fetch下一个pc
    end
end
endmodule