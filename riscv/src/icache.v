`include "define.v"

//从mem中预取指令，然后按照pc把指令取给IF
module ICache (
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,

    //IF module
    //IF requires, and ICache gives
    input  wire [    `ADDR] require_addr,
    output wire [`INSTRLEN] if_instr,
    output wire             fetch_success,

    //RAM module(actually is mem_ctrl module)
    //ICache requires, and RAM gives
    input  wire [`INSTRLEN] mem_instr,
    output wire [    `ADDR] mem_addr,
    input  wire             mem_fetch_success
);
  reg                              [`INSTRLEN] icache[`ICSIZE];
  reg                              [  `ICSIZE] valid;
  reg                              [   `ICTAG] tag   [`ICSIZE];

  wire cache_hit = `FALSE;  //todo

  always @(posedge clk) begin
    if (rst) begin
      fetch_success = `FALSE;
    end

    if (!rdy) begin

    end

    if (cache_hit) begin
      fetch_success <= `TRUE;
      instr         <= icache[pc_to_fetch[`ICINDEX]];
    end else begin
      fetch_success                <= mem_fetch_success;
      instr                        <= mem_instr;
      valid[pc_to_fetch[`ICINDEX]] <= `TRUE;
      cache[pc_to_fetch[`ICINDEX]] <= `instr;
      tag[pc_to_fetch[`ICINDEX]]   <= pc_to_fetch[`ICTAG];
    end
  end
endmodule
