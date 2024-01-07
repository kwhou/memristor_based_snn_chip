
module buffer2 (
    CLK,
    RSTB,
    IN_VALID_INTERNAL,
    D,
    Q,
    DEPTH, // depth-1
    PD
);

input CLK;
input RSTB;
input IN_VALID_INTERNAL;
input [47:0] D;
output [47:0] Q;
input [8:0] DEPTH; // depth-1
input PD;

wire CE;
wire CEB;
reg WEB;
reg [8:0] wptr;
reg [8:0] rptr;
wire [8:0] A;

reg CLK_EN;
wire CLK_GATE;

assign CEB = ~(IN_VALID_INTERNAL | ~WEB);
assign CE = ~CEB;

assign A = WEB? rptr : wptr;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        WEB <= 1'b1;
    else if (IN_VALID_INTERNAL)
        WEB <= 1'b0;
    else
        WEB <= 1'b1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        rptr <= 0;
    else if (IN_VALID_INTERNAL && rptr == DEPTH)
        rptr <= 0;
    else if (IN_VALID_INTERNAL)
        rptr <= rptr + 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        wptr <= 0;
    else if (!WEB && wptr == DEPTH)
        wptr <= 0;
    else if (!WEB)
        wptr <= wptr + 1;

ICG icg (.CP(CLK), .E(CE), .Q(CLK_GATE));

MEM312X48 mem1 (
    .PD(PD),
    .CLK(CLK_GATE),
    .CEB(CEB),
    .WEB(WEB),
    .A(A),
    .D(D), 
    .Q(Q)
);

endmodule
