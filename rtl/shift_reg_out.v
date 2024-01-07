
module shift_reg_out (
    CLK,
    RSTB,
    OUT_VALID_INTERNAL,
    OUT_SPIKE_INTERNAL,
    OUT_VALID,
    OUT_SPIKE,
    BP,
    IN_VALID,
    IN_SPIKE
);

parameter IO_WIDTH = 8;
parameter CNT_WIDTH = 1;
parameter CNT_MAX = 16/IO_WIDTH-1;

input CLK;
input RSTB;
input OUT_VALID_INTERNAL;
input [15:0] OUT_SPIKE_INTERNAL;
output reg OUT_VALID;
output [IO_WIDTH-1:0] OUT_SPIKE;
input BP;
input IN_VALID;
input [IO_WIDTH-1:0] IN_SPIKE;

reg [15:0] spike;
reg [CNT_WIDTH-1:0] cnt;

assign OUT_SPIKE = spike[IO_WIDTH-1:0];

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        OUT_VALID <= 1'b0;
    else if (BP)
        OUT_VALID <= IN_VALID;
    else if (OUT_VALID_INTERNAL)
        OUT_VALID <= 1'b1;
    else if (OUT_VALID && cnt == CNT_MAX)
        OUT_VALID <= 1'b0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        spike[IO_WIDTH-1:0] <= 0;
    else if (BP)
        spike[IO_WIDTH-1:0] <= IN_SPIKE;
    else if (OUT_VALID_INTERNAL)
        spike[IO_WIDTH-1:0] <= OUT_SPIKE_INTERNAL[IO_WIDTH-1:0];
    else if (OUT_VALID)
        spike[IO_WIDTH-1:0] <= spike[2*IO_WIDTH-1:IO_WIDTH];

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        spike[15:IO_WIDTH] <= 0;
    else if (!BP && OUT_VALID_INTERNAL)
        spike[15:IO_WIDTH] <= OUT_SPIKE_INTERNAL[15:IO_WIDTH];
    else if (!BP && OUT_VALID)
        spike[15:IO_WIDTH] <= spike >> 2*IO_WIDTH;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        cnt <= 0;
    else if (!BP && OUT_VALID_INTERNAL)
        cnt <= 0;
    else if (!BP && OUT_VALID)
        cnt <= cnt + 1;

endmodule
