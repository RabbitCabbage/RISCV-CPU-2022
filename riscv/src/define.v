`define ICSIZE 512 //ICache的大小
`define INSTRLEN 5:0 //Instruction的长度
`define ADDR 31:0//地址的长度是32位
`define BYTELEN 7:0
`define READ 1'b0
`define WRITE 1'b1
`define REGSIZE 31:0//寄存器个数有32个
`define REGLINE 31:0//每一个寄存器也有32位
`define REGINDEX 5:0//总共有32个寄存器，因此寄存器下标0~31，用6位即可
`define IMMLEN 31:0//立即数的长度
`define RSSIZE 31:0//RS的大小，RS的标号用来rename用这条指令作为结果的寄存器
`define OPLEN 31:0//判断一个计算指令类型的长度