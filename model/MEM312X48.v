
module MEM312X48 (
    PD,
    CLK,
    CEB,
    WEB,
    A,
    D, 
    Q
);

/* This is only a model for memory.
   Please replace this model with the one generated by
   the memory compiler you use. */

input PD;        // power down enable
input CLK;       // clock
input CEB;       // active low enable
input WEB;       // active low write enable
input [8:0] A;   // address
input [47:0] D;  // data in
output [47:0] Q; // data out

reg [47:0] Q;
reg [47:0] MEMORY [0:311];

always @(posedge CLK)
    if (!PD && !CEB)
         Q <= MEMORY[A];

always @(posedge CLK)
    if (!PD && !CEB && !WEB)
        MEMORY[A] <= D;

endmodule

