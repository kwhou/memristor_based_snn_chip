
module network (
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
input CLK;                       // clock
input RSTB;                      // active low reset
input [1:0] TM;                  // test mode (00: normal, 01: scan, 10: mbist)
input CFG_WE;                    // configuration write enable
input CFG_D;                     // configuration data input
output CFG_Q;                    // configuration data output
input IN_VALID;                  // input spikes valid
input [IO_WIDTH-1:0] IN_SPIKE;   // input spikes
output OUT_VALID;                // output spikes valid
output [IO_WIDTH-1:0] OUT_SPIKE; // output spikes
// Memory Mode
input MS;                        // cim macro mode selection (0: inference, 1: memory)
input [4:0] CE;                  // chip enable for memory mode
input WE;                        // write enable
input [7:0] BEB;                 // bit enable (active low)
input [7:0] RA;                  // row address
input [4:0] CA;                  // column address
input [7:0] D;                   // data in
input F;                         // forming enable
output [7:0] Q;                  // data out
input [5:0] CL;                  // reference current level selection

wire OUT_VALID_L1;
wire OUT_VALID_L2;
wire OUT_VALID_L3;
wire OUT_VALID_L4;
wire [IO_WIDTH-1:0] OUT_SPIKE_L1;
wire [IO_WIDTH-1:0] OUT_SPIKE_L2;
wire [IO_WIDTH-1:0] OUT_SPIKE_L3;
wire [IO_WIDTH-1:0] OUT_SPIKE_L4;
wire CFG_Q1;
wire CFG_Q2;
wire CFG_Q3;
wire CFG_Q4;
wire [7:0] Q_L1;
wire [7:0] Q_L2;
wire [7:0] Q_L3;
wire [7:0] Q_L4;
wire [7:0] Q_L5;

assign Q = CE[0]? Q_L1 :
           CE[1]? Q_L2 :
           CE[2]? Q_L3 :
           CE[3]? Q_L4 :
           CE[4]? Q_L5 : 8'b0;

layer #(HW_WIDTH, T_WIDTH, D1_WIDTH, D2_WIDTH, NCFG_WIDTH, TPD_WIDTH, IO_WIDTH, CNT_WIDTH) layer1 (
    // Inference Mode
    .CLK        (CLK),
    .RSTB       (RSTB),
    .TM         (TM),
    .CFG_WE     (CFG_WE),
    .CFG_D      (CFG_D),
    .CFG_Q      (CFG_Q1),
    .IN_VALID   (IN_VALID),
    .IN_SPIKE   (IN_SPIKE),
    .OUT_VALID  (OUT_VALID_L1),
    .OUT_SPIKE  (OUT_SPIKE_L1),
    // Memory Mode
    .MS         (MS),
    .CE         (CE[0]),
    .WE         (WE),
    .BEB        (BEB),
    .RA         (RA),
    .CA         (CA),
    .D          (D),
    .F          (F),
    .Q          (Q_L1),
    .CL         (CL)
);

layer #(HW_WIDTH, T_WIDTH, D1_WIDTH, D2_WIDTH, NCFG_WIDTH, TPD_WIDTH, IO_WIDTH, CNT_WIDTH) layer2 (
    // Inference Mode
    .CLK        (CLK),
    .RSTB       (RSTB),
    .TM         (TM),
    .CFG_WE     (CFG_WE),
    .CFG_D      (CFG_Q1),
    .CFG_Q      (CFG_Q2),
    .IN_VALID   (OUT_VALID_L1),
    .IN_SPIKE   (OUT_SPIKE_L1),
    .OUT_VALID  (OUT_VALID_L2),
    .OUT_SPIKE  (OUT_SPIKE_L2),
    // Memory Mode
    .MS         (MS),
    .CE         (CE[1]),
    .WE         (WE),
    .BEB        (BEB),
    .RA         (RA),
    .CA         (CA),
    .D          (D),
    .F          (F),
    .Q          (Q_L2),
    .CL         (CL)
);

layer #(HW_WIDTH, T_WIDTH, D1_WIDTH, D2_WIDTH, NCFG_WIDTH, TPD_WIDTH, IO_WIDTH, CNT_WIDTH) layer3 (
    // Inference Mode
    .CLK        (CLK),
    .RSTB       (RSTB),
    .TM         (TM),
    .CFG_WE     (CFG_WE),
    .CFG_D      (CFG_Q2),
    .CFG_Q      (CFG_Q3),
    .IN_VALID   (OUT_VALID_L2),
    .IN_SPIKE   (OUT_SPIKE_L2),
    .OUT_VALID  (OUT_VALID_L3),
    .OUT_SPIKE  (OUT_SPIKE_L3),
    // Memory Mode
    .MS         (MS),
    .CE         (CE[2]),
    .WE         (WE),
    .BEB        (BEB),
    .RA         (RA),
    .CA         (CA),
    .D          (D),
    .F          (F),
    .Q          (Q_L3),
    .CL         (CL)
);

layer #(HW_WIDTH, T_WIDTH, D1_WIDTH, D2_WIDTH, NCFG_WIDTH, TPD_WIDTH, IO_WIDTH, CNT_WIDTH) layer4 (
    // Inference Mode
    .CLK        (CLK),
    .RSTB       (RSTB),
    .TM         (TM),
    .CFG_WE     (CFG_WE),
    .CFG_D      (CFG_Q3),
    .CFG_Q      (CFG_Q4),
    .IN_VALID   (OUT_VALID_L3),
    .IN_SPIKE   (OUT_SPIKE_L3),
    .OUT_VALID  (OUT_VALID_L4),
    .OUT_SPIKE  (OUT_SPIKE_L4),
    // Memory Mode
    .MS         (MS),
    .CE         (CE[3]),
    .WE         (WE),
    .BEB        (BEB),
    .RA         (RA),
    .CA         (CA),
    .D          (D),
    .F          (F),
    .Q          (Q_L4),
    .CL         (CL)
);

layer #(HW_WIDTH, T_WIDTH, D1_WIDTH, D2_WIDTH, NCFG_WIDTH, TPD_WIDTH, IO_WIDTH, CNT_WIDTH) layer5 (
    // Inference Mode
    .CLK        (CLK),
    .RSTB       (RSTB),
    .TM         (TM),
    .CFG_WE     (CFG_WE),
    .CFG_D      (CFG_Q4),
    .CFG_Q      (CFG_Q),
    .IN_VALID   (OUT_VALID_L4),
    .IN_SPIKE   (OUT_SPIKE_L4),
    .OUT_VALID  (OUT_VALID),
    .OUT_SPIKE  (OUT_SPIKE),
    // Memory Mode
    .MS         (MS),
    .CE         (CE[4]),
    .WE         (WE),
    .BEB        (BEB),
    .RA         (RA),
    .CA         (CA),
    .D          (D),
    .F          (F),
    .Q          (Q_L5),
    .CL         (CL)
);

endmodule
