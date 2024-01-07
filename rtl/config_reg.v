
module config_reg (
    CLK,
    RSTB,
    CFG_WE,
    CFG_D,
    CFG_Q,
    HW,
    T,
    D1,
    D2,
    NCFG,
    TPD,
    PD_EN_MEM,
    PD_EN_CIM,
    BP,
    SWP
);

parameter HW_WIDTH = 5;
parameter T_WIDTH = 5;
parameter D1_WIDTH = 5;
parameter D2_WIDTH = 9;
parameter NCFG_WIDTH = 6 * 16;
parameter TPD_WIDTH = 4;

parameter CFG_WIDTH = HW_WIDTH + T_WIDTH + D1_WIDTH + D2_WIDTH + NCFG_WIDTH + TPD_WIDTH + 4;

input CLK;
input RSTB;
input CFG_WE;
input CFG_D;
output CFG_Q;

output [HW_WIDTH-1:0] HW;     // H-1 and W-1
output [T_WIDTH-1:0] T;       // T-1
output [D1_WIDTH-1:0] D1;     // depth of buffer1 - 1
output [D2_WIDTH-1:0] D2;     // depth of buffer2 - 1
output [NCFG_WIDTH-1:0] NCFG; // neuron configuration of 16 neurons {enb, vth}*16
output [TPD_WIDTH-1:0] TPD;   // wait time before power down
output PD_EN_MEM;             // power down enable for memory
output PD_EN_CIM;             // power down enable for cim macro
output BP;                    // 0: normal mode, 1: bypass mode
output SWP;                   // 0: neuron fires when v>vth, 1: neuron fires when v<vth

reg [CFG_WIDTH-1:0] cfg;
wire [CFG_WIDTH-1:0] cfg_out;

assign HW = cfg_out[HW_WIDTH-1:0];
assign T = cfg_out[T_WIDTH-1+HW_WIDTH:HW_WIDTH];
assign D1 = cfg_out[D1_WIDTH-1+T_WIDTH+HW_WIDTH:T_WIDTH+HW_WIDTH];
assign D2 = cfg_out[D2_WIDTH-1+D1_WIDTH+T_WIDTH+HW_WIDTH:D1_WIDTH+T_WIDTH+HW_WIDTH];
assign NCFG = cfg_out[NCFG_WIDTH-1+D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH:D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH];
assign TPD = cfg_out[TPD_WIDTH-1+NCFG_WIDTH+D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH:NCFG_WIDTH+D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH];
assign PD_EN_MEM = cfg_out[TPD_WIDTH+NCFG_WIDTH+D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH];
assign PD_EN_CIM = cfg_out[TPD_WIDTH+NCFG_WIDTH+D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH+1];
assign BP = cfg_out[TPD_WIDTH+NCFG_WIDTH+D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH+2];
assign SWP = cfg_out[TPD_WIDTH+NCFG_WIDTH+D2_WIDTH+D1_WIDTH+T_WIDTH+HW_WIDTH+3];

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        cfg <= 0;
    else if (CFG_WE)
        cfg <= {CFG_D, cfg[CFG_WIDTH-1:1]};

assign CFG_Q = cfg[0];
assign cfg_out = CFG_WE? 0 : cfg;

endmodule
