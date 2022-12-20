`include "define.v"
module Predictor(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire if_success,
    input wire [`ADDR] if_instr_pc_itself,
    input wire[`INSTRLEN] if_instr_to_ask_for_prediction,
    input wire rob_enable_predictor,//每当一次跳完之后，不论是否错都要给predictor一个反馈
    output reg is_jump_instr,
    output reg predicted_jump,
    output reg [`ADDR] predict_jump_pc,
    input wire real_jump_or_not,
    input wire [`PREDICTORINDEX]instr_pc,
    input wire[`ADDR] jump_to_pc_from_rob
);
reg[`INSTRLEN] see_the_instr_now;
reg [`IMMLEN] imm;
always @(posedge clk) begin
    if(rst == `TRUE)begin
        is_jump_instr <= `FALSE;
        predicted_jump <= `FALSE;
    end else if(rdy == `TRUE && if_success == `TRUE) begin
        is_jump_instr = `FALSE;
        predicted_jump = `FALSE;
        predict_jump_pc = if_instr_pc_itself + 4;
        case(if_instr_to_ask_for_prediction[`OPCODE])
            7'd111: begin//jal
                is_jump_instr <= `TRUE;
                predicted_jump <= `TRUE;
                see_the_instr_now = if_instr_to_ask_for_prediction;
                imm = {{12{if_instr_to_ask_for_prediction[31]}},if_instr_to_ask_for_prediction[19:12],if_instr_to_ask_for_prediction[20],if_instr_to_ask_for_prediction[30:21],1'b0};
                predict_jump_pc = if_instr_pc_itself + imm;
            end
            7'd103: begin//jalr
                is_jump_instr <= `TRUE;
                predicted_jump <= `FALSE;
                predict_jump_pc <= if_instr_pc_itself+ 4;//todo 这里需要一个寄存器读取值计算怎么办，就stall？
            end
            7'd99: begin//branch
                is_jump_instr <= `TRUE;
                predicted_jump <= `TRUE;
                imm = {{20{if_instr_to_ask_for_prediction[31]}},if_instr_to_ask_for_prediction[7],if_instr_to_ask_for_prediction[30:25],if_instr_to_ask_for_prediction[11:8],1'b0};
                predict_jump_pc = if_instr_pc_itself+ imm;
            end
            default: begin
            end
        endcase
    end
end
endmodule