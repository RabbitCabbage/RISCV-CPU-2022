`include "define.v"
module LSB(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    // from RS get the rd
    input wire [`ADDR]addr,//如果是l/s指令，则要传进来一个addr
    input wire [`OPLEN] op,
    // from ALU get the result
    input wire [`REGLINE] result,
    
    // to RS the updated reg
    output wire [`REGINDEX] updated_reg_index,
    // to ICache, RS, ROB and LSB
    input wire jump_prediction,
    output wire jump,
    output wire jump_pc
)
endmodule