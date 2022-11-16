`include "define.v"

//从mem中预取指令，然后按照pc把指令取给IF
module ICache (
  //control signals
  input wire clk,
  input wire rst,
  input wire rdy,
  input wire jump_wrong

  //IF module
  //IF requires, and ICache gives
  input wire [`ADDR] require_addr,
  output wire[`INSTRLEN] if_instr,

  //RAM module(actually is mem_ctrl module)
  //ICache requires, and RAM gives
  input wire [`INSTRLEN] mem_instr,
  output wire[`ADDR] mem_addr
);
endmodule
