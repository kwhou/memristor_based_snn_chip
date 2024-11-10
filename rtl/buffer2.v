
module buffer2 (
    CLK,
    RSTB,
    IN_VALID,
    D,
    Q,
    DEPTH, // depth-1
    PD
);

input CLK;
input RSTB;
input IN_VALID;
input [47:0] D;
output [47:0] Q;
input [8:0] DEPTH; // depth-1
input PD;

wire MEA;
wire MEB;
wire ME;
reg WEA;
reg [8:0] wptr;
reg [8:0] rptr;
wire [8:0] ADRA;
wire [8:0] ADRB;

wire CLK_GATE;

assign MEA = WEA;
assign MEB = IN_VALID;
assign ME = MEA | MEB;

assign ADRA = wptr;
assign ADRB = rptr;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        WEA <= 1'b0;
    else if (IN_VALID)
        WEA <= 1'b1;
    else
        WEA <= 1'b0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        rptr <= 0;
    else if (IN_VALID && rptr == DEPTH)
        rptr <= 0;
    else if (IN_VALID)
        rptr <= rptr + 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        wptr <= 0;
    else if (WEA && wptr == DEPTH)
        wptr <= 0;
    else if (WEA)
        wptr <= wptr + 1;

ICG icg (.CP(CLK), .E(ME), .Q(CLK_GATE));

MEM312X48 mem1 (
    .PD     (PD),
    .CLK    (CLK_GATE),
    .MEA    (MEA),
    .WEA    (WEA),
    .ADRA   (ADRA),
    .DA     (D), 
    .MEB    (MEB),
    .ADRB   (ADRB),
    .QB     (Q)
);

endmodule
