`include "define.v"
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
    //不用rob enable，如果lsb需要读的话会在得到地址值之后及时去读，不会等rob
    //output reg rob_enable_lsb_read,
    input wire [`DATALEN] from_lsb_data,
    //commit to register file
    output reg [`REGINDEX] to_reg_rd,
    output reg [`DATALEN] to_reg_value,
    output reg [`ROBINDEX] to_reg_rename,
    output reg enable_reg,

    //interact with decoder
    //tell decoder the rob line free
    output wire [`ROBINDEX] rob_free_tag,
    input wire decoder_input_enable,
    input wire [`ROBINDEX] decoder_rd_rename,
    input wire [`INSTRLEN] decoder_instr,
    // decoder fetches value from rob
    input wire [`ROBINDEX] decoder_fetch_rs1_index,
    input wire [`ROBINDEX] decoder_fetch_rs2_index,
    output wire to_decoder_rs1_ready,
    output wire to_decoder_rs2_ready,
    output wire [`DATALEN] to_decoder_rs1_value,
    output wire [`DATALEN] to_decoder_rs2_value,
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

    output reg rob_broadcast,
    output reg [`ROBINDEX] rob_update_rename,
    output reg [`DATALEN] rob_cbd_value,

    output reg rob_full,
    output reg jump_wrong,
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
reg [`ROBINDEX] head;
reg [`ROBPOINTER] next;
reg [`INSTRLEN] instr;

//因为decoder送进来的是4：0的index，有一位用作了表示无重命名
//所以这里要取后面的3位作为indexing的下标
assign to_decoder_rs1_value = rd_value[decoder_fetch_rs1_index[3:0]];
assign to_decoder_rs2_value = rd_value[decoder_fetch_rs2_index[3:0]];
assign to_decoder_rs1_ready = ready[decoder_fetch_rs1_index[3:0]];
assign to_decoder_rs2_ready = ready[decoder_fetch_rs2_index[3:0]];
assign rob_free_tag = (rob_full==`FALSE)? {1'b0,next}: 16;

integer i;
integer debug_alu_update;
integer debug_rob_commit;
integer occupied;
localparam  file_name = "../test_execute.txt";
integer file_handle = 0;
initial begin
    rob_full <= `FALSE;
    head <= 0;//定一个很特殊的初始状态
    next <= 0;
    debug_alu_update <= 0;
    debug_rob_commit <= 0;
    occupied <= 0;
end

always @(posedge clk) begin
    if(rst == `TRUE ||(rdy == `TRUE && jump_wrong == `TRUE)) begin
        head <= 0;;
        next <= 0;
        to_reg_rd <= `NULL5;
        enable_reg <=  `FALSE;
        rob_enable_lsb_write <= `FALSE;
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
        rob_full = (next == head && occupied == 16);
       if(ready[head[3:0]]==`TRUE && rob_full==`FALSE && head != `ROBNOTRENAME) begin//同时要检查这个rob不空
           case(op[head[3:0]])
               `SB: begin
                    to_lsb_size <= `REQUIRE8;
                    to_lsb_addr <= destination_mem_addr[head[3:0]];
                    to_lsb_value <= rd_value[head[3:0]];
                    rob_enable_lsb_write <= `TRUE;
                    enable_reg <=  `FALSE;
               end
               `SH: begin
                    to_lsb_size <= `REQUIRE16;
                    to_lsb_addr <= destination_mem_addr[head[3:0]];
                    to_lsb_value <= rd_value[head[3:0]];
                    rob_enable_lsb_write <= `TRUE;
                    enable_reg <=  `FALSE;
               end
               `SW: begin
                    to_lsb_size <= `REQUIRE32;
                    to_lsb_addr <= destination_mem_addr[head[3:0]];
                    to_lsb_value <= rd_value[head[3:0]];
                    rob_enable_lsb_write <= `TRUE;
                    enable_reg <=  `FALSE;
               end
               `JALR: begin
                    to_reg_rd <= destination_reg_index[head[3:0]];
                    to_reg_value <= rd_value[head[3:0]];
                    to_reg_rename <= {1'b0,head[3:0]};
                    jumping_pc <= jump_pc[head[3:0]];
                    jump_wrong <= `TRUE;
                    enable_reg <=  `FALSE;
               end
               `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU:begin
                    to_predictor_pc <= pc[head[3:0]][`PREDICTORHASH];
                    to_predictor_jump <= rd_value[head[3:0]][0];//记下到底是jump还是not jump
                    to_predictor_enable <= `TRUE;
                    if(rd_value[head[3:0]][0] != predictor_jump[head[3:0]]) begin
                        if(rd_value[head[3:0]]=={31'b0,1'b1}) begin
                            jump_wrong <= `TRUE;
                            jumping_pc <= jump_pc[head[3:0]];
                        end else begin
                            jump_wrong <= `TRUE;
                            jumping_pc <= pc[head[3:0]]+4;
                        end
                    end
                    enable_reg <=  `FALSE;                    
               end
               default: begin
                    to_reg_rd <= destination_reg_index[head[3:0]];
                    to_reg_value <= rd_value[head[3:0]];
                    to_reg_rename <= {1'b0,head[3:0]};
                    jumping_pc <= jump_pc[head[3:0]];
                    jump_wrong <= `FALSE;
                    enable_reg <=  `TRUE;
               end
           endcase
           file_handle = $fopen(file_name,"w");
           if(!file_handle) begin
            $display("could not open file\r");
            $stop;
           end
        //    case(op[head[3:0]])
            // `LB: begin
                $fdisplay(file_handle,"%h /tlb %d %d",instr[head[3:0]],destination_reg_index[head[3:0]],rd_value[head[3:0]]);
                $fclose(file_handle);
                $display("hello?");
            // end
            // default begin
            // end
        //    endcase
           head <= (head + 1) % `ROBNOTRENAME;
           debug_rob_commit <= debug_rob_commit + 1;
           occupied <= occupied - 1;
       end else begin
        enable_reg <=  `FALSE;
        rob_enable_lsb_write <= `FALSE;
       end
       if(decoder_input_enable == `TRUE) begin
           pc[next] <= decoder_pc;
           destination_reg_index[next] <= decoder_destination_reg_index;
           op[next] <= decoder_op;
           instr[next] <= decoder_instr;
           ready[next] <= `FALSE;
           predictor_jump[next] <= predicted_jump;
           if(decoder_op == `SW || decoder_op == `SH || decoder_op == `SB) begin
               is_store[next] <= `TRUE;
           end else begin
               is_store[next] <= `FALSE;
           end
           next <= next + 1;
           occupied <= occupied + 1;
        end
        if(lsb_input_enable == `TRUE) begin
            pc[from_lsb_rename[3:0]] <= from_lsb_pc;
            destination_mem_addr[from_lsb_rename[3:0]] <= lsb_destination_mem_addr;
        end
       if(alu_broadcast == `TRUE) begin
           rd_value[alu_update_rename[3:0]] <= alu_cbd_value;
           ready[alu_update_rename[3:0]] <= `TRUE;
           jump_pc[alu_update_rename[3:0]] <= alu_jumping_pc;
           debug_alu_update <= debug_alu_update + 1;
       end 
       if(lsb_broadcast == `TRUE) begin
           rd_value[lsb_update_rename[3:0]] <= lsb_cbd_value;
           ready[lsb_update_rename[3:0]] <= `TRUE;
           if(is_store[lsb_update_rename[3:0]]==`TRUE) begin
               destination_mem_addr[lsb_update_rename[3:0]] <= lsb_addr;
           end
       end
    end
end
endmodule