// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "define.v"
`include "alu.v"
`include "decoder.v"
`include "icache.v"
`include "ifetch.v"
`include "hci.v"
`include "lsb.v"
`include "mem_ctrl.v"
`include "ram.v"
`include "reg_file.v"
`include "riscv_top.v"
`include "rob.v"
`include "rs.v"
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
wire jump_wrong_from_rob;
wire [`ADDR] jumping_pc_from_rob;
wire ifetch_enable_icache;
wire [`ADDR] ifetch_pc;
wire [`INSTRLEN] icache_instr_to_if;
wire icache_success;
wire RS_full;
wire ROB_full;
wire LSB_full;
wire stall_IF;
assign stall_IF = (ROB_full||RS_full||LSB_full);
wire [`INSTRLEN] if_instr_to_decoder;
wire IF_success;
wire is_jump_instr;
wire jump_prediction;

IF ifetch(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .jump_wrong(jump_wrong_from_rob),.jump_pc(jumping_pc_from_rob),
  .icache_enable(ifetch_enable_icache),.pc_to_fetch(ifetch_pc),.instr_fetched(icache_instr_to_if),.icache_success(icache_success),
  .stall_IF(stall_IF),.instr_to_decode(if_instr_to_decoder),.IF_success(IF_success),
  .is_jump_instr(is_jump_instr),.jump_prediction(jump_prediction)
);

wire [`INSTRLEN] mem_instr_to_icache;
wire [`ADDR] icache_pc;
wire icache_enable_mem;
wire mem_success_to_icache;

ICache icache(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .stall_IF(stall_IF),.require_addr(ifetch_pc),.IF_instr(icache_instr_to_if),.fetch_success(IF_success),
  .mem_instr(mem_instr_to_icache),.mem_addr(icache_pc),.mem_enable(icache_enable_mem),mem_fetch_success(mem_success_to_icache)
);

wire decode_success;
wire [`ROBINDEX] decoder_rs1_rename_to_RS;
wire [`ROBINDEX] decoder_rs2_rename_to_RS;
wire [`ROBINDEX] decoder_rd_rename_to_RS;
wire [`DATALEN] decoder_rs1_value_to_RS;
wire [`DATALEN] decoder_rs2_value_to_RS;
wire [`IMMLEN] decoder_imm_to_RS;
wire [`OPCODE] decoder_op_to_RS;
wire [`ROBINDEX] decoder_rs1_rename_to_LSB;
wire [`ROBINDEX] decoder_rs2_rename_to_LSB;
wire [`ROBINDEX] decoder_rd_rename_to_LSB;
wire [`DATALEN] decoder_rs1_value_to_LSB;
wire [`DATALEN] decoder_rs2_value_to_LSB;
wire [`IMMLEN] decoder_imm_to_LSB;
wire [`OPCODE] decoder_op_to_LSB;
wire [`ADDR] decoder_pc;
wire [`ROBINDEX] reg_rs1_rename_to_decoder;
wire [`ROBINDEX] reg_rs2_rename_to_decoder;
wire [`DATALEN] reg_rs1_value_to_decoder;
wire [`DATALEN] reg_rs2_value_to_decoder;
wire reg_rs1_busy;
wire reg_rs2_busy;
wire [`REGINDEX] decoder_rs1_index_to_reg;
wire [`REGINDEX] decoder_rs2_index_to_reg;
wire [`ROBINDEX] decoder_rd_rename_to_reg;
wire [`ROBINDEX] rob_freetag_to_decoder;
wire [`ROBINDEX] decoder_rd_rename_to_ROB;
wire [`ROBINDEX] decoder_rs1_rename_to_ROB;
wire [`ROBINDEX] decoder_rs2_rename_to_ROB;
wire [`DATALEN] decoder_rs1_value_to_ROB;
wire [`DATALEN] decoder_rs2_value_to_ROB;
wire [`OPCODE] decoder_op_to_ROB;
wire ROB_rs1_ready;
wire ROB_rs2_ready;
wire [`REGINDEX] decoder_rd_index_to_ROB;
wire decoder_success;

Decoder decoder(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .IF_success(IF_success),.instr(if_instr_to_decoder),.fetch_pc(ifetch_pc), 
  .decode_success(decode_success),
  .to_rs_rs1_rename(decoder_rs1_rename_to_RS),.to_rs_rs2_rename(decoder_rs2_rename_to_RS),.to_rs_rd_rename(decoder_rd_rename_to_RS),.to_rs_rs1_value(decoder_rs1_value_to_RS),.to_rs_rs2_value(decoder_rs2_value_to_RS),.to_rs_imm(decoder_imm_to_RS),.to_rs_op(decoder_op_to_RS),.decode_pc(decoder_pc),.to_lsb_rs1_rename(decoder_rs1_rename_to_LSB),.to_lsb_rs2_rename(decoder_rs2_rename_to_LSB),.to_lsb_rd_rename(decoder_rd_rename_to_LSB),.to_lsb_rs1_value(decoder_rs1_value_to_LSB),.to_lsb_rs2_value(decoder_rs2_value_to_LSB),.to_lsb_imm(decoder_imm_to_LSB),.to_lsb_op(decoder_op_to_LSB),
  .from_reg_rs1_rob_rename(reg_rs1_rename_to_decoder),.from_reg_rs2_rob_rename(reg_rs2_rename_to_decoder),.reg_rs1_value(reg_rs1_value_to_decoder),.reg_rs2_value(reg_rs2_to_decoder),.reg_rs1_busy(reg_rs1_busy),.reg_rs2_busy(reg_rs2_busy),.to_reg_rs1_index(decoder_rs1_index_to_reg),.to_reg_rs2_index(decoder_rs2_index_to_reg),.to_reg_rd_rename(decoder_rd_rename_to_reg),
  .rob_free_tag(rob_freetag_to_decoder),.to_rob_rd_rename(decoder_rd_rename_to_ROB),.rob_fetch_rs1_rename(decoder_rs1_rename_to_ROB),.rob_fetch_rs2_rename(decoder_rs2_rename_to_ROB),.rob_fetch_rs1_value(decoder_rs1_value_to_ROB),.rob_fetch_rs2_value(decoder_rs2_value_to_ROB),.rob_rs1_ready(ROB_rs1_ready),.rob_rs2_ready(ROB_rs2_ready),.to_rob_op(decoder_op_to_ROB),.to_rob_destination_reg_index(decoder_rd_index_to_ROB)
);

wire ALU_broadcast;
wire [`DATALEN] ALU_broadcast_value;
wire [`ROBINDEX] ALU_broadcast_rename;
wire LSB_broadcast;
wire [`DATALEN] LSB_broadcast_value;
wire [`ROBINDEX] LSB_broadcast_rename;
wire ROB_broadcast;
wire [`DATALEN] ROB_broadcast_value;
wire [`ROBINDEX] ROB_broadcast_rename;
wire RS_enable_ALU;
wire [`ROBINDEX] RS_rd_rename_to_ALU;
wire [`DATALEN] RS_rs1_value_to_ALU;
wire [`DATALEN] RS_rs2_value_to_ALU;
wire [`OPCODE] RS_op_to_ALU;
wire [`ADDR] RS_pc_to_ALU;

RS rs(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .decode_success(decoder_success),.decode_rs1_rename(decoder_rs1_rename_to_RS),.decode_rs2_rename(decoder_rs2_rename_to_RS),.decode_rs1_value(decoder_rs1_value_to_RS),.decode_rs2_value(decoder_rs2_value_to_RS),.decode_imm(decoder_imm_to_RS),.decode_rd_rename(decoder_rd_rename_to_RS),.decode_op(decoder_op_to_RS),.decode_pc(decoder_pc),
  .alu_broadcast(ALU_broadcast),.alu_cbd_value(ALU_broadcast_value),.alu_update_rename(ALU_broadcast_rename),.lsb_broadcast(LSB_broadcast),.lsb_cbd_value(LSB_broadcast_value),.lsb_update_rename(LSB_broadcast_rename),.rob_broadcast(ROB_broadcast),.rob_cbd_value(ROB_broadcast_value),.rob_update_rename(ROB_broadcast_rename),
  //hello
  .to_rob_rd_rename(decoder_rd_rename_to_ROB),.rob_fetch_rs1_rename(decoder_rs1_rename_to_ROB),.rob_fetch_rs2_rename(decoder_rs2_rename_to_ROB),.rob_fetch_rs1_value(decoder_rs1_value_to_ROB),.rob_fetch_rs2_value(decoder_rs2_value_to_ROB),.rob_rs1_ready(ROB_rs1_ready),.rob_rs2_ready(ROB_rs2_ready),.to_rob_op(decoder_op_to_ROB),.to_rob_destination_reg_index(decoder_rd_index_to_ROB)
);

LSB lsb(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .IF_success(IF_success),.instr(if_instr_to_decoder),.fetch_pc(ifetch_pc), 
  .decode_success(decode_success),
  .to_rs_rs1_rename(decoder_rs1_rename_to_RS),.to_rs_rs2_rename(decoder_rs2_rename_to_RS),.to_rs_rd_rename(decoder_rd_rename_to_RS),.to_rs_rs1_value(decoder_rs1_value_to_RS),.to_rs_rs2_value(decoder_rs2_value_to_RS),.to_rs_imm(decoder_imm_to_RS),.to_rs_op(decoder_op_to_RS),.decode_pc(decoder_pc),.to_lsb_rs1_rename(decoder_rs1_rename_to_LSB),.to_lsb_rs2_rename(decoder_rs2_rename_to_LSB),.to_lsb_rd_rename(decoder_rd_rename_to_LSB),.to_lsb_rs1_value(decoder_rs1_value_to_LSB),.to_lsb_rs2_value(decoder_rs2_value_to_LSB),.to_lsb_imm(decoder_imm_to_LSB),.to_lsb_op(decoder_op_to_LSB),
  .from_reg_rs1_rob_rename(reg_rs1_rename_to_decoder),.from_reg_rs2_rob_rename(reg_rs2_rename_to_decoder),.reg_rs1_value(reg_rs1_value_to_decoder),.reg_rs2_value(reg_rs2_to_decoder),.reg_rs1_busy(reg_rs1_busy),.reg_rs2_busy(reg_rs2_busy),.to_reg_rs1_index(decoder_rs1_index_to_reg),.to_reg_rs2_index(decoder_rs2_index_to_reg),.to_reg_rd_rename(decoder_rd_rename_to_reg),
  .rob_free_tag(rob_freetag_to_decoder),.to_rob_rd_rename(decoder_rd_rename_to_ROB),.rob_fetch_rs1_rename(decoder_rs1_rename_to_ROB),.rob_fetch_rs2_rename(decoder_rs2_rename_to_ROB),.rob_fetch_rs1_value(decoder_rs1_value_to_ROB),.rob_fetch_rs2_value(decoder_rs2_value_to_ROB),.rob_rs1_ready(ROB_rs1_ready),.rob_rs2_ready(ROB_rs2_ready),.to_rob_op(decoder_op_to_ROB),.to_rob_destination_reg_index(decoder_rd_index_to_ROB)
);

ROB rob(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .decode_success(decoder_success),.decode_rs1_rename(decoder_rs1_rename_to_RS),.decode_rs2_rename(decoder_rs2_rename_to_RS),.decode_rs1_value(decoder_rs1_value_to_RS),.decode_rs2_value(decoder_rs2_value_to_RS),.decode_imm(decoder_imm_to_RS),.decode_rd_rename(decoder_rd_rename_to_RS),.decode_op(decoder_op_to_RS),.decode_pc(decoder_pc),
  .alu_broadcast(ALU_broadcast),.alu_cbd_value(ALU_broadcast_value),.alu_update_rename(ALU_broadcast_rename),.lsb_broadcast(LSB_broadcast),.lsb_cbd_value(LSB_broadcast_value),.lsb_update_rename(LSB_broadcast_rename),.rob_broadcast(ROB_broadcast),.rob_cbd_value(ROB_broadcast_value),.rob_update_rename(ROB_broadcast_rename),
  //hello
  .to_rob_rd_rename(decoder_rd_rename_to_ROB),.rob_fetch_rs1_rename(decoder_rs1_rename_to_ROB),.rob_fetch_rs2_rename(decoder_rs2_rename_to_ROB),.rob_fetch_rs1_value(decoder_rs1_value_to_ROB),.rob_fetch_rs2_value(decoder_rs2_value_to_ROB),.rob_rs1_ready(ROB_rs1_ready),.rob_rs2_ready(ROB_rs2_ready),.to_rob_op(decoder_op_to_ROB),.to_rob_destination_reg_index(decoder_rd_index_to_ROB)
);

RegFile regfile(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .IF_success(IF_success),.instr(if_instr_to_decoder),.fetch_pc(ifetch_pc), 
  .decode_success(decode_success),
  .to_rs_rs1_rename(decoder_rs1_rename_to_RS),.to_rs_rs2_rename(decoder_rs2_rename_to_RS),.to_rs_rd_rename(decoder_rd_rename_to_RS),.to_rs_rs1_value(decoder_rs1_value_to_RS),.to_rs_rs2_value(decoder_rs2_value_to_RS),.to_rs_imm(decoder_imm_to_RS),.to_rs_op(decoder_op_to_RS),.decode_pc(decoder_pc),.to_lsb_rs1_rename(decoder_rs1_rename_to_LSB),.to_lsb_rs2_rename(decoder_rs2_rename_to_LSB),.to_lsb_rd_rename(decoder_rd_rename_to_LSB),.to_lsb_rs1_value(decoder_rs1_value_to_LSB),.to_lsb_rs2_value(decoder_rs2_value_to_LSB),.to_lsb_imm(decoder_imm_to_LSB),.to_lsb_op(decoder_op_to_LSB),
  .from_reg_rs1_rob_rename(reg_rs1_rename_to_decoder),.from_reg_rs2_rob_rename(reg_rs2_rename_to_decoder),.reg_rs1_value(reg_rs1_value_to_decoder),.reg_rs2_value(reg_rs2_to_decoder),.reg_rs1_busy(reg_rs1_busy),.reg_rs2_busy(reg_rs2_busy),.to_reg_rs1_index(decoder_rs1_index_to_reg),.to_reg_rs2_index(decoder_rs2_index_to_reg),.to_reg_rd_rename(decoder_rd_rename_to_reg),
  .rob_free_tag(rob_freetag_to_decoder),.to_rob_rd_rename(decoder_rd_rename_to_ROB),.rob_fetch_rs1_rename(decoder_rs1_rename_to_ROB),.rob_fetch_rs2_rename(decoder_rs2_rename_to_ROB),.rob_fetch_rs1_value(decoder_rs1_value_to_ROB),.rob_fetch_rs2_value(decoder_rs2_value_to_ROB),.rob_rs1_ready(ROB_rs1_ready),.rob_rs2_ready(ROB_rs2_ready),.to_rob_op(decoder_op_to_ROB),.to_rob_destination_reg_index(decoder_rd_index_to_ROB)
);

ALU alu(
  .clk(clk_in),.rst(rst_in),.rdy(rdy_in),
  .IF_success(IF_success),.instr(if_instr_to_decoder),.fetch_pc(ifetch_pc), 
  .decode_success(decode_success),
  .to_rs_rs1_rename(decoder_rs1_rename_to_RS),.to_rs_rs2_rename(decoder_rs2_rename_to_RS),.to_rs_rd_rename(decoder_rd_rename_to_RS),.to_rs_rs1_value(decoder_rs1_value_to_RS),.to_rs_rs2_value(decoder_rs2_value_to_RS),.to_rs_imm(decoder_imm_to_RS),.to_rs_op(decoder_op_to_RS),.decode_pc(decoder_pc),.to_lsb_rs1_rename(decoder_rs1_rename_to_LSB),.to_lsb_rs2_rename(decoder_rs2_rename_to_LSB),.to_lsb_rd_rename(decoder_rd_rename_to_LSB),.to_lsb_rs1_value(decoder_rs1_value_to_LSB),.to_lsb_rs2_value(decoder_rs2_value_to_LSB),.to_lsb_imm(decoder_imm_to_LSB),.to_lsb_op(decoder_op_to_LSB),
);
endmodule