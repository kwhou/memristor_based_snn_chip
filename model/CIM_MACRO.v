
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
integer pd [0:15];

wire CLR1; // reset immediately
wire CLR2; // reset after firing
wire LOAD; // load spike enable
wire INT;  // integration enable
wire FIRE; // firing enable

reg [15:0] q;
reg [15:0] qb;
reg [15:0] NEURON_OUT_1;
reg [15:0] NEURON_OUT_2;
reg [15:0] READY_OUT;
reg [15:0] RESET_EN;

reg EN_d1;
reg EN_d2;
reg FT_d1;

// *************************************************
// Timing control
// *************************************************
assign LOAD = ~(CLK | ~EN_d1);
assign CLR1 = ~(CLK | ~(EN_d1 & ~EN_d2 & FT_d1));
assign CLR2 = ~(CLK | ~(EN_d1 & EN_d2 & FT_d1));
assign FIRE = ~(CLK | ~EN_d2);

ICG icg_int (.CP(CLK), .E(EN_d1), .Q(INT));

always @(posedge CLK or negedge RSTB) begin
    if (!RSTB) begin
        EN_d1 <= 0;
        EN_d2 <= 0;
        FT_d1 <= 0;
    end
    else begin
        EN_d1 <= EN;
        EN_d2 <= EN_d1;
        FT_d1 <= FT;
    end
end

always @(posedge CLK or negedge RSTB) begin
    if (!RSTB)
        REQ <= 0;
    else
        REQ <= FIRE;
end

// *************************************************
// Spike latch
// *************************************************
always @(*)
    if (LOAD)
        spike_reg = SPIKE_REMAP;

// *************************************************
// Synapse and neuron
// *************************************************
integer i, j, k, p;

initial begin
    NEURON_OUT_1 = 0;
    NEURON_OUT_2 = 0;
    READY_OUT = 0;
    RESET_EN = 0;
end

initial begin
    for (i=0; i<16; i=i+1)
        v[i] = 0;
end

always @(INT) begin
    if (INT) begin
        for (i=0; i<16; i=i+1) begin
            if (pd[i] == 0) begin
                dv = 0;
                for (j=0; j<256; j=j+1)
                    dv = dv + spike_reg[j] * (weight_p[i][j] - weight_n[i][j]);
                if (v[i] + dv >= 32)
                    v[i] = 32;
                else if (v[i] + dv <= -32)
                    v[i] = -32;
                else
                    v[i] = v[i] + dv;
            end
        end
    end
end

always @(*) begin
    for (p=0; p<16; p=p+1) begin
        RESET_EN[p] = READY_OUT[p] & (NEURON_OUT_2[p] | CLR2) | CLR1;
        if (RESET_EN[p] == 1)
            v[p] = 0;
    end
end

always @(FIRE) begin
    if (FIRE) begin
        for (k=0; k<16; k=k+1) begin
            if (pd[k] == 0) begin
                if (!SWP && (v[k] >= vth[k])) begin
                    q[k] = 1;
                    qb[k] = 0;
                end
                else if (SWP && (v[k] <= vth[k])) begin
                    q[k] = 1;
                    qb[k] = 0;
                end
                else begin
                    q[k] = 0;
                    qb[k] = 1;
                end
                NEURON_OUT_1[k] = q[k] & ~qb[k];
                NEURON_OUT_2[k] = q[k] & ~qb[k];
                READY_OUT[k] = q[k] ^ qb[k];
            end
        end
    end
    else begin
        for (k=0; k<16; k=k+1) begin
            q[k] = 1;
            qb[k] = 1;
            NEURON_OUT_2[k] = 0;
            READY_OUT[k] = 0;
        end
    end
end

always @(posedge CLK or negedge RSTB) begin
    if (!RSTB)
        NEURON_OUT <= 0;
    else
        NEURON_OUT <= NEURON_OUT_1;
end

// *************************************************
// Neuron configuration
// *************************************************
integer m, n;

reg [NCFG_WIDTH-1:0] ncfg;

always @(NCFG) begin
    ncfg = NCFG;
    for (m=0; m<16; m=m+1) begin
        vth[m] = ncfg[4:0];
        ncfg = {5'b0, ncfg[NCFG_WIDTH-1:5]};
    end
    for (m=0; m<16; m=m+1) begin
        enb[m] = ncfg[0];
        ncfg = {1'b0, ncfg[NCFG_WIDTH-1:1]};
    end
    for (m=0; m<16; m=m+1) begin
        pd[m] = enb[m] | PD;
    end
end

always @(PD) begin
    for (n=0; n<16; n=n+1)
        pd[n] = enb[n] | PD;
end

// *************************************************
// Task
// *************************************************
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

endmodule

