
module buffer1 (
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
input [63:0] D;
output [191:0] Q;
input [4:0] DEPTH; // depth-1
input PD;

wire MEA;
wire MEB;
wire ME;
reg WEA;
reg [4:0] wptr;
reg [4:0] rptr;
wire [4:0] ADRA;
wire [4:0] ADRB;
wire [191:0] D2M;

wire CLK_GATE;

assign MEA = WEA;
assign MEB = IN_VALID;
assign ME = MEA | MEB;

assign ADRA = wptr;
assign ADRB = rptr;

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

MEM24X96 mem1 (
    .PD     (PD),
    .CLK    (CLK_GATE),
    .MEA    (MEA),
    .WEA    (WEA),
    .ADRA   (ADRA),
    .DA     (D2M[95:0]),
    .MEB    (MEB),
    .ADRB   (ADRB),
    .QB     (Q[95:0])
);

MEM24X96 mem2 (
    .PD     (PD),
    .CLK    (CLK_GATE),
    .MEA    (MEA),
    .WEA    (WEA),
    .ADRA   (ADRA),
    .DA     (D2M[191:96]),
    .MEB    (MEB),
    .ADRB   (ADRB),
    .QB     (Q[191:96])
);

endmodule
