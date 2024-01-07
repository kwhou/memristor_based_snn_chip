
layer1:
	@ iverilog -s test -o my_design -c file_list.txt -DLAYER1
	@ vvp -n my_design -lxt2

layer2:
	@ iverilog -s test -o my_design -c file_list.txt -DLAYER2
	@ vvp -n my_design -lxt2

layer3:
	@ iverilog -s test -o my_design -c file_list.txt -DLAYER3
	@ vvp -n my_design -lxt2

layer4:
	@ iverilog -s test -o my_design -c file_list.txt -DLAYER4
	@ vvp -n my_design -lxt2

layer5:
	@ iverilog -s test -o my_design -c file_list.txt -DLAYER5
	@ vvp -n my_design -lxt2

all: layer1 layer2 layer3 layer4 layer5

clean:
	@ rm -rf my_design *.vcd

