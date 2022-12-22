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
    input predictor_enable,
    output wire[`ADDR] instr_to_predictor,
    output reg [`ADDR] instr_pc_to_predictor,
    input wire is_jump_instr,
    input wire jump_prediction,
    input wire [`ADDR] jump_pc_from_predictor
    //表示的是上一个指令是否是跳转指令，以及predict是否跳转
);
reg [`ADDR] pc;

assign IF_success = icache_success;
assign instr_to_decode = instr_fetched;
assign instr_to_predictor = instr_fetched;
always @(posedge IF_success) begin
    instr_pc_to_predictor <= pc;
end

always @(posedge predictor_enable) begin
    
end
integer begin_flag;
reg wait_flag;
always @(posedge predictor_enable) begin
    wait_flag <= `TRUE;
    if(is_jump_instr==`TRUE) begin
                    if(jump_prediction==`TRUE)begin
                        pc <= jump_pc_from_predictor;
                        pc_to_fetch <= jump_pc_from_predictor;
                    end else begin
                        pc <= pc + 4;
                        pc_to_fetch <= pc+4;
                    end
                end else begin
                    pc <= pc + 4;
                    pc_to_fetch <= pc+4;
                end
end
always @(posedge IF_success)begin
    if(IF_success == `TRUE) begin//如果之前已经fetch成功了
        pc_to_decoder <= pc;
        icache_enable <= `FALSE;
    end
end

always @(posedge clk) begin
    if (rst == `TRUE) begin
        icache_enable <= `FALSE;
        pc <= `NULL32;
        begin_flag <= 0;
        wait_flag <= `FALSE;
    end else if(rdy==`TRUE && stall_IF==`FALSE) begin
        if(jump_wrong==`TRUE) begin
            pc = jump_pc_from_rob;
        end else begin
            if(predictor_enable ==`TRUE && wait_flag == `TRUE) begin
                icache_enable <= `TRUE;
                wait_flag <= `FALSE;
            end else if(begin_flag == 0) begin
                begin_flag <= 1;
                icache_enable <= `TRUE;
                pc_to_fetch <= pc;
            end
        end
    end
end
endmodule