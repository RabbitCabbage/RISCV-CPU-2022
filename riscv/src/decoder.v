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
    input wire[`ADDR] fetch_pc,

    //raw information decoded
    // to RS
    input wire stall_RS,
    output wire decode_success,// after decoding it requires rs to add the instr.
    output reg [`ROBINDEX] to_rs_rs1_rename,
    output reg [`ROBINDEX] to_rs_rs2_rename,
    output reg [`ROBINDEX] to_rs_rd_rename,
    output reg [`DATALEN] to_rs_imm,
    output reg [`DATALEN] to_rs_rs1_value,
    output reg [`DATALEN] to_rs_rs2_value,
    output reg [`OPCODE] to_rs_op,
    output wire [`ADDR] decode_pc,

    // to lsb
    output reg [`ROBINDEX] to_lsb_rs1_rename,
    output reg [`ROBINDEX] to_lsb_rs2_rename,
    output reg [`ROBINDEX] to_lsb_rd_rename,
    output reg [`DATALEN] to_lsb_rs1_value,
    output reg [`DATALEN] to_lsb_rs2_value,
    output reg [`IMMLEN] to_lsb_imm,
    output reg [`OPCODE] to_lsb_op,

    //from regfile
    //from regfile ask the information about registers
    input wire [`ROBINDEX] from_reg_rs1_rob_rename,
    input wire [`ROBINDEX] from_reg_rs2_rob_rename,
    input wire [`DATALEN] reg_rs1_value,
    input wire [`DATALEN] reg_rs2_value,
    input wire reg_rs1_busy,
    input wire reg_rs2_busy, 
    output wire [`REGINDEX] to_reg_rs1_index,
    output wire [`REGINDEX] to_reg_rs2_index,
    output wire [`ROBINDEX] to_reg_rd_rename,

    // from ROB, asking for the free index for the rd renaming
    // ask for the value of issued results
    input wire [`ROBINDEX] rob_free_tag,
    output reg [`ROBINDEX] to_rob_rd_rename,
    input wire [`DATALEN] rob_fetch_rs1_value,
    input wire rob_rs1_ready,
    input wire [`DATALEN] rob_fetch_rs2_value,
    input wire rob_rs2_ready,
    output reg [`ROBINDEX] rob_fetch_rs1_index,
    output reg [`ROBINDEX] rob_fetch_rs2_index,
    output reg [`OPLEN] to_rob_op,
    output reg [`REGINDEx] to_rob_destination_reg_index,
)

//记下decode的结果
reg [`OPLEN] op;
reg [`REGINDEX] rs1;
reg [`REGINDEX] rs2;
reg [`REGINDEX] rd;
reg [`DATALEN] imm;

wire [`DATALEN] rs1_value;
wire [`DATALEN] rs2_value;
wire [`ROBINDEX] rs1_rename;
wire [`ROBINDEX] rs2_rename;

assign to_reg_rs1_index = rs1;//从instr中读出来的rs1，送给regfile
assign to_reg_rs2_index = rs2;//从instr中读出rs2，送给regfile
assign rob_fetch_rs1_index = from_reg_rs1_rob_rename;//regfile送回来rename
assign rob_fetch_rs2_index = from_reg_rs2_rob_rename;//regfile送回来rename
assign to_reg_rd_rename = rob_free_tag;//rob空的tag赋给rd作为rename
assign decode_pc = fetch_pc;
assign rs1_value = (reg_rs1_busy==`FALSE)?reg_rs1_value:(rob_rs1_ready==`TRUE)?rob_fetch_rs1_value:`NULL32;
assign rs2_value = (reg_rs2_busy==`FALSE)?reg_rs2_value:(rob_rs2_ready==`TRUE)?rob_fetch_rs2_value:`NULL32;
assign rs1_rename = (reg_rs1_busy==`FALSE)?`ROBNOTRENAME:(rob_rs1_ready==`TRUE)?`ROBNOTRENAME:from_reg_rs1_rob_rename;
assign rs2_rename = (reg_rs2_busy==`FALSE)?`ROBNOTRENAME:(rob_rs2_ready==`TRUE)?`ROBNOTRENAME:from_reg_rs2_rob_rename;

always @(*) begin
    //rst has nothing on this module, because this module has nothing stored in itself.

    if(rdy==`TRUE && IF_success==`TRUE && stall_RS==`FALSE) begin
        decode_success <= `TRUE;
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
                //把得到的结果传给lsb
                to_rob_op <= op;
                to_lsb_op <= op;
                to_lsb_imm <= imm;
                to_lsb_rd_rename <= rob_free_tag;
                to_lsb_rs1_value <= rs1_value;
                to_lsb_rs1_rename <= rs1_rename;
                to_rob_destination_reg_index <= rd;
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
                //吧得到的结果传给rs
                to_rs_op <= op;
                to_rob_op <= op;
                to_rs_imm <= imm;
                to_rs_rs1_rename <= rs1_rename;
                to_rs_rs1_value <= rs1_value;
                to_rs_rd_rename <= rob_free_tag;
                to_rob_destination_reg_index <= rd;
            end
            7'0010111: begin
                op <= `AUIPC;
                rd <= instr[11:7];
                imm <= {instr[31:12],12'b0};
                to_rs_rd_rename <= rob_free_tag;
                to_rs_imm <= imm;
                to_rs_op <= op;
                to_rob_op <= op;
                to_rob_destination_reg_index <= rd;
            end
            7'0100011: begin
                case(instr[`FUNC3])
                    3'000: op <= `SB;
                    3'001: op <= `SH;
                    3'010: op <= `SW;
                endcase
                rs1 <= instr[19:15];
                rs2 <= instr[24:20];
                imm <= {{21{instr[31]}},instr[30:25],instr[11:7]};
                to_rob_op <= op;
                to_lsb_op <= op;
                to_lsb_imm <= imm;
                to_lsb_rs1_value <= rs1_value;
                to_lsb_rs1_rename <= rs1_rename;
                to_lsb_rs2_value <= rs2_value;
                to_lsb_rs2_rename <= rs2_rename;
            end
            7'0110011: begin
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
                to_rs_rs1_value <= rs1_value;
                to_rs_rs2_value <= rs2_value;
                to_rs_rs1_rename <= rs1_rename;
                to_rs_rs2_rename <= rs2_rename;
                to_rs_rename <= rob_free_tag;
                to_rs_op <= op;
                to_rob_op <= op;
                to_rob_destination_reg_index <= rd;
            end
            7'0110111: begin
                op <= `LUI;
                rd <= instr[11:7];
                imm <= {instr[31:12],12'b0};
                to_rs_imm <= imm;
                to_rob_op <= op;
                to_rs_op <= op;
                to_rs_rd_rename <= rob_free_tag;
                to_rob_destination_reg_index <= rd;
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
                to_rs_rs1_value <= rs1_value;
                to_rs_rs2_value <= rs2_value;
                to_rs_rs1_rename <= rs1_rename;
                to_rs_rs2_rename <= rs2_rename;
                to_rs_imm <= imm;
                to_rs_op <= op;
                to_rob_op <= op;
            end
            7'1100111: begin
                op <= `JALR;
                rs1 <= instr[19:15];
                rd <= instr[11:7];
                imm <= {{21{instr[31]}},instr[30:20]};
                to_rs_rs1_value <= rs1_value;
                to_rs_rs1_rename <= rs1_rename;
                to_rs_rename <= rob_free_tag;
                to_rs_imm <= imm;
                to_rs_op <= op;
                to_rob_op <= op;
                to_rob_destination_reg_index <= rd;
            end
            7'1101111: begin
                op <= `JAL;
                imm <= {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};
                rd <= instr[11:7];
                to_rs_rename <= rob_free_tag;
                to_rs_imm <= imm;
                to_rs_op <= op;
                to_rob_op <= op;
                to_rob_destination_reg_index <= rd;
            end
         endcase
    end else begin
        decode_success <= `FALSE;
    end
end
endmodule