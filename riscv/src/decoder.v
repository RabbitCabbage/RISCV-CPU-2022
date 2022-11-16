`include "define.v"

// get instructions from if, 
//and then decode them and send them to rs
module Decoder(
    // control signals
    input wire clk,
    input wire rst,
    input wire rdy,
    // from and to IFetch
    input wire [`INSTRLEN] instr,
    input wire is_jump_instr,
    input wire jump_prediction,
    output wire stall_IF,
    // to RS 
    output wire [`IMMLEN] imm,
    output wire [`REGINDEX] rs1,
    output wire [`REGINDEX] rs2,
    output wire [`REGINDEX] rd,
    output wire [`OPLEN] op
)
endmodule