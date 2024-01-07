# Memristor-Based SNN Chip

![NTHU LARC Logo](images/nthu_larc_logo.png?raw=true)

This repository contains the RTL verilog code for the digital part of a memristor-based SNN chip. The SNN chip consists of 5 layers of spiking convolutional module. The memristor-based compute-in-memory (CIM) macro are responsible for multiply-and-accumulate (MAC) computation of spikes and weights. The CIM macro is a full-custom design. It is represented by a behavior model during verilog simulation and will be loaded as an hard macro during synthesis, placement and routing.

## Usage

1. Run verilog simulation for layer module
```
$ cd sim/layer
$ make layer1
$ make layer2
$ make layer3
$ make layer4
$ make layer5
```
The input spikes, weights and expected output spikes (golden data) of each layer in the SNN can be found in the directory "data".  They are extracted from an pre-trained SNN model. The test bench will compare the output spikes obtained from the design under test with the golden data automatically. If the verification is successful, "Simulation Pass!" will be displayed on the screen. Otherwise, you will see "Simulation Fail!".

2. Run verilog simulation for network module
```
$ cd sim/network
$ make network
```

3. Clean working directory
In sim/layer or sim/network, execute the following command.
```
$ make clean
```

