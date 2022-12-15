`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"
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
    output reg icache_enable,
    output reg [`ADDR] pc_to_fetch,
    input wire [`INSTRLEN] instr_fetched,
    input wire icache_success,

    // send instr to decoder
    // send out instr and wether jumping
    // if lsb or rob is full, then fetching should be stalled
    input wire stall_IF,
    output reg [`INSTRLEN] instr_to_decode,
    output reg IF_success,

    // from predictor
    input wire is_jump_instr,
    input wire jump_prediction
    //表示的是上一个指令是否是跳转指令，以及predict是否跳转
);
reg [`ADDR] pc;
always @(posedge clk) begin
    if (rst) begin
        icache_enable <= `FALSE;
        pc_to_fetch <= `NULL32;
        pc <= `NULL32;
    end
    if(rdy==`TRUE && stall_IF==`FALSE) begin
        if(jump_wrong==`TRUE) begin
            pc_to_fetch <= jump_pc;
        end else begin
            if(is_jump_instr==`TRUE) begin
                if(jump_prediction==`TRUE)begin
                    pc_to_fetch <= jump_pc;
                end else begin
                    pc_to_fetch <= pc + 4;
                end
            end
        end
        icache_enable <= `TRUE;
        if(icache_success ==`TRUE) begin
            instr_to_decode <= instr_fetched;
            IF_success <= `TRUE;
        end
    end
end
endmodule