`include "define.v"
module RegFile(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,

    //interact with decoder
    input wire [`REGINDEX] from_decoder_rs1_index,
    input wire [`REGINDEX] from_decoder_rs2_index,
    input wire [`ROBINDEX] decoder_rd_rename,
    output wire rs1_busy,
    output wire rs2_busy,
    output reg [`DATALEN] to_decoder_rs1_value,
    output reg [`DATALEN] to_decoder_rs2_value,
    output reg [`ROBINDEX] to_decoder_rs1_rename,
    output reg [`ROBINDEX] to_decoder_rs2_rename,

    // from ROB
    input wire [`REGINDEX] rob_update_index,
    input wire [`ROBINDEX] rob_update_rename,
    input wire [`DATALEN] rob_updated_value,
)
reg [`DATALEN] reg_value [`REGSIZE];
reg reg_status[`REGSIZE];
reg busy[`REGSIZE];
reg [`ROBINDEX] reg_rename [`REGSIZE]//用RS的标号来rename用这条指令作为结果的寄存器
endmodule