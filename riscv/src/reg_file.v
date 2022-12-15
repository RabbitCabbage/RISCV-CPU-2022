`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"
module RegFile(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,

    //interact with decoder
    input wire [`REGINDEX] from_decoder_rs1_index,
    input wire [`REGINDEX] from_decoder_rs2_index,
    input wire [`REGINDEX] from_decoder_rd_index,
    input wire [`ROBINDEX] decoder_rd_rename,
    output wire rs1_renamed,
    output wire rs2_renamed,
    output reg [`DATALEN] to_decoder_rs1_value,
    output reg [`DATALEN] to_decoder_rs2_value,
    output reg [`ROBINDEX] to_decoder_rs1_rename,
    output reg [`ROBINDEX] to_decoder_rs2_rename,

    // from ROB
    input wire [`REGINDEX] rob_commit_index,
    input wire [`ROBINDEX] rob_commit_rename,
    input wire [`DATALEN] rob_commit_value,
    input wire jump_wrong
);
reg [`DATALEN] reg_value [`REGSIZE];
reg renamed[`REGSIZE];
reg [`ROBINDEX] reg_rename [`REGSIZE];//用RS的标号来rename用这条指令作为结果的寄存器
assign to_decoder_rs1_value = reg_value[from_decoder_rs1_index];
assign to_decoder_rs1_rename = reg_rename[from_decoder_rs1_index];
assign rs1_renamed = renamed[from_decoder_rs1_index];
assign to_decoder_rs2_value = reg_value[from_decoder_rs2_index];
assign to_decoder_rs2_rename = reg_rename[from_decoder_rs2_index];
assign rs2_renamed = renamed[from_decoder_rs2_index];
integer i;
always @(posedge clk)begin
    if(rst==`TRUE || jump_wrong==`TRUE) begin
        for(i=0;i<`REGSIZESCALAR;i=i+1)begin
            reg_value[i] <= `NULL32;
            renamed[i] <= `FALSE;
            reg_rename[i] <= 0;
        end
    end else begin
        if(rdy==`TRUE) begin
            for(i=0;i<`REGSIZESCALAR;i=i+1) begin
                if({27'b0, rob_commit_index} == i) begin
                    reg_value[i] <= rob_commit_value;
                    reg_rename[i] <= `ROBNOTRENAME;
                    renamed[i] <= `FALSE;  
                end
                if({27'b0,from_decoder_rd_index}==i) begin
                    reg_rename[i] <= decoder_rd_rename;
                    renamed <= `TRUE;
                end
            end
        end
    end
end
endmodule