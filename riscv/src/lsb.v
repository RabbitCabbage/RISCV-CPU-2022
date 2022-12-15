`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"
module LSB(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    input wire jump_wrong,
    //to mem_ctrl 
    output reg lsb_read_signal,
    output reg lsb_write_signal,
    output reg[`LSBINSTRLEN] requiring_length,
    output reg[`DATALEN] to_mem_data,
    output reg[`ADDR] to_mem_addr,
    output reg load_signed,
    input wire mem_load_success,
    input wire [`DATALEN] from_mem_data,

    //interact with decoder
    input wire decode_signal,
    input wire [`ROBINDEX] decoder_rs1_rename,
    input wire [`ROBINDEX] decoder_rs2_rename,
    input wire [`ROBINDEX] decoder_rd_rename,
    input wire [`DATALEN] decoder_rs1_value,
    input wire [`DATALEN] decoder_rs2_value,
    input wire [`IMMLEN] decoder_imm,
    input wire [`OPLEN] decoder_op,

    //from alu cbd
    input wire alu_broadcast,
    input wire [`DATALEN] alu_cbd_value,
    input wire [`ROBINDEX] alu_update_rename,
    //from rob cbd
    input wire rob_broadcast,
    input wire [`DATALEN] rob_cbd_value,
    input wire [`ROBINDEX] rob_update_rename,
    // 将自己load结果发到cbd
    output wire lsb_broadcast,
    output reg [`DATALEN] lsb_cbd_value,
    output reg [`ROBINDEX] lsb_update_rename,
    
    output wire lsb_full
);
reg                 busy[`LSBSIZE];
reg [`ADDR]         pc[`LSBSIZE];
reg [`ROBINDEX]     rob_index[`LSBSIZE];
reg [`ADDR]         destination_mem_addr[`LSBSIZE];
reg                 addr_ready[`LSBSIZE];
reg [`OPLEN]        op[`LSBSIZE];
reg [`IMMLEN]       imms[`LSBSIZE];
reg [`DATALEN]      rs1_value[`LSBSIZE];
reg [`DATALEN]      rs2_value[`LSBSIZE];
reg [`ROBINDEX]     rs1_rename[`LSBSIZE];
reg [`ROBINDEX]     rs2_rename[`LSBSIZE];
reg                 calculate_ready[`LSBSIZE];
reg                 issue_ready[`LSBSIZE];

//rob的数据结构应该是一个循环队列，记下头尾,记住顺序
reg [`LSBPOINTER]   head;
reg [`LSBPOINTER]   tail;
reg [`LSBPOINTER]   current;
reg [`LSBPOINTER]   next;
reg [`LSBINDEX]     tmp;
reg [`LSBINDEX]     to_calculate;
assign tmp = {1'b0,head} % 16;
assign current = tmp[3:0];
assign tmp = {1'b0,tail} % 16;
assign next = tmp[3:0];
assign to_calculate = (calculate_ready[0] ? 0 :(
                            calculate_ready[1] ? 1 : (
                                calculate_ready[2] ? 2 : (
                                    calculate_ready[3] ? 3: (
                                        calculate_ready[4] ? 4 : (
                                            calculate_ready[5] ? 5 : (
                                                calculate_ready[6] ? 6 : (
                                                    calculate_ready[7] ? 7 : (
                                                        calculate_ready[8] ? 8 : (
                                                            calculate_ready[9] ? 9 :(
                                                                calculate_ready[10] ? 10 :(
                                                                    calculate_ready[11] ? 11 :(
                                                                        calculate_ready[12] ? 12 :(
                                                                            calculate_ready[13] ? 13 :(
                                                                                calculate_ready[14] ? 14 :(
                                                                                    calculate_ready[15]? 15 : `LSBNOTRENAME
                                                                                    ))))))))))))))));
genvar i;
generate 
    for(i=0;i<`LSBSIZESCALAR;i=i+1) begin
        assign issue_ready[i] = (busy[i]==`TRUE && (addr_ready[i]==`TRUE && rs2_rename[i] == `ROBNOTRENAME));
        assign calculate_ready[i] = (busy[i]==`TRUE && (addr_ready[i]==`FALSE && rs1_rename[i] == `ROBNOTRENAME));
    end
endgenerate
integer j;
always @(posedge clk) begin
    if(rst == `TRUE || (rdy == `TRUE && jump_wrong == `TRUE)) begin
        head <= 1;
        tail <= 1;
        lsb_write_signal <= `FALSE;
        lsb_read_signal <= `FALSE;
        lsb_full <= `FALSE;
        for(j=0;j<`LSBSIZESCALAR;j=j+1)begin
            busy[j] <= `FALSE;
            calculate_ready[j] <= `FALSE;
            issue_ready[j] <= `FALSE;
            addr_ready [j] <= `FALSE;
            destination_mem_addr[j] <= `NULL32;
        end
    end else if(rdy == `TRUE && jump_wrong == `FALSE)begin
        if(issue_ready[current] == `TRUE) begin
            case(op[current])
                `SB,`SH,`SW: begin
                    lsb_write_signal <= `TRUE;
                    lsb_read_signal <= `FALSE;
                    to_mem_addr <= destination_mem_addr[current];
                    to_mem_data <= rs2_value[current];
                    busy[current] <= `FALSE;
                    addr_ready[current] <= `FALSE;
                    head <= current;
                    lsb_update_rename <= rob_index[current];
                end
                `LB,`LBU,`LH,`LHU,`LW: begin
                    busy[current] <= `FALSE;
                    addr_ready[current] <= `FALSE;
                    head <= current;
                    lsb_write_signal <= `FALSE;
                    lsb_read_signal <= `TRUE;
                    lsb_update_rename <= rob_index[current];
                    to_mem_addr <= destination_mem_addr[current];
                    load_signed <= (op[current]==`LHU || op[current]==`LBU)? `FALSE : `TRUE;
                    case(op[current])
                        `LB,`LBU: begin 
                            requiring_length <= `REQUIRE8; 
                        end
                        `LH,`LHU: begin 
                            requiring_length <= `REQUIRE16;
                        end
                        default: begin
                            requiring_length <= `REQUIRE32;
                        end
                    endcase
                end
                default: begin end
            endcase
        end
        if(mem_load_success) begin
            lsb_broadcast <= `TRUE;
            lsb_cbd_value <= from_mem_data;
            lsb_update_rename <= rob_index[current];
            busy[current] <= `FALSE;
            addr_ready[current] <= `FALSE;
            head <= current;
        end
        //calculate the required address
        if(to_calculate != `LSBNOTRENAME) begin
            destination_mem_addr[to_calculate[3:0]] <= rs1_value[to_calculate[3:0]] + imms[current];
            addr_ready[to_calculate[3:0]] <=  `TRUE;
        end
        // add an entry to lsb
        if(decode_signal==`TRUE && head != tail) begin
            busy[next] <= `TRUE;
            rob_index[next] <= decoder_rd_rename;
            rs1_rename[next] <= decoder_rs1_rename;
            rs2_rename[next] <= decoder_rs2_rename;
            rs1_value[next] <= decoder_rs1_value;
            rs2_value[next] <= decoder_rs2_value;
            imms[next] <= decoder_imm;
            tail <= next;
        end
        for(j=0;j<`LSBSIZESCALAR;j=j+1)begin
            if(alu_broadcast) begin
                if(alu_update_rename==rs1_rename[j]) begin
                    rs1_value[j] <= alu_cbd_value;
                    rs1_rename[j] <= `ROBNOTRENAME;
                end
                if(alu_update_rename==rs2_rename[j]) begin
                    rs2_value[j] <= alu_cbd_value;
                    rs2_rename[j] <= `ROBNOTRENAME;
                end
            end
            if(rob_broadcast) begin
                if(rob_update_rename==rs1_rename[j]) begin
                    rs1_value[j] <= alu_cbd_value;
                    rs1_rename[j] <= `ROBNOTRENAME;
                end
                if(rob_update_rename==rs2_rename[j]) begin
                    rs2_value[j] <= rob_cbd_value;
                    rs2_rename[j] <= `ROBNOTRENAME;
                end
            end
        end
    end
end
endmodule