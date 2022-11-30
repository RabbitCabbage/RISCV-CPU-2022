`include "define.v"
module RS(
    //control signals
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,
    
    //from decoder
    input wire decode_success,
    input wire [`INSTRLEN] decode_instr,
    input wire [`REGINDEX] decode_rs1,
    input wire [`REGINDEX] decode_rs2
    input wire [`IMMLEN] decode_imm,
    input wire [`REGINDEX] decode_rd,
    input wire [`OPLEN] decode_op,
    input wire [`ADDR] decpde_pc,

    // to ALU
    output wire alu_enable,
    output wire to_alu_renaming,
    output wire [`REGLINE] to_alu_rs1_value,
    output wire [`REGLINE] to_alu_rs2_value,
    output wire [`OPLEN] to_alu_op,
    output wire [`IMMLEN] to_alu_imm,
    output wire [`ADDR] to_alu_pc,

    output wire rs_full,//如果rs满了的话就要停下if
    
    // from ROB and LSB
    // record the index of this instr in ROB
    // ROB要把写好到reg中的东西返回到RS让它去除renaming
    input wire rob_is_update,
    input wire updated_reg_index,
    //to ROB module    
    output wire [`REGINDEX] rd,
    //to LSB module
    output wire [`ADD] ls_information,
    output wire [`INSTRLEN] instr
)
reg [`OPLEN] opcode[`RSSIZE];
reg [`DATALEN] rs1_value[`RSSIZE];
reg [`DATALEN] rs2_value[`RSSIZE];
reg [`ROBINDEX] rs1_rename[`RSSIZE];
reg [`ROBINDEX] rs2_rename[`RSSIZE];
reg [`ROBINDEX] rd_rename[`RSSIZE];
reg [`IMMLEN] imm[`RSSIZE];
reg rs1_rdy[`RSSIZE];
reg rs2_rdy[`RSSIZE];
reg ready[`RSSIZE];
reg busy[`RSSIZE];
reg [`ADDR] pc[`RSSIZE];
wire [`RSINDEX] free_index;//表示的是哪一个RS是空的可以用的
wire [`RSINDEX] ready_index; //表达hi说的是哪一个RS已经ready了可以进行计算了

assign stall_IF = (free_index == `RSNOTFOUND);//如果找不到空的RS，则说明RS满了，那么就应该停IF。
assign free_index = ~busy[0] ? 0:  
                        ~busy[1] ? 1 :
                            ~busy[2] ? 2 : 
                                ~busy[3] ? 3 :
                                    ~busy[4] ? 4 :
                                        ~busy[5] ? 5 : 
                                            ~busy[6] ? 6 :
                                                ~busy[7] ? 7 :
                                                    ~busy[8] ? 8 : 
                                                        ~busy[9] ? 9 :
                                                            ~busy[10] ? 10 :
                                                                ~busy[11] ? 11 :
                                                                    ~busy[12] ? 12 :
                                                                        ~busy[13] ? 13 :
                                                                            ~busy[14] ? 14 : 
                                                                                ~busy[15] ? 15 : `RSNOTFOUND;
assign issue_index = ~ready[0] ? 0:  
                        ~ready[1] ? 1 :
                            ~ready[2] ? 2 : 
                                ~ready[3] ? 3 :
                                    ~ready[4] ? 4 :
                                        ~ready[5] ? 5 : 
                                            ~ready[6] ? 6 :
                                                ~ready[7] ? 7 :
                                                    ~ready[8] ? 8 : 
                                                        ~ready[9] ? 9 :
                                                            ~ready[10] ? 10 :
                                                                ~ready[11] ? 11 :
                                                                    ~ready[12] ? 12 :
                                                                        ~ready[13] ? 13 :
                                                                            ~ready[14] ? 14 : 
                                                                                ~ready[15] ? 15 : `RSNOTFOUND;

always @(*) begin
    if(rst==`TRUE || clr==`TRUE) begin
        alu_enable <=  `FALSE;
        for(i=0;i<32;i=i+1) begin
            busy[i] <= `FALSE;
        end
    end else if (rdy) begin
        // 如果在RS中又ready的index；
        // 发布到alu中进行计算
        if(issue_index != `RSNOTFOUND) begin
            alu_enable <= `TRUE;
            to_alu_op <= opcode[issue_index];
            to_alu_rs1_value <= rs1_value[issue_index];
            to_alu_rs2_value <= rs2_value[issue_index];
            to_alu_imm <= imm[issue_index];
            to_alu_renaming <= rd_rename[issue_index];
            to_alu_pc <= pc[issue_index];
            busy[issue_index] <= `FALSE;
        end
        //如果decode这边成功解码，并且有空位置，添加一条指令
        if(decode_success && free_index!=`RSNOTFOUND) begin
            busy[free_index] <= `TRUE;
            tags[free_index] <= in_decode_rob_tag;
            opcode[free_index] <= decode_op;
            imm[free_index] <= decode_imml;
            pc[free_index] <= decode_pc;
            rs1_value[free_index] <= decode_rs1_value;
            rs2_value[free_index] <= decode_rs2_value;
            rs1_rename[free_index] <= decode_rs1_rename;
            rs2_rename[free_index] <= decode_rs2_rename;
        end     
    end
end
endmodule