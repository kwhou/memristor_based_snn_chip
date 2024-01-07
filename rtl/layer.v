
module layer (
    // Inference Mode
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
    // Memory Mode
    MS,
    CE,
    WE,
    BEB,
    RA,
    CA,
    D,
    F,
    Q,
    CL
);

parameter HW_WIDTH = 5;
parameter T_WIDTH = 5;
parameter D1_WIDTH = 5;
parameter D2_WIDTH = 9;
parameter NCFG_WIDTH = 6 * 16;
parameter TPD_WIDTH = 4;
parameter IO_WIDTH = 8;
parameter CNT_WIDTH = 1;

// Inference Mode
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
// Memory Mode
input MS;
input CE;
input WE;
input [7:0] BEB;
input [7:0] RA;
input [4:0] CA;
input [7:0] D;
input F;
output [7:0] Q;
input [5:0] CL;

wire EN;                    // cim macro computing enable
wire FT;                    // first time step
wire [255:0] SPIKE_REMAP;   // remapped spikes
wire [NCFG_WIDTH-1:0] NCFG; // neuron configuration of 16 neurons {enb, vth}*16
wire PD_CIM;                // power down signal for cim macro
wire SWP;                   // 0: neuron fires when v>vth, 1: neuron fires when v<vth
wire REQ;                   // neuron output request
wire [15:0] NEURON_OUT;     // neuron output data

layer_ctrl #(HW_WIDTH, T_WIDTH, D1_WIDTH, D2_WIDTH, NCFG_WIDTH, TPD_WIDTH, IO_WIDTH, CNT_WIDTH) layer_ctrl (
    .CLK            (CLK),
    .RSTB           (RSTB),
    .TM             (TM),
    .CFG_WE         (CFG_WE),
    .CFG_D          (CFG_D),
    .CFG_Q          (CFG_Q),
    .IN_VALID       (IN_VALID),
    .IN_SPIKE       (IN_SPIKE),
    .OUT_VALID      (OUT_VALID),
    .OUT_SPIKE      (OUT_SPIKE),
    .NCFG           (NCFG),
    .PD_CIM         (PD_CIM),
    .SWP            (SWP),
    .EN             (EN),
    .FT             (FT),
    .SPIKE_REMAP    (SPIKE_REMAP),
    .REQ            (REQ),
    .NEURON_OUT     (NEURON_OUT)
);

CIM_MACRO cim_macro (
    // Inference Mode
    .CLK            (CLK),
    .RSTB           (RSTB),
    .NCFG           (NCFG),
    .PD             (PD_CIM),
    .SWP            (SWP),
    .EN             (EN),
    .FT             (FT),
    .SPIKE_REMAP    (SPIKE_REMAP),
    .REQ            (REQ),
    .NEURON_OUT     (NEURON_OUT),
    // Program Mode
    .MS             (MS),
    .CE             (CE),
    .WE             (WE),
    .BEB            (BEB),
    .RA             (RA),
    .CA             (CA),
    .D              (D),
    .F              (F),
    .Q              (Q),
    .CL             (CL)
);

endmodule
