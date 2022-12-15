`include "D:/Desktop/RISCV-CPU-2022/riscv/src/define.v"

module ALU(
    //control signals
    input wire clk,
    input wire rdy,
    input wire rst,
    //from RS
    input wire alu_enable,
    input wire [`ROBINDEX] in_rd_rename,
    input wire [`ADDR] instr_pc,
    input wire [`IMMLEN] imm,
    input wire [`DATALEN] rs1_value,
    input wire [`DATALEN] rs2_value,
    input wire [`OPLEN] op,
    
    // to RS and ROB
    output reg [`DATALEN] result,
    output wire alu_broadcast,
    output reg [`ROBINDEX] out_rd_rename,
    output reg [`ADDR] jumping_pc
);
always @(posedge clk) begin
    if(rdy && alu_enable) begin
        out_rd_rename         <= in_rd_rename;
        alu_broadcast         <= `TRUE;
        case(op)
            `ADD: result      <= rs1_value+rs2_value;
            `ADDI: result     <= rs1_value+imm;
            `SUB: result      <= rs1_value-rs2_value;
            `LUI: result      <= imm;
            `AUIPC: result    <= instr_pc+imm;
            `XOR: result      <= rs1_value^rs2_value;
            `XORI: result     <= rs1_value^imm;
            `OR: result       <= rs1_value|rs2_value;
            `ORI: result      <= rs1_value|imm;
            `AND: result      <= rs1_value&rs2_value;
            `ANDI: result     <= rs1_value&imm;
            `SLL: result      <= rs1_value<<rs2_value;
            `SLLI: result     <= rs1_value<<imm;
            `SRL: result      <= rs1_value>>rs2_value;
            `SRLI: result     <= rs1_value>>imm;
            `SRA: result      <= rs1_value>>>rs2_value;
            `SRAI: result     <= rs1_value>>>imm;
            `SLT: result      <= ($signed(rs1_value)<$signed(rs2_value))?1:0;
            `SLTI: result     <= ($signed(rs1_value)<$signed(imm))?1:0;
            `SLTU: result     <= (rs1_value<rs2_value)?1:0;
            `SLTIU: result    <= (rs1_value<imm)?1:0;
            `BEQ: begin
                result        <= (rs1_value==rs2_value)?1:0;
                jumping_pc    <= instr_pc+imm;
                alu_broadcast <= `FALSE;//因为没有寄存器的数值被更新
            end
            `BNE: begin
                result        <= (rs1_value!=rs2_value)?1:0;
                jumping_pc    <= instr_pc+imm;
                alu_broadcast <= `FALSE;//因为没有寄存器的数值被更新
            end
            `BLT: begin
                result        <= ($signed(rs1_value)<$signed(rs2_value))?1:0;
                jumping_pc    <= instr_pc+imm;
                alu_broadcast <= `FALSE;//因为没有寄存器的数值被更新
            end
            `BGE: begin
                result        <= ($signed(rs1_value)>=$signed(rs2_value))?1:0;
                jumping_pc    <= instr_pc+imm;
                alu_broadcast <= `FALSE;//因为没有寄存器的数值被更新
            end
            `BLTU: begin
                result        <= (rs1_value<rs2_value)?1:0;
                jumping_pc    <= instr_pc+imm;
                alu_broadcast <= `FALSE;//因为没有寄存器的数值被更新
            end
            `BGEU: begin
                result        <= (rs1_value>=rs2_value)?1:0;
                jumping_pc    <= instr_pc+imm;
                alu_broadcast <= `FALSE;//因为没有寄存器的数值被更新
            end
            `JAL:  begin
                result        <= instr_pc+4;
                // jumping_pc <= instr_pc+imm;反正已经跳了
            end
            `JALR: begin
                result        <= instr_pc+4;
                jumping_pc    <= rs1_value+imm;
            end
            default:begin end
        endcase
    end
end
endmodule