`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"

module MemCtrl (
    // control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    // When the ROB jump wrong, the reading or writing should be halted
    input wire clr,

    // from and to LSB
    // LSB write and read memory, separately using two signals
    input wire lsb_write_signal,
    input wire lsb_read_signal,
    input wire [`ADDR] lsb_addr,
    input wire [`LSBINSTRLEN] lsb_len,//表示的是这个ls指令涉及了多少位，32、16、8分别对应3、2、1
    input wire [`DATALEN] lsb_write_data,
    output reg [`DATALEN] lsb_read_data,
    output reg lsb_success,

    //from ICache
    // ICache read from memory
    //一次读一个byte，所以一个地址读四次
    input wire [`ADDR] icache_addr,
    input wire icache_read_signal,
    output wire [`INSTRLEN] icache_read_instr,
    output wire icache_success,

    // from and to RAM
    input wire io_buffer_full,
    output reg [`ADDR] mem_addr,
    output reg [`BYTELEN] mem_byte_write,
    input wire [`BYTELEN] mem_byte_read,
    output wire read_write
);

reg working;
reg for_lsb_ic;//0 for lsb, 1 for icache;
reg [`ADDR] start_addr;
reg [`LSBINSTRLEN]requiring_len;
reg [`DATALEN] ultimate_data;//storing the result while processing
reg [2:0] finished;//result processed,00,01,10,11

always @(posedge clk) begin
    if(rst == `TRUE) begin
        
    end else if (rdy == `TRUE) begin
        // There is an instruction on operation so it cannot begin a new instruction.
        if(working) begin
            // 如果是向IO进行读写就不应该再把地址加一加二操作了。
            if(start_addr[17:16]==2'b11) begin
                if(read_write == `READ) begin //I/O read
                //load word/half word/ byte
                    if(finished == requiring_len) begin
                        //requiring length has been read
                        if(for_lsb_ic == 0) begin 
                            lsb_success              <= `TRUE;
                            lsb_read_data            <= ultimate_data;
                            icache_success           <= `FALSE;
                        end else begin
                            icache_success           <= `TRUE;
                            lsb_success              <= `FALSE;
                            icache_read_instr        <= ultimate_data;
                        end
                        working                      <= `FALSE;
                        mem_addr                     <= `NULL32;
                        ultimate_data                <= `NULL32;
                        mem_byte_write               <= `NULL8;
                    end else begin
                        lsb_success                  <= `FALSE;
                        icache_success               <= `FALSE;
                        mem_byte_write               <= `NULL8;
                        case(finished)
                            3'b000: begin
                                ultimate_data[7:0]   <= mem_byte_read;
                            end
                            3'b001: begin
                                ultimate_data[15:8]  <= mem_byte_read;
                            end
                            3'b010: begin
                                ultimate_data[23:16] <= mem_byte_read;
                            end
                            3'b011: begin
                                mem_addr             <= `NULL32;
                                ultimate_data[31:24] <= mem_byte_read;
                            end
                            default: begin end
                        endcase
                        finished                     <= finished + 3'b001;
                    end
                end else begin //I/O write, that is lsb wirte into memory
                //Store word/half word/byte
                    if(finished == requiring_len - 3'b001) begin
                        icache_success               <= `FALSE;
                        lsb_success                  <= `TRUE;
                        working                      <= `FALSE;
                        mem_addr                     <= `NULL32;
                        mem_byte_write               <= `NULL8;
                        ultimate_data                <= `NULL32;
                    end else begin
                        case(finished)
                            3'b000: begin
                                mem_byte_write       <= lsb_write_data[15:8];
                            end
                            3'b001: begin
                                mem_byte_write       <= lsb_write_data[23:16];
                            end
                            3'b010: begin
                                mem_byte_write       <= lsb_write_data[31:24];
                            end
                            default: begin end
                        endcase
                        finished                     <= finished + 3'b001;
                    end
                end
            end
            else begin
                if(read_write == `READ) begin //read
                    if(finished == requiring_len) begin
                        //requiring length has been read
                        if(for_lsb_ic == 0) begin 
                            lsb_success              <= `TRUE;
                            lsb_read_data            <= ultimate_data;
                            icache_success           <= `FALSE;
                        end else begin
                            icache_success           <= `TRUE;
                            lsb_success              <= `FALSE;
                            icache_read_instr        <= ultimate_data;
                        end
                        working                      <= `FALSE;
                        mem_addr                     <= `NULL32;
                        ultimate_data                <= `NULL32;
                        mem_byte_write               <= `NULL8;
                    end else begin
                        lsb_success                  <= `FALSE;
                        icache_success               <= `FALSE;
                        mem_byte_write               <= `NULL8;
                        case(finished)
                            3'b000: begin
                                ultimate_data[7:0]   <= mem_byte_read;
                                mem_addr             <= start_addr + 1;
                            end
                            3'b001: begin
                                ultimate_data[15:8]  <= mem_byte_read;
                                mem_addr             <= start_addr + 2; 
                            end
                            3'b010: begin
                                ultimate_data[23:16] <= mem_byte_read;
                                mem_addr             <= start_addr + 3; 
                            end
                            3'b011: begin
                                ultimate_data[31:24] <= mem_byte_read;
                                mem_addr             <= `NULL32;
                            end
                            default: begin end
                        endcase
                        finished                     <= finished + 1;
                    end
                end else begin //write
                    if(finished == requiring_len - 3'b001) begin
                        icache_success               <= `FALSE;
                        lsb_success                  <= `TRUE;
                        working                      <= `FALSE;
                        mem_addr                     <= `NULL32;
                        mem_byte_write               <= `NULL8;
                    end else begin
                        case(finished)
                            3'b000: begin
                                mem_byte_write       <= lsb_write_data[15:8];
                                mem_addr             <= start_addr + 1;
                            end
                            3'b001: begin
                                mem_byte_write       <= lsb_write_data[23:16];
                                mem_addr             <= start_addr + 2;
                            end
                            3'b010: begin
                                mem_byte_write       <= lsb_write_data[31:24];
                                mem_addr             <= start_addr + 3;
                            end
                            default: begin end
                        endcase
                        finished                     <= finished + 1;
                    end
                end
            end
        end
        // Begin a new instruction.
        else begin
            if(lsb_read_signal == `TRUE || lsb_write_signal == `TRUE) begin
                if(lsb_read_signal == `TRUE) begin
                    ultimate_data                    <= `NULL32;
                    working                          <= `TRUE;
                    for_lsb_ic                       <= 1'b0;
                    start_addr                       <= lsb_addr;
                    mem_addr                         <= lsb_addr;
                    read_write                       <= `READ;
                    //先读进来一个byte
                    requiring_len                    <= lsb_len;
                    finished                         <= 3'b000;
                    icache_success                   <= `FALSE;
                    lsb_success                      <= `FALSE;
                end else begin
                    ultimate_data                    <= `NULL32;
                    working                          <= `TRUE;
                    for_lsb_ic                       <= 1'0;
                    start_addr                       <= lsb_addr;
                    read_write                       <= `WRITE;
                    requiring_len                    <= lsb_len;
                    finished                         <= 3'b000;
                    icache_success                   <= `FALSE;
                    lsb_success                      <= `FALSE;
                    mem_addr                         <= lsb_addr;
                    mem_byte_write                   <= lsb_write_data[7:0];
                    //先写入一个byte
                end
            end
            else if(icache_read_signal) begin
                ultimate_data                        <= `NULL32;
                working                              <= `TRUE;
                for_lsb_ic                           <= 1'1;//working for icache;
                start_addr                           <= icache_addr;
                read_write                           <= `READ;
                mem_addr                             <= icache_addr;//先读进来一个byte
                requiring_len                        <= `REQUIRE32;
                finished                             <= 3'b000;
                icache_success                       <= `FALSE;
                lsb_success                          <= `FALSE;
            end
            else begin
                icache_success                       <= `FALSE;
                lsb_success                          <= `FALSE;
                read_write                           <= `NULL1;
                mem_addr                             <= `NULL32;
                mem_byte_write                       <= `NULL8;
            end
        end
    end
end
endmodule
