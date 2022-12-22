cd ..
cd src
iverilog common/*/*.v ram.v hci.v cpu.v riscv_top.v ../sim/testbench.v -o ../test/a.out
cd ../test
vvp a.out
