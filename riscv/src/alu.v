`include "define.v"

module ALU(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    //from RS
    input wire [`IMMLEN] imm,
    input wire [`REGLINE] rs1_value,
    input wire [`REGLINE] rs2_value,
    input wire [`OPLEN] op,
    
    // to ROB
    output wire [`REGLINE] rd_value,
    output wire [`REGLINE] ls_result,
)
endmodule