`include "define.v"
module LSB(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    input wire jump_wrong,
    //to mem_ctrl 
    output wire lsb_read_signal,
    output wire lsb_write_signal,
    output reg[`LSBSIZE] requiring_length,
    output reg[`DATALEN] to_mem_data,
    output reg[`ADDR] mem_addr,
    input wire [`DATALEN] from_mem_data,

    //interact with decoder
    input wire [`ROBINDEX] decoder_rs1_rename,
    input wire [`ROBINDEX] decoder_rs2_rename,
    input wire [`ROBINDEX] decoder_rd_rename,
    input wire [`DATALEN] decoder_rs1_value,
    input wire [`DATALEN] decoder_rs2_value,
    input wire [`IMMLEN] decoder_imm,
    input wire [`OPCODE] decoder_op,

    //from alu cbd
    input wire alu_broadcast,
    input wire [`DATALEN] alu_cbd_value,
    input wire [`ROBINDEX] alu_update_rename,
    //from rob cbd
    input wire rob_broadcast,
    input wire [`DATALEN] rob_cbd_value,
    input wire [`ROBINDEX] rob_update_rename,
    // 将自己load结果发到cbd
    output wire lsb_broadcast,
    output reg [`DATALEN] lsb_cbd_value,
    output reg [`ROBINDEX] lsb_update_rename,
    
    output wire lsb_full
)
reg [`ADDR] pc[`LSBSIZE];
reg [`ROBINDEX] rd_rename[`LSBSIZE];
reg [`DATALEN] rd_value[`LSBSIZE];
reg [`ADDR] destination_mem_addr[`LSBSIZE];
reg [`REGINDEX] destination_reg_index[`LSBSIZE];
reg ready[`LSBSIZE];
reg [`OPCODE] op[`LSBSIZE];
reg [`ADDR]jumping_pc[`LSBSIZE];
reg predictor_jump[`LSBSIZE];

//rob的数据结构应该是一个循环队列，记下头尾,记住顺序
reg [`LSBINDEX] head;
reg [`LSBINDEX] tail;
reg [`LSBINDEX] next_commit;
reg [`LSBINDEX] next_put;
assign next_commit = head % 16;
assign next_put = tail % 16 + 1;

always @(*) begin
    
end
endmodule