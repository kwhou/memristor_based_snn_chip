
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
parameter IO_WIDTH = 8;
parameter CNT_WIDTH = 1;

input CLK;
input RSTB;
input [1:0] TM;
input CFG_WE;
input CFG_D;
output CFG_Q;
input IN_VALID;
input [IO_WIDTH-1:0] IN_SPIKE;
output OUT_VALID;
output [IO_WIDTH-1:0] OUT_SPIKE;
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

wire IN_VALID_INTERNAL;
wire [15:0] IN_SPIKE_INTERNAL;

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

reg IN_VALID_INTERNAL_D1;
reg [255:0] SPIKE_REMAP;
wire [255:0] SPIKE_REMAP_TEMP;

assign PD_MEM = PD_EN_MEM & PD & (TM == 2'b00);
assign PD_CIM = PD_EN_CIM & PD & (TM == 2'b00);

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

dataflow #(HW_WIDTH, T_WIDTH, TPD_WIDTH, IO_WIDTH, CNT_WIDTH) dataflow (
    .CLK                (CLK),
    .RSTB               (RSTB),
    .IN_VALID           (IN_VALID),
    .IN_VALID_INTERNAL  (IN_VALID_INTERNAL),
    .EN                 (EN),
    .FT                 (FT),
    .HW                 (HW),
    .T                  (T),
    .TPD                (TPD),
    .PD                 (PD),
    .BP                 (BP)
);

shift_reg_in #(IO_WIDTH, CNT_WIDTH) shift_reg_in (
    .CLK                (CLK),
    .RSTB               (RSTB),
    .IN_VALID           (IN_VALID),
    .IN_SPIKE           (IN_SPIKE),
    .IN_VALID_INTERNAL  (IN_VALID_INTERNAL),
    .IN_SPIKE_INTERNAL  (IN_SPIKE_INTERNAL),
    .BP                 (BP)
);

shift_reg_out #(IO_WIDTH, CNT_WIDTH) shift_reg_out (
    .CLK                (CLK),
    .RSTB               (RSTB),
    .OUT_VALID_INTERNAL (REQ),
    .OUT_SPIKE_INTERNAL (NEURON_OUT),
    .OUT_VALID          (OUT_VALID),
    .OUT_SPIKE          (OUT_SPIKE),
    .BP                 (BP),
    .IN_VALID           (IN_VALID),
    .IN_SPIKE           (IN_SPIKE)
);

buffer1 buffer1 (
    .CLK                (CLK),
    .RSTB               (RSTB),
    .IN_VALID_INTERNAL  (IN_VALID_INTERNAL),
    .D                  (D2BUF1),
    .Q                  (QFBUF1),
    .DEPTH              (D1),
    .PD                 (PD_MEM)
);

buffer2 buffer2 (
    .CLK                (CLK),
    .RSTB               (RSTB),
    .IN_VALID_INTERNAL  (IN_VALID_INTERNAL),
    .D                  (D2BUF2),
    .Q                  (QFBUF2),
    .DEPTH              (D2),
    .PD                 (PD_MEM)
);

assign D2BUF2[15:0] = SPIKE_REMAP_TEMP[79:64];
assign D2BUF2[31:16] = SPIKE_REMAP_TEMP[143:128];
assign D2BUF2[47:32] = SPIKE_REMAP_TEMP[207:192];

assign D2BUF1[47:0] = QFBUF2;
assign D2BUF1[63:48] = IN_SPIKE_INTERNAL;

assign SPIKE_REMAP_TEMP[47:0] = QFBUF1[47:0];
assign SPIKE_REMAP_TEMP[63:48] = QFBUF2[15:0];
assign SPIKE_REMAP_TEMP[111:64] = QFBUF1[95:48];
assign SPIKE_REMAP_TEMP[127:112] = QFBUF2[31:16];
assign SPIKE_REMAP_TEMP[175:128] = QFBUF1[143:96];
assign SPIKE_REMAP_TEMP[191:176] = QFBUF2[47:32];
assign SPIKE_REMAP_TEMP[239:192] = QFBUF1[191:144];
assign SPIKE_REMAP_TEMP[255:240] = IN_SPIKE_INTERNAL;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        IN_VALID_INTERNAL_D1 <= 1'b0;
    else
        IN_VALID_INTERNAL_D1 <= IN_VALID_INTERNAL;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        SPIKE_REMAP <= 256'b0;
    else if (IN_VALID_INTERNAL_D1)
        SPIKE_REMAP <= SPIKE_REMAP_TEMP;

endmodule
