`include "define.v"
module RS(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire jump_wrong,
    
    //from decoder
    input wire [`INSTRLEN] instr,
    input wire [`REGINDEX] rs1,
    input wire [`REGINDEX] rs2,
    input wire [`IMMLEN] imm,
    input wire [`REGINDEX] rd,

    // to ALU
    output wire [`REGLINE] rs1_value,
    output wire [`REGLINE] rs2_value,
    output wire [`OPLEN] op,
    output wire [`IMMLEN] imm,

    // from ROB whether jump
    input wire jump_wrong,
    
    // from ROB and LSB
    // record the index of this instr in ROB
    // ROB要把写好到reg中的东西返回到RS让它去除renaming
    input wire rob_is_update,
    input wire updated_reg_index,
    //to ROB module    
    output wire [`REGINDEX] rd,
    //to LSB module
    output wire [`ADD] ls_information,
    output wire [`INSTRLEN] instr
)
endmodule