`include "define.v"
module RegFile(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,

    // from RS
    input wire [`REGINDEX] rs1,
    input wire [`REGINDEX] rs2,
    input wire rs1_ready,
    input wire rs2_ready,
    // to ALU
    output wire [`DATALEN] rs1_value,
    output wire [`DATALEN] rs2_value,
    // from ROB
    input wire jump_wrong,
    input wire [`REGINDEX] updated_index,
    input wire [`DATALEN] updated_value,
)
reg [`REGSIZE] reg_value [`DATALEN];
reg [`REGSIZE] reg_status;
reg [`REGSIZE] reg_is_renamed;
reg [`REGSIZE] reg_rename [`RSSIZE]//用RS的标号来rename用这条指令作为结果的寄存器
endmodule