`include "define.v"
module IF(
    input wire clk,
    input wire rst,
    input wire rdy,
    // with regard to jumping
    // from ROB
    input wire jump_wrong,
    input wire[`ADDR] jump_pc,
    
    // fetch instr from ICache
    // give out an addr and get an instr
    output wire [`ADDR] pc_to_fetch,
    input wire [`INSTRLEN] instr_fetched,

    // send instr to decoder
    // send out instr and wether jumping
    // if lsb or rob is full, then fetching should be stalled
    input wire stall_IF
    output wire [`INSTRLEN] instr_to_decode,
    output wire is_jump_instr,
    output wire jump_prediction
)
endmodule