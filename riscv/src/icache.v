`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"

//从mem中预取指令，然后按照pc把指令取给IF
module ICache (
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,

    //IF module
    //IF requires, and ICache gives
    input wire if_enable,
    input  wire [`ADDR] require_addr,
    output reg [`INSTRLEN] IF_instr,
    output reg fetch_success,

    //RAM module(actually is mem_ctrl module)
    //ICache requires, and RAM gives
    input  wire [`INSTRLEN] mem_instr,
    output reg [`ADDR] mem_addr,
    output reg mem_enable,//需要在mem中进行查找
    input  reg mem_fetch_success
);
  reg [`INSTRLEN] icache[`ICSIZE];
  reg [`ICSIZE] valid;
  reg [`ICTAG] tag[`ICSIZE];
integer i;
  always @(posedge clk) begin
    if (rst) begin
      fetch_success                              <= `FALSE;
      for(i=0;i<`ICSIZESCALAR;i=i+1) begin
        valid[i]                                 <=`FALSE;
      end
    end
    if(rdy==`TRUE && if_enable==`FALSE) begin
          if (valid[require_addr[`ICINDEX]] && (tag[require_addr[`ICTAG]]==require_addr[`ICTAG])) begin
                IF_instr                         <= icache[require_addr[`ICINDEX]];
                fetch_success                    <= `TRUE;
          end else begin
              //否则就miss掉了，需要到memory中进行查找
              if(mem_fetch_success == `TRUE) begin
                  valid[require_addr[`ICINDEX]]  <= `TRUE;
                  tag[require_addr[`ICINDEX]]    <= require_addr[`ICTAG];
                  icache[require_addr[`ICINDEX]] <= mem_instr;
                  fetch_success                  <= `TRUE;
                  IF_instr                       <= mem_instr;
              end else begin
                mem_addr                         <= require_addr;
                mem_enable                       <= `TRUE;
              end
          end
    end
    else begin
      mem_enable                                 <= `FALSE;
      fetch_success                              <= `TRUE;
    end
  end
endmodule
