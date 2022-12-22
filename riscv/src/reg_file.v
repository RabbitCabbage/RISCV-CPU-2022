`include "define.v"
module RegFile(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,

    //interact with decoder
    input wire [`REGINDEX] from_decoder_rs1_index,
    input wire [`REGINDEX] from_decoder_rs2_index,
    input wire [`REGINDEX] from_decoder_rd_index,
    input wire decoder_need_rs1,
    input wire decoder_need_rs2,
    input wire decoder_have_rd_waiting,//有一些指令本身不需要rd，那么这时候的reg也不应该将记下发过来的rename
    //这个rename是这条指令在rob中的编号，无论有没有rd在等结果都会发过来，所以需要记下来
    input wire [`ROBINDEX] decoder_rd_rename,
    output wire rs1_renamed,
    output wire rs2_renamed,
    output wire [`DATALEN] to_decoder_rs1_value,
    output wire [`DATALEN] to_decoder_rs2_value,
    output wire [`ROBINDEX] to_decoder_rs1_rename,
    output wire [`ROBINDEX] to_decoder_rs2_rename,

    // from ROB
    input wire rob_enable,
    input wire [`REGINDEX] rob_commit_index,
    input wire [`ROBINDEX] rob_commit_rename,
    input wire [`DATALEN] rob_commit_value
);
reg [`DATALEN] reg_value [`REGSIZE];
reg renamed[`REGSIZE];
reg [`ROBINDEX] reg_rename [`REGSIZE];//用RS的标号来rename用这条指令作为结果的寄存器
assign to_decoder_rs1_value = reg_value[from_decoder_rs1_index];
//如果本身这条指令不用rs1的值，那就直接说没有rename
assign to_decoder_rs1_rename = (decoder_need_rs1? reg_rename[from_decoder_rs1_index] : `ROBNOTRENAME);
assign rs1_renamed = (decoder_need_rs1? renamed[from_decoder_rs1_index] : `FALSE);
assign to_decoder_rs2_value = reg_value[from_decoder_rs2_index];
assign to_decoder_rs2_rename = (decoder_need_rs2 ? reg_rename[from_decoder_rs2_index] : `ROBNOTRENAME);
assign rs2_renamed = (decoder_need_rs2 ? renamed[from_decoder_rs2_index] : `FALSE);
integer i;
always @(posedge clk)begin
    if(rst==`TRUE) begin
        for(i=0;i<`REGSIZESCALAR;i=i+1)begin
            reg_value[i] <= `NULL32;
            renamed[i] <= `FALSE;
            reg_rename[i] <= 0;
        end
    end else begin
        if(rdy==`TRUE) begin
            if(rob_enable == `TRUE) begin
                reg_value[{27'b0, rob_commit_index}] <= rob_commit_value;
                reg_rename[{27'b0, rob_commit_index}] <= `ROBNOTRENAME;
                renamed[{27'b0, rob_commit_index}] <= `FALSE;
            end
            for(i=0;i<`REGSIZESCALAR;i=i+1) begin
                //首先要检查这个指令是不是要写reg，否则它的reg rename不能随便填
                if(decoder_have_rd_waiting==`TRUE && {27'b0,from_decoder_rd_index}==i) begin
                    reg_rename[i] <= decoder_rd_rename;
                    renamed[i] <= `TRUE;
                end
            end
        end
    end
end
endmodule