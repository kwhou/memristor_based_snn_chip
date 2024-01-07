
module buffer1 (
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
input [63:0] D;
output [191:0] Q;
input [4:0] DEPTH; // depth-1
input PD;

wire CE;
wire CEB;
reg WEB;
reg [4:0] wptr;
reg [4:0] rptr;
wire [4:0] A;
wire [191:0] D2M;

reg CLK_EN;
wire CLK_GATE;

assign CEB = ~(IN_VALID_INTERNAL | ~WEB);
assign CE = ~CEB;

assign A = WEB? rptr : wptr;

assign D2M[31:0] = Q[47:16];
assign D2M[47:32] = D[15:0];
assign D2M[79:48] = Q[95:64];
assign D2M[95:80] = D[31:16];
assign D2M[127:96] = Q[143:112];
assign D2M[143:128] = D[47:32];
assign D2M[175:144] = Q[191:160];
assign D2M[191:176] = D[63:48];

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

MEM24X96 mem1 (
    .PD     (PD),
    .CLK    (CLK_GATE),
    .CEB    (CEB),
    .WEB    (WEB),
    .A      (A),
    .D      (D2M[95:0]),
    .Q      (Q[95:0])
);

MEM24X96 mem2 (
    .PD     (PD),
    .CLK    (CLK_GATE),
    .CEB    (CEB),
    .WEB    (WEB),
    .A      (A),
    .D      (D2M[191:96]),
    .Q      (Q[191:96])
);

endmodule
