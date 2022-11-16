`include "define.v"

module MemCtrl (
    // control signals
    input wire clk,
    input wire rdy,
    input wire rst,

    // from and to LSB
    // LSB write and read memory, separately using two signals
    input wire lsb_write_signal,
    input wire [`ADDR] lsb_write_addr,
    input wire [`BYTELEN] lsb_write_byte,
    input wire [`ADDR] lsb_read_addr,
    output wire [`BYTELEN] lsb_read_byte,
    output wire lsb_read_signal,

    //from ICache
    // ICache read from memory
    input wire [`ADDR] icache_addr,
    output wire [`INSTRLEN] icache_read_instr,
    output wire icache_read_signal,
    //read_signal shows that reading is still not completed. 


    // from and to RAM
    input wire io_buffer_full,
    output wire [`ADDR] mem_addr,
    output wire [`BYTELEN] mem_data_write,
    input wire [`BYTELEN] mem_data_read,
    output wire read_write
);
endmodule
