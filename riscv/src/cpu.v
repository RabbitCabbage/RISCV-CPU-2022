// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/alu.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/decoder.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/icache.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/ifetch.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/hci.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/lsb.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/mem_ctrl.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/ram.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/reg_file.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/riscv_top.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/rob.v"
`include "D:/Desktop/RISCV-CPU-2022/riscv/src/rs.v"
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

  ICache inst_ICache
    (
      .clk               (clk),
      .rst               (rst),
      .rdy               (rdy),
      .stall_IF          (stall_IF),
      .require_addr      (require_addr),
      .IF_instr          (IF_instr),
      .fetch_success     (fetch_success),
      .mem_instr         (mem_instr),
      .mem_addr          (mem_addr),
      .mem_enable        (mem_enable),
      .mem_fetch_success (mem_fetch_success)
    );
  IF inst_IF
    (
      .clk             (clk),
      .rst             (rst),
      .rdy             (rdy),
      .jump_wrong      (jump_wrong),
      .jump_pc         (jump_pc),
      .icache_enable   (icache_enable),
      .pc_to_fetch     (pc_to_fetch),
      .instr_fetched   (instr_fetched),
      .icache_success  (icache_success),
      .stall_IF        (stall_IF),
      .instr_to_decode (instr_to_decode),
      .IF_success      (IF_success),
      .is_jump_instr   (is_jump_instr),
      .jump_prediction (jump_prediction)
    );
      MemCtrl inst_MemCtrl
    (
      .clk                (clk),
      .rdy                (rdy),
      .rst                (rst),
      .clr                (clr),
      .lsb_write_signal   (lsb_write_signal),
      .lsb_read_signal    (lsb_read_signal),
      .lsb_addr           (lsb_addr),
      .lsb_len            (lsb_len),
      .lsb_write_data     (lsb_write_data),
      .lsb_read_data      (lsb_read_data),
      .lsb_success        (lsb_success),
      .icache_addr        (icache_addr),
      .icache_read_signal (icache_read_signal),
      .icache_read_instr  (icache_read_instr),
      .icache_success     (icache_success),
      .io_buffer_full     (io_buffer_full),
      .mem_addr           (mem_addr),
      .mem_byte_write     (mem_byte_write),
      .mem_byte_read      (mem_byte_read),
      .read_write         (read_write)
    );
  Decoder inst_Decoder
    (
      .clk                          (clk),
      .rst                          (rst),
      .rdy                          (rdy),
      .IF_success                   (IF_success),
      .instr                        (instr),
      .fetch_pc                     (fetch_pc),
      .decode_success               (decode_success),
      .to_rs_rs1_rename             (to_rs_rs1_rename),
      .to_rs_rs2_rename             (to_rs_rs2_rename),
      .to_rs_rd_rename              (to_rs_rd_rename),
      .to_rs_imm                    (to_rs_imm),
      .to_rs_rs1_value              (to_rs_rs1_value),
      .to_rs_rs2_value              (to_rs_rs2_value),
      .to_rs_op                     (to_rs_op),
      .decode_pc                    (decode_pc),
      .to_lsb_rs1_rename            (to_lsb_rs1_rename),
      .to_lsb_rs2_rename            (to_lsb_rs2_rename),
      .to_lsb_rd_rename             (to_lsb_rd_rename),
      .to_lsb_rs1_value             (to_lsb_rs1_value),
      .to_lsb_rs2_value             (to_lsb_rs2_value),
      .to_lsb_imm                   (to_lsb_imm),
      .to_lsb_op                    (to_lsb_op),
      .from_reg_rs1_rob_rename      (from_reg_rs1_rob_rename),
      .from_reg_rs2_rob_rename      (from_reg_rs2_rob_rename),
      .reg_rs1_value                (reg_rs1_value),
      .reg_rs2_value                (reg_rs2_value),
      .reg_rs1_busy                 (reg_rs1_busy),
      .reg_rs2_busy                 (reg_rs2_busy),
      .to_reg_rs1_index             (to_reg_rs1_index),
      .to_reg_rs2_index             (to_reg_rs2_index),
      .to_reg_rd_rename             (to_reg_rd_rename),
      .rob_free_tag                 (rob_free_tag),
      .to_rob_rd_rename             (to_rob_rd_rename),
      .rob_fetch_rs1_value          (rob_fetch_rs1_value),
      .rob_rs1_ready                (rob_rs1_ready),
      .rob_fetch_rs2_value          (rob_fetch_rs2_value),
      .rob_rs2_ready                (rob_rs2_ready),
      .rob_fetch_rs1_index          (rob_fetch_rs1_index),
      .rob_fetch_rs2_index          (rob_fetch_rs2_index),
      .to_rob_op                    (to_rob_op),
      .to_rob_destination_reg_index (to_rob_destination_reg_index)
    );
  RS inst_RS
    (
      .clk                (clk),
      .rst                (rst),
      .rdy                (rdy),
      .clr                (clr),
      .decode_success     (decode_success),
      .decode_rs1_rename  (decode_rs1_rename),
      .decode_rs2_rename  (decode_rs2_rename),
      .decode_rs1_value   (decode_rs1_value),
      .decode_rs2_value   (decode_rs2_value),
      .decode_imm         (decode_imm),
      .decode_rd_rename   (decode_rd_rename),
      .decode_op          (decode_op),
      .decode_pc          (decode_pc),
      .alu_broadcast      (alu_broadcast),
      .alu_cbd_value      (alu_cbd_value),
      .alu_update_rename  (alu_update_rename),
      .lsb_broadcast      (lsb_broadcast),
      .lsb_cbd_value      (lsb_cbd_value),
      .lsb_update_rename  (lsb_update_rename),
      .rob_broadcast      (rob_broadcast),
      .rob_cbd_value      (rob_cbd_value),
      .rob_update_rename  (rob_update_rename),
      .alu_enable         (alu_enable),
      .to_alu_rd_renaming (to_alu_rd_renaming),
      .to_alu_rs1_value   (to_alu_rs1_value),
      .to_alu_rs2_value   (to_alu_rs2_value),
      .to_alu_op          (to_alu_op),
      .to_alu_imm         (to_alu_imm),
      .to_alu_pc          (to_alu_pc),
      .rs_full            (rs_full)
    );
  ALU inst_ALU
    (
      .clk           (clk),
      .rdy           (rdy),
      .rst           (rst),
      .alu_enable    (alu_enable),
      .in_rd_rename  (in_rd_rename),
      .instr_pc      (instr_pc),
      .imm           (imm),
      .rs1_value     (rs1_value),
      .rs2_value     (rs2_value),
      .op            (op),
      .result        (result),
      .alu_broadcast (alu_broadcast),
      .out_rd_rename (out_rd_rename),
      .jumping_pc    (jumping_pc)
    );
  RegFile inst_RegFile
    (
      .clk                    (clk),
      .rst                    (rst),
      .rdy                    (rdy),
      .from_decoder_rs1_index (from_decoder_rs1_index),
      .from_decoder_rs2_index (from_decoder_rs2_index),
      .from_decoder_rd_index  (from_decoder_rd_index),
      .decoder_rd_rename      (decoder_rd_rename),
      .rs1_renamed            (rs1_renamed),
      .rs2_renamed            (rs2_renamed),
      .to_decoder_rs1_value   (to_decoder_rs1_value),
      .to_decoder_rs2_value   (to_decoder_rs2_value),
      .to_decoder_rs1_rename  (to_decoder_rs1_rename),
      .to_decoder_rs2_rename  (to_decoder_rs2_rename),
      .rob_commit_index       (rob_commit_index),
      .rob_commit_rename      (rob_commit_rename),
      .rob_commit_value       (rob_commit_value),
      .jump_wrong             (jump_wrong)
    );
  ROB inst_ROB
    (
      .clk                           (clk),
      .rdy                           (rdy),
      .rst                           (rst),
      .rob_write_mem                 (rob_write_mem),
      .to_mem_value                  (to_mem_value),
      .to_mem_size                   (to_mem_size),
      .to_mem_addr                   (to_mem_addr),
      .rob_read_mem                  (rob_read_mem),
      .from_mem_data                 (from_mem_data),
      .to_reg_rd                     (to_reg_rd),
      .to_reg_value                  (to_reg_value),
      .to_reg_rename                 (to_reg_rename),
      .rob_free_tag                  (rob_free_tag),
      .decoder_input_enable          (decoder_input_enable),
      .decoder_rd_rename             (decoder_rd_rename),
      .decoder_fetch_rs1_index       (decoder_fetch_rs1_index),
      .decoder_fetch_rs2_index       (decoder_fetch_rs2_index),
      .to_decoder_rs1_ready          (to_decoder_rs1_ready),
      .to_decoder_rs2_ready          (to_decoder_rs2_ready),
      .to_decoder_rs1_value          (to_decoder_rs1_value),
      .to_decoder_rs2_value          (to_decoder_rs2_value),
      .decoder_op                    (decoder_op),
      .decoder_pc                    (decoder_pc),
      .predicted_jump                (predicted_jump),
      .decoder_destination_mem_addr  (decoder_destination_mem_addr),
      .decoder_destination_reg_index (decoder_destination_reg_index),
      .alu_broadcast                 (alu_broadcast),
      .alu_cbd_value                 (alu_cbd_value),
      .alu_jumping_pc                (alu_jumping_pc),
      .alu_update_rename             (alu_update_rename),
      .lsb_broadcast                 (lsb_broadcast),
      .lsb_cbd_value                 (lsb_cbd_value),
      .lsb_addr                      (lsb_addr),
      .lsb_update_rename             (lsb_update_rename),
      .rob_broadcast                 (rob_broadcast),
      .rob_update_rename             (rob_update_rename),
      .rob_cbd_value                 (rob_cbd_value),
      .rob_full                      (rob_full),
      .jump_wrong                    (jump_wrong),
      .jumping_pc                    (jumping_pc),
      .to_predictor_enable           (to_predictor_enable),
      .to_predictor_jump             (to_predictor_jump),
      .to_predictor_pc               (to_predictor_pc)
    );
  LSB inst_LSB
    (
      .clk                (clk),
      .rdy                (rdy),
      .rst                (rst),
      .jump_wrong         (jump_wrong),
      .lsb_read_signal    (lsb_read_signal),
      .lsb_write_signal   (lsb_write_signal),
      .requiring_length   (requiring_length),
      .to_mem_data        (to_mem_data),
      .to_mem_addr        (to_mem_addr),
      .load_signed        (load_signed),
      .mem_load_success   (mem_load_success),
      .from_mem_data      (from_mem_data),
      .decode_signal      (decode_signal),
      .decoder_rs1_rename (decoder_rs1_rename),
      .decoder_rs2_rename (decoder_rs2_rename),
      .decoder_rd_rename  (decoder_rd_rename),
      .decoder_rs1_value  (decoder_rs1_value),
      .decoder_rs2_value  (decoder_rs2_value),
      .decoder_imm        (decoder_imm),
      .decoder_op         (decoder_op),
      .alu_broadcast      (alu_broadcast),
      .alu_cbd_value      (alu_cbd_value),
      .alu_update_rename  (alu_update_rename),
      .rob_broadcast      (rob_broadcast),
      .rob_cbd_value      (rob_cbd_value),
      .rob_update_rename  (rob_update_rename),
      .lsb_broadcast      (lsb_broadcast),
      .lsb_cbd_value      (lsb_cbd_value),
      .lsb_update_rename  (lsb_update_rename),
      .lsb_full           (lsb_full)
    );


endmodule