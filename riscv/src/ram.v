`include "define.v"
module RAM(
  // control signals
  input wire clk,
  input wire chip_enable,
  input wire read_write,
  input wire [`ADDR] mem_addr,
  input wire [`BYTELEN] mem_data_write,
  output wire [`BYTELEN] mem_data_read,
)

endmodule