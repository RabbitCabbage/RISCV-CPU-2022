`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"
module Predictor(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire if_ask_for_prediction,
    input wire rob_enable_predictor,//每当一次跳完之后，不论是否错都要给predictor一个反馈
    output reg predicted_jump,
    input wire real_jump_or_not,
    input wire [`PREDICTORINDEX]instr_pc,
    input wire[`ADDR] jump_to_pc
    
);
always @(posedge clk) begin 
    predicted_jump <= `TRUE;
end
endmodule