`include "define.v"
module ROB(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    //commit to memory
    output wire rob_write_mem,
    output reg [`DATALEN] to_mem_value,
    output reg [`LSBSIZE] to_mem_size,
    output reg [`ADDR] to_mem_addr,
    output wire rob_read_mem,
    input wire [`DATALEN] from_mem_data,
    //commit to register file
    output reg [`REGINDEX] to_reg_rd,
    output reg [`DATALEN] to_reg_value,
    output reg [`ROBINDEX] to_reg_rename,

    //interact with decoderr
    //tell decoder the rob line free
    output reg [`ROBINDEX] rob_free_tag,
    input wire [`ROBINDEX] decoder_rd_rename,
    // decoder fetches value from rob
    input wire [`ROBINDEX] decoder_fetch_rs1_index,
    input wire [`ROBINDEX] decoder_fetch_rs2_index,
    output wire to_decoder_rs1_ready,
    output wire to_decoder_rs2_ready,
    output reg [`DATALEN] to_decoder_rs1_value,
    output reg [`DATALEN] to_decoder_rs2_value,
    input wire [`OPCODE] decoder_op,
    input wire [`ADDR] decoder_pc,
    input wire [`ADDR] decoder_destination_mem_addr,//from lsb
    input wire [`REGINDEX] decoder_destination_reg_index,//from decoder

    input wire alu_broadcast,
    input wire [`DATALEN] alu_cbd_value,
    input wire [`DATALEN] alu_jumping_pc,
    input wire [`ROBINDEX] alu_update_rename,

    input wire lsb_broadcast,
    input wire [`DATALEN] lsb_cbd_value,
    input wire [`DATALEN] lsb_addr,
    input wire [`ROBINDEX] lsb_update_rename,

    output wire rob_broadcast,
    output reg [`ROBINDEX] rob_update_rename,
    output reg [`DATALEN] rob_cbd_value,

    output wire rob_full,
    output wire jump_wrong,
    output reg [`ADDR] jumping_pc
)
reg [`ADDR] pc[`ROBSIZE];
reg [`ROBINDEX] rd_rename[`ROBSIZE];
reg [`DATALEN] rd_value[`ROBSIZE];
reg [`ADDR] destination_mem_addr[`ROBSIZE];
reg [`REGINDEX] destination_reg_index[`ROBSIZE];
reg ready[`ROBSIZE];
reg [`OPCODE] op[`ROBSIZE];
reg [`ADDR]jumping_pc[`ROBSIZE];
reg predictor_jump[`ROBSIZE];

//rob的数据结构应该是一个循环队列，记下头尾,记住顺序
reg [`ROBINDEX] head;
reg [`ROBINDEX] tail;


assign decoder_rs1_value = value[decoder_fetch_rs1_index];
assign decoder_rs2_value = value[decoder_fetch_rs2_index];
assign to_decoder_rs1_ready = ready[decoder_fetch_rs1_index];
assign to_decoder_rs2_ready = ready[decoder_fetch_rs2_index];

always @(*) begin

end
endmodule