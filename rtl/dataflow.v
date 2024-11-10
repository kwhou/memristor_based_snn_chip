
module dataflow (
    CLK,
    RSTB,
    IN_VALID,
    EN,
    FT,
    HW,
    T,
    TPD,
    PD,
    BP
);

parameter HW_WIDTH = 5;
parameter T_WIDTH = 5;
parameter TPD_WIDTH = 4;
parameter IO_WIDTH = 16;

input CLK;
input RSTB;
input IN_VALID;
output reg EN;
output reg FT;
input [HW_WIDTH-1:0] HW; // H-1 and W-1
input [T_WIDTH-1:0] T;   // T-1
input [TPD_WIDTH-1:0] TPD;
output reg PD;
input BP;

reg [HW_WIDTH-1:0] h;
reg [HW_WIDTH-1:0] w;
reg [T_WIDTH-1:0] t;
reg e;
reg pd_tmp;
reg [TPD_WIDTH-1:0] pd_cnt;

parameter I = 4;
parameter J = 4;

always @(*)
    if (!IN_VALID)
        e = 0;
    else if (h <= I-2)
        e = 0;
    else if (w <= J-2)
        e = 0;
    else
        e = 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        t <= 0;
    else if (IN_VALID && t == T)
        t <= 0;
    else if (IN_VALID)
        t <= t + 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        w <= 0;
    else if (IN_VALID && t == T && w == HW)
        w <= 0;
    else if (IN_VALID && t == T)
        w <= w + 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        h <= 0;
    else if (IN_VALID && t == T && w == HW && h == HW)
        h <= 0;
    else if (IN_VALID && t == T && w == HW)
        h <= h + 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        EN <= 1'b0;
    else if (e)
        EN <= 1'b1;
    else
        EN <= 1'b0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        FT <= 0;
    else if (e && t == 0)
        FT <= 1;
    else
        FT <= 0;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        PD <= 1;
    else if (BP)
        PD <= 1;
    else if (IN_VALID && t == 0 && w == 0 && h == 0)
        PD <= 0;
    else if (pd_tmp && pd_cnt == TPD)
        PD <= 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        pd_tmp <= 1;
    else if (BP)
        pd_tmp <= 1;
    else if (IN_VALID && t == 0 && w == 0 && h == 0)
        pd_tmp <= 0;
    else if (IN_VALID && t == T && w == HW && h == HW)
        pd_tmp <= 1;

always @(posedge CLK or negedge RSTB)
    if (!RSTB)
        pd_cnt <= 0;
    else if (!pd_tmp)
        pd_cnt <= 0;
    else if (pd_cnt != TPD)
        pd_cnt <= pd_cnt + 1;

endmodule
