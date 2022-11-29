`include "define.v"

// get instructions from if, 
//and then decode them and send them to rs
module Decoder(
    // control signals
    input wire clk,
    input wire rst,
    input wire rdy,
    // from and to IFetch
    input wire IF_success,
    input wire [`INSTRLEN] instr,
    
    // to RS 
    input wire stall_RS,
    output wire [`IMMLEN] imm,
    output wire [`REGINDEX] rs1,
    output wire [`REGINDEX] rs2,
    output wire [`REGINDEX] rd,
    output wire [`OPLEN] op
)
always @(*) begin
    //rst has nothing on this module, because this module has nothing stored in itself.
    if(rdy==`TRUE && IF_success==`TRUE && stall_RS==`FALSE) begin
        case(instr[`OPCODE])
            7'0000011: begin
                case(instr[`FUNC3])
                    3'000: op <= `LB;
                    3'001: op <= `LH;
                    3'010: op <= `LW;
                    3'100: op <= `LBU;
                    3'101: op <= `LHU;
                endcase
                rs1 <= instr[19:15];
                rd <= instr[11:7];
                imm <= {{21{instr[31]}},instr[30:20]};
            end
            7'0010011: begin
                case(instr[`FUNC3])
                    3'000: op <= `ADDI;
                    3'001: op <= `SLLI;
                    3'010: op <= `SLTI;
                    3'011: op <= `SLTIU;
                    3'100: op <= `XORI;
                    3'101: begin
                        case(instr[`FUNC7])
                            7'0000000: op <= `SRLI;
                            7'0100000: op <= `SRAI;
                        endcase
                    end
                    3'110: op <= `ORI;
                    3'111: op <= `ANDI;
                endcase
                rs1 <= instr[19:15];
                rd <= instr[11:7];
                imm <= {{21{instr[31]}},instr[30:20]};
            end
            7'0010111:
                op <= `AUIPC;
                rd <= instr[11:7];
                imm <= {instr[31:12],12'b0};
            7'0100011:
                case(instr[`FUNC3])
                    3'000: op <= `SB;
                    3'001: op <= `SH;
                    3'010: op <= `SW;
                endcase
                rs1 <= instr[19:15];
                rs2 <= instr[24:20];
                imm <= {{21{instr[31]}},instr[30:25],instr[11:7]};
            7'0110011:
                case(instr[`FUNC3]):
                    3'000:
                        case(instr[`FUNC7]):
                            7'0000000: op <= `ADD;
                            7'0100000: op <= `SUB;
                        endcase
                    3'001: op <= `SLL;
                    3'010: op <= `SLT;
                    3'011: op <= `SLTU;
                    3'100: op <= `XOR;
                    3'101: begin
                        case(instr[`FUNC7]):
                            7'0000000: op <= `SRL;
                            7'0100000: op <= `SRA;
                        endcase
                    end
                    3'110: op <= `OR;
                    3'111: op <= `AND;
                endcase
                rs1 <= instr[19:15];
                rs2 <= instr[24:20];
                rd <= instr[11:7];
            7'0110111: begin
                op <= `LUI;
                rd <= instr[11:7];
                imm <= {instr[31:12],12'b0};
            end
            7'1100011: begin
                case(instr[`FUNC3]):
                    3'000: op <= `BEQ;
                    3'001: op <= `BNE;
                    3'100: op <= `BLT;
                    3'101: op <= `BGE;
                    3'110: op <= `BLTU;
                    3'111: op <= `BGEU;
                endcase
                rs1 <= instr[19:15];
                rs2 <= instr[24:20];
                imm <= {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
            end
            7'1100111: begin
                op <= `JALR;
                rs1 <= instr[19:15];
                rd <= instr[11:7];
                imm <= {{21{instr[31]}},instr[30:20]};
            end
            7'1101111: begin
                op <= `JAL;
                imm <= {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};
                rd <= instr[11:7];
            end
         endcase
    end
end
endmodule