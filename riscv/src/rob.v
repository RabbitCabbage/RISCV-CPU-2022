`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"
module ROB(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    //commit to lsb, let lsb commit and perform the instr
    output reg rob_enable_lsb_write,
    output reg [`DATALEN] to_lsb_value,
    output reg [`LSBINSTRLEN] to_lsb_size,
    output reg [`ADDR] to_lsb_addr,
    output wire rob_enable_lsb_read,
    input wire [`DATALEN] from_lsb_data,
    //commit to register file
    output reg [`REGINDEX] to_reg_rd,
    output reg [`DATALEN] to_reg_value,
    output reg [`ROBINDEX] to_reg_rename,

    //interact with decoder
    //tell decoder the rob line free
    output reg [`ROBINDEX] rob_free_tag,
    input wire decoder_input_enable,
    input wire [`ROBINDEX] decoder_rd_rename,
    // decoder fetches value from rob
    input wire [`ROBINDEX] decoder_fetch_rs1_index,
    input wire [`ROBINDEX] decoder_fetch_rs2_index,
    output wire to_decoder_rs1_ready,
    output wire to_decoder_rs2_ready,
    output reg [`DATALEN] to_decoder_rs1_value,
    output reg [`DATALEN] to_decoder_rs2_value,
    input wire [`OPLEN] decoder_op,
    input wire [`ADDR] decoder_pc,
    input wire predicted_jump,
    input wire [`REGINDEX] decoder_destination_reg_index,//from decoder


    input wire [`ADDR] lsb_destination_mem_addr,//from lsb 如果lsb算出来了一个destination就会送过来
    input wire lsb_input_enable,
    input wire [`ROBINDEX] from_lsb_rename,
    input wire [`ADDR] from_lsb_pc,

    input wire alu_broadcast,
    input wire [`DATALEN] alu_cbd_value,
    input wire [`DATALEN] alu_jumping_pc,
    input wire [`ROBINDEX] alu_update_rename,

    input wire lsb_broadcast,
    input wire [`DATALEN] lsb_cbd_value,
    input wire [`DATALEN] lsb_addr,
    input wire [`ROBINDEX] lsb_update_rename,

    output wire rob_broadcast,
    output reg [`ROBINDEX] rob_update_rename,
    output reg [`DATALEN] rob_cbd_value,

    output wire rob_full,
    output wire jump_wrong,
    output reg [`ADDR] jumping_pc,

    output reg to_predictor_enable,
    output reg to_predictor_jump,
    output reg [`PREDICTORINDEX] to_predictor_pc
);
reg [`ADDR] pc[`ROBSIZE];
reg [`DATALEN] rd_value[`ROBSIZE];
reg [`ADDR] destination_mem_addr[`ROBSIZE];
reg [`REGINDEX] destination_reg_index[`ROBSIZE];
reg ready[`ROBSIZE];
reg [`OPLEN] op[`ROBSIZE];
reg [`ADDR] jump_pc[`ROBSIZE];
reg predictor_jump[`ROBSIZE];
reg is_store[`ROBSIZE];

//rob的数据结构应该是一个循环队列，记下头尾,记住顺序
reg [`ROBPOINTER] head;
reg [`ROBPOINTER] tail;
wire [`ROBPOINTER] next;
wire [`ROBPOINTER] current;
wire [`ROBINDEX] tmp;

//因为decoder送进来的是4：0的index，有一位用作了表示无重命名
//所以这里要取后面的3位作为indexing的下标
assign to_decoder_rs1_value = rd_value[decoder_fetch_rs1_index[3:0]];
assign to_decoder_rs2_value = rd_value[decoder_fetch_rs2_index[3:0]];
assign to_decoder_rs1_ready = ready[decoder_fetch_rs1_index[3:0]];
assign to_decoder_rs2_ready = ready[decoder_fetch_rs2_index[3:0]];
assign tmp = {1'b0,tail} % `ROBSIZESCALAR;
assign next = tmp[3:0];
assign tmp = {1'b0,head} % `ROBSIZESCALAR;
assign current = tmp[3:0];
assign rob_free_tag = (next != head)? {1'b0,next}: 16;
assign rob_full = (next == head);

integer i;
always @(posedge clk) begin
    if(rst == `TRUE ||(rdy == `TRUE && jump_wrong == `TRUE)) begin
        head <= 1;
        tail <= 1;
        to_reg_rd <= `NULL5;
        rob_enable_lsb_write <= `FALSE;
        rob_enable_lsb_read <= `FALSE;
        jump_wrong <= `FALSE;
        rob_broadcast <= `FALSE;
        rob_update_rename <= `NULL5;
        rob_cbd_value <= `NULL32;
        jump_wrong <= `FALSE;
        jumping_pc <= `NULL32;
        for(i=0;i<`ROBSIZESCALAR;i=i+1) begin
            rd_value[i] <= `NULL32;
            ready[i] <= `FALSE;
            is_store[i] <= `FALSE;
            predictor_jump[i] <= `FALSE;
        end
    end else if(rdy == `TRUE && jump_wrong == `FALSE) begin
        //commit the first instr;
       if(ready[current]==`TRUE && head != tail) begin
           case(op[current])
               `SB: begin
                    to_lsb_size <= `REQUIRE8;
                    to_lsb_addr <= destination_mem_addr[current];
                    to_lsb_value <= rd_value[current];
                    rob_enable_lsb_write <= `TRUE;
               end
               `SH: begin
                    to_lsb_size <= `REQUIRE16;
                    to_lsb_addr <= destination_mem_addr[current];
                    to_lsb_value <= rd_value[current];
                    rob_enable_lsb_write <= `TRUE;
               end
               `SW: begin
                    to_lsb_size <= `REQUIRE32;
                    to_lsb_addr <= destination_mem_addr[current];
                    to_lsb_value <= rd_value[current];
                    rob_enable_lsb_write <= `TRUE;
               end
               `JALR: begin
                    to_reg_rd <= destination_reg_index[current];
                    to_reg_value <= rd_value[current];
                    to_reg_rename <= {1'b0,current[3:0]};
                    jumping_pc <= jump_pc[current];
                    jump_wrong <= `TRUE;
               end
               `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU:begin
                    to_predictor_pc <= pc[current][`PREDICTORHASH];
                    to_predictor_jump <= rd_value[current][0];//记下到底是jump还是not jump
                    to_predictor_enable <= `TRUE;
                    if(rd_value[current][0] != predictor_jump[current]) begin
                        if(rd_value[current]=={31'b0,1'b1}) begin
                            jump_wrong <= `TRUE;
                            jumping_pc <= jump_pc[current];
                        end else begin
                            jump_wrong <= `TRUE;
                            jumping_pc <= pc[current]+4;
                        end
                    end                    
               end
               default: begin
                    to_reg_rd <= destination_reg_index[current];
                    to_reg_value <= rd_value[current];
                    to_reg_rename <= {1'b0,current[3:0]};
                    jumping_pc <= jump_pc[current];
                    jump_wrong <= `FALSE;
               end
           endcase
       end
       if(decoder_input_enable == `TRUE) begin
           pc[next] <= decoder_pc;
           destination_reg_index[next] <= decoder_destination_reg_index;
           op[next] <= decoder_op;
           ready[next] <= `FALSE;
           predictor_jump[next] <= predicted_jump;
           tail <= next;
           if(decoder_op == `SW || decoder_op == `SH || decoder_op == `SB) begin
               is_store[next] <= `TRUE;
           end else begin
               is_store[next] <= `FALSE;
           end
        end
        if(lsb_input_enable == `TRUE) begin
            pc[from_lsb_rename[3:0]] <= from_lsb_pc;
            destination_mem_addr[from_lsb_rename[3:0]] <= lsb_destination_mem_addr;
        end
       if(alu_broadcast == `TRUE) begin
           rd_value[alu_update_rename[3:0]] <= alu_cbd_value;
           ready[alu_update_rename[3:0]] <= `TRUE;
           jump_pc[alu_update_rename[3:0]] <= alu_jumping_pc;
       end 
       if(lsb_broadcast) begin
           rd_value[lsb_update_rename[3:0]] <= lsb_cbd_value;
           ready[lsb_update_rename[3:0]] <= `TRUE;
           if(is_store[lsb_update_rename[3:0]]==`TRUE) begin
               destination_mem_addr[lsb_update_rename[3:0]] <= lsb_addr;
           end
       end
    end
end
endmodule