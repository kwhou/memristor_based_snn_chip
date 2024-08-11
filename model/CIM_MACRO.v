
module CIM_MACRO (
    // Inference Mode
    CLK,
    RSTB,
    NCFG,
    PD,
    SWP,
    EN,
    FT,
    SPIKE_REMAP,
    REQ,
    NEURON_OUT,
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

parameter NCFG_WIDTH = 6 * 16;

// Inference Mode
input CLK;                      // clock
input RSTB;                     // active low reset
input [NCFG_WIDTH-1:0] NCFG;    // neuron configuration of 16 neurons {enb, vth}*16
input PD;                       // power down signal
input SWP;                      // 0: neuron fires when v>vth, 1: neuron fires when v<vth
input EN;                       // cim macro computing enable
input FT;                       // first time step
input [255:0] SPIKE_REMAP;      // remapped spikes
output reg REQ;                 // neuron output request
output reg [15:0] NEURON_OUT;   // neuron output data
// Memory Mode
input MS;                       // cim macro mode selection (0: inference, 1: memory)
input CE;                       // chip enable for memory mode
input WE;                       // write enable
input [7:0] BEB;                // bit enable (active low)
input [7:0] RA;                 // row address
input [4:0] CA;                 // column address
input [7:0] D;                  // data in
input F;                        // forming enable
output [7:0] Q;                 // data out
input [5:0] CL;                 // reference current level selection

reg [255:0] spike_reg;
reg [255:0] weight_p [0:15];
reg [255:0] weight_n [0:15];

integer enb [0:15];
integer vth [0:15];
integer v [0:15];
integer dv;
integer i;
integer j;

reg CLR1; // reset immediately
reg CLR2; // reset after firing
reg LOAD; // load spike enable
reg INT;  // integration enable
reg FIRE; // firing enable

initial begin
    NEURON_OUT = 0;
end

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        CLR1 <= 1'b0;
    else if (FT && !INT)
        CLR1 <= 1'b1;
    else
        CLR1 <= 1'b0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        CLR2 <= 1'b0;
    else if (FT && INT)
        CLR2 <= 1'b1;
    else
        CLR2 <= 1'b0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB) begin
        LOAD <= 1'b0;
        INT <= 1'b0;
        FIRE <= 1'b0;
        REQ <= 1'b0;
    end
    else begin
        LOAD <= EN;
        INT <= LOAD;
        FIRE <= INT;
        REQ <= FIRE;
    end

always @(*)
    if (LOAD)
        spike_reg = SPIKE_REMAP;
    else
        spike_reg = spike_reg;

always @(posedge CLK or negedge RSTB or posedge CLR1 or posedge PD)
begin
    if (PD || !RSTB || CLR1) begin
        for (i=0; i<16; i=i+1)
            v[i] <= 0;
    end
    else if (INT) begin
        for (i=0; i<16; i=i+1) begin
            if (enb[i] == 0) begin
                dv = 0;
                for (j=0; j<256; j=j+1)
                    dv = dv + spike_reg[j] * (weight_p[i][j] - weight_n[i][j]);
                if (v[i] + dv >= 32)
                    v[i] <= 32;
                else if (v[i] + dv <= -32)
                    v[i] <= -32;
                else
                    v[i] <= v[i] + dv;
            end
        end
    end
    else if (FIRE) begin
        for (i=0; i<16; i=i+1) begin
            NEURON_OUT[i] <= 0;
            if (enb[i] == 0) begin
                if (!SWP && (v[i] >= vth[i])) begin
                    NEURON_OUT[i] <= 1;
                    v[i] <= 0;
                end
                else if (SWP && (v[i] <= vth[i])) begin
                    NEURON_OUT[i] <= 1;
                    v[i] <= 0;
                end
            end
        end
    end
    if (CLR2) begin
        for (i=0; i<16; i=i+1)
            v[i] <= 0;
    end
end

task Load_Positive_Weight;
input [511:0] fname;
begin
    $readmemb(fname, weight_p);
end
endtask

task Load_Negative_Weight;
input [511:0] fname;
begin
    $readmemb(fname, weight_n);
end
endtask

integer k;
reg [NCFG_WIDTH-1:0] ncfg;
always @(NCFG) begin
    ncfg = NCFG;
    for (k=0; k<16; k=k+1) begin
        vth[k] = ncfg[4:0];
        ncfg = {5'b0, ncfg[NCFG_WIDTH-1:5]};
    end
    for (k=0; k<16; k=k+1) begin
        enb[k] = ncfg[0];
        ncfg = {1'b0, ncfg[NCFG_WIDTH-1:1]};
    end
end

endmodule

