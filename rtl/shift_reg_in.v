
module shift_reg_in (
    CLK,
    RSTB,
    IN_VALID,
    IN_SPIKE,
    IN_VALID_INTERNAL,
    IN_SPIKE_INTERNAL,
    BP
);

parameter IO_WIDTH = 8;
parameter CNT_WIDTH = 1;
parameter CNT_MAX = 16/IO_WIDTH-1;

input CLK;
input RSTB;
input IN_VALID;
input [IO_WIDTH-1:0] IN_SPIKE;
output reg IN_VALID_INTERNAL;
output reg [15:0] IN_SPIKE_INTERNAL;
input BP;

reg [15:0] spike;
reg [CNT_WIDTH-1:0] cnt;

wire in_valid;

assign in_valid = ~BP & IN_VALID;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        IN_VALID_INTERNAL <= 1'b0;
    else if (in_valid && cnt == CNT_MAX)
        IN_VALID_INTERNAL <= 1'b1;
    else
        IN_VALID_INTERNAL <= 1'b0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        IN_SPIKE_INTERNAL <= 1'b0;
    else if (IN_VALID_INTERNAL)
        IN_SPIKE_INTERNAL <= spike;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        spike <= 16'd0;
    else if (in_valid)
        spike <= {IN_SPIKE, spike[15:IO_WIDTH]};

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        cnt <= 0;
    else if (in_valid)
        cnt <= cnt + 1;

endmodule
