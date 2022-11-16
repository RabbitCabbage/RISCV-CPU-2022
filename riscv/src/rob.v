`include "define.v"
module ROB(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    // from RS get the rd
    input wire [`REGINDEX] rd,//如果是向寄存器内写，rd表示的是目标寄存器
    input wire [`OPLEN] op,
    // from ALU get the result
    input wire [`REGLINE] result,
    
    // to RS the updated reg
    output wire [`REGINDEX] updated_reg_index,
    // to ICache, RS, ROB and LSB
    input wire jump_prediction,
    output wire jump_wrong,
    output wire jump_pc
)
endmodule