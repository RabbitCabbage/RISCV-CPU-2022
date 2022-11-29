`include "define.v"
module IF(
    input wire clk,
    input wire rst,
    input wire rdy,
    // with regard to jumping
    // from ROB
    input wire jump_wrong,
    input wire[`ADDR] jump_pc,
    
    // fetch instr from ICache
    // give out an addr and get an instr
    output wire icache_enable,
    output wire [`ADDR] pc_to_fetch,
    input wire [`INSTRLEN] instr_fetched,
    input wire icache_success,

    // send instr to decoder
    // send out instr and wether jumping
    // if lsb or rob is full, then fetching should be stalled
    input wire stall_IF;
    output wire [`INSTRLEN] instr_to_decode,
    output wire decoder_enable,

    // from predictor
    input wire is_jump_instr,
    input wire jump_prediction,
    input wire[`ADDR] predict_jump_pc,
    //表示的是上一个指令是否是跳转指令，以及predict是否跳转
)
reg [`ADDR] pc;
always @(posedge clk) begin
    if (rst) begin
        icache_enable <= `FALSE;
        pc_to_fetch <= NULL32;
    end
    if(rdy==`TRUE && stall_IF==`FALSE) begin
        if(jump_wrong==`TRUE) begin
            pc_to_fetch <= jump_pc;
        end else begin
            if(is_jump_instr==`TRUE) begin
                if(jump_prediction==`TRUE)begin
                    pc_to_fetch <= predict_jump_pc;
                end else begin
                    pc_to_fetch <= pc + 3'100;
                end
            end
        end
        icahce_enable <= `TRUE;
        if(icache_success ==`TRUE) begin
            instr_to_decode <= instr_fetched;
            decoder_enable <= `TRUE;
        end
    end
end
endmodule