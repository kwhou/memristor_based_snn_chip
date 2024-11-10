
module layer_ctrl (
    CLK,
    RSTB,
    TM,
    CFG_WE,
    CFG_D,
    CFG_Q,
    IN_VALID,
    IN_SPIKE,
    OUT_VALID,
    OUT_SPIKE,
    NCFG,
    PD_CIM,
    SWP,
    EN,
    FT,
    SPIKE_REMAP,
    REQ,
    NEURON_OUT
);

parameter HW_WIDTH = 5;
parameter T_WIDTH = 5;
parameter D1_WIDTH = 5;
parameter D2_WIDTH = 9;
parameter NCFG_WIDTH = 6 * 16;
parameter TPD_WIDTH = 4;
parameter IO_WIDTH = 16;

input CLK;
input RSTB;
input [1:0] TM;
input CFG_WE;
input CFG_D;
output CFG_Q;
input IN_VALID;
input [IO_WIDTH-1:0] IN_SPIKE;
output reg OUT_VALID;
output reg [IO_WIDTH-1:0] OUT_SPIKE;
output [NCFG_WIDTH-1:0] NCFG;
output PD_CIM;
output SWP;
output EN;
output FT;
output [255:0] SPIKE_REMAP;
input REQ;
input [15:0] NEURON_OUT;

wire PD_MEM;
wire PD;
wire BP;

wire [HW_WIDTH-1:0] HW;     // H-1 and W-1
wire [T_WIDTH-1:0] T;       // T-1
wire [D1_WIDTH-1:0] D1;     // depth of buffer1 - 1
wire [D2_WIDTH-1:0] D2;     // depth of buffer2 - 1
wire [NCFG_WIDTH-1:0] NCFG; // neuron configuration of 16 neurons {enb, vth}*16
wire [TPD_WIDTH-1:0] TPD;   // wait time before power down
wire PD_EN_MEM;             // power down enable for memory
wire PD_EN_CIM;             // power down enable for cim macro

wire [63:0] D2BUF1;
wire [191:0] QFBUF1;
wire [47:0] D2BUF2;
wire [47:0] QFBUF2;

reg [255:0] SPIKE_REMAP;
wire [255:0] SPIKE_REMAP_TEMP;

wire in_valid;
reg in_valid_d1;
reg [IO_WIDTH-1:0] in_spike;

assign PD_MEM = PD_EN_MEM & PD & (TM == 2'b00);
assign PD_CIM = PD_EN_CIM & PD & (TM == 2'b00);

assign in_valid = ~BP & IN_VALID;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        in_valid_d1 <= 1'b0;
    else
        in_valid_d1 <= in_valid;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        in_spike <= 0;
    else if (in_valid)
        in_spike <= IN_SPIKE;

config_reg #(HW_WIDTH, T_WIDTH, D1_WIDTH, D2_WIDTH, NCFG_WIDTH, TPD_WIDTH) config_reg (
    .CLK        (CLK),
    .RSTB       (RSTB),
    .CFG_WE     (CFG_WE),
    .CFG_D      (CFG_D),
    .CFG_Q      (CFG_Q),
    .HW         (HW),
    .T          (T),
    .D1         (D1),
    .D2         (D2),
    .NCFG       (NCFG),
    .TPD        (TPD),
    .PD_EN_MEM  (PD_EN_MEM),
    .PD_EN_CIM  (PD_EN_CIM),
    .BP         (BP),
    .SWP        (SWP)
);

dataflow #(HW_WIDTH, T_WIDTH, TPD_WIDTH, IO_WIDTH) dataflow (
    .CLK        (CLK),
    .RSTB       (RSTB),
    .IN_VALID   (in_valid),
    .EN         (EN),
    .FT         (FT),
    .HW         (HW),
    .T          (T),
    .TPD        (TPD),
    .PD         (PD),
    .BP         (BP)
);

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        OUT_VALID <= 1'b0;
    else if (BP)
        OUT_VALID <= IN_VALID;
    else if (REQ)
        OUT_VALID <= 1'b1;
    else
        OUT_VALID <= 1'b0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        OUT_SPIKE <= 0;
    else if (BP)
        OUT_SPIKE <= IN_SPIKE;
    else if (REQ)
        OUT_SPIKE <= NEURON_OUT;

buffer1 buffer1 (
    .CLK        (CLK),
    .RSTB       (RSTB),
    .IN_VALID   (in_valid),
    .D          (D2BUF1),
    .Q          (QFBUF1),
    .DEPTH      (D1),
    .PD         (PD_MEM)
);

buffer2 buffer2 (
    .CLK        (CLK),
    .RSTB       (RSTB),
    .IN_VALID   (in_valid),
    .D          (D2BUF2),
    .Q          (QFBUF2),
    .DEPTH      (D2),
    .PD         (PD_MEM)
);

assign D2BUF2[15:0] = SPIKE_REMAP_TEMP[79:64];
assign D2BUF2[31:16] = SPIKE_REMAP_TEMP[143:128];
assign D2BUF2[47:32] = SPIKE_REMAP_TEMP[207:192];

assign D2BUF1[47:0] = QFBUF2;
assign D2BUF1[63:48] = in_spike;

assign SPIKE_REMAP_TEMP[47:0] = QFBUF1[47:0];
assign SPIKE_REMAP_TEMP[63:48] = QFBUF2[15:0];
assign SPIKE_REMAP_TEMP[111:64] = QFBUF1[95:48];
assign SPIKE_REMAP_TEMP[127:112] = QFBUF2[31:16];
assign SPIKE_REMAP_TEMP[175:128] = QFBUF1[143:96];
assign SPIKE_REMAP_TEMP[191:176] = QFBUF2[47:32];
assign SPIKE_REMAP_TEMP[239:192] = QFBUF1[191:144];
assign SPIKE_REMAP_TEMP[255:240] = in_spike;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        SPIKE_REMAP <= 256'b0;
    else if (in_valid_d1)
        SPIKE_REMAP <= SPIKE_REMAP_TEMP;

endmodule
