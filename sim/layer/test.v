`timescale 1ns / 10ps

module test;

parameter HW_WIDTH = 5;
parameter T_WIDTH = 5;
parameter D1_WIDTH = 5;
parameter D2_WIDTH = 9;
parameter NCFG_WIDTH = 6 * 16;
parameter TPD_WIDTH = 4;
parameter IO_WIDTH = 8;
parameter CLK_HALF_PERIOD = 5;

`ifndef NIMG
    integer NIMG = 1;
`else
    integer NIMG = `NIMG;
`endif

reg CLK;
reg RSTB;
reg IN_VALID;
reg [IO_WIDTH-1:0] IN_SPIKE;
wire OUT_VALID;
wire [IO_WIDTH-1:0] OUT_SPIKE;
reg CFG_WE;
reg CFG_D;
wire CFG_Q;

layer layer (
    // Digital
    .CLK        (CLK),
    .RSTB       (RSTB),
    .TM         (2'b00),
    .CFG_WE     (CFG_WE),
    .CFG_D      (CFG_D),
    .CFG_Q      (CFG_Q),
    .IN_VALID   (IN_VALID),
    .IN_SPIKE   (IN_SPIKE),
    .OUT_VALID  (OUT_VALID),
    .OUT_SPIKE  (OUT_SPIKE),
    // Analog
    .MS         (1'b0),
    .CE         (1'b0),
    .WE         (1'b0),
    .BEB        (8'b1111_1111),
    .RA         (8'b0),
    .CA         (5'b0),
    .D          (8'b0),
    .F          (1'b0),
    .Q          (),
    .CL         (6'b0)
);

initial CLK = 0;
always #CLK_HALF_PERIOD CLK = ~CLK;

initial begin
`ifdef LAYER1
    layer.cim_macro.Load_Positive_Weight("../../data/layer1/weight_p.txt");
    layer.cim_macro.Load_Negative_Weight("../../data/layer1/weight_n.txt");
`elsif LAYER2
    layer.cim_macro.Load_Positive_Weight("../../data/layer2/weight_p.txt");
    layer.cim_macro.Load_Negative_Weight("../../data/layer2/weight_n.txt");
`elsif LAYER3
    layer.cim_macro.Load_Positive_Weight("../../data/layer3/weight_p.txt");
    layer.cim_macro.Load_Negative_Weight("../../data/layer3/weight_n.txt");
`elsif LAYER4
    layer.cim_macro.Load_Positive_Weight("../../data/layer4/weight_p.txt");
    layer.cim_macro.Load_Negative_Weight("../../data/layer4/weight_n.txt");
`elsif LAYER5
    layer.cim_macro.Load_Positive_Weight("../../data/layer5/weight_p.txt");
    layer.cim_macro.Load_Negative_Weight("../../data/layer5/weight_n.txt");
`else
    layer.cim_macro.Load_Positive_Weight("../../data/layer1/weight_p.txt");
    layer.cim_macro.Load_Negative_Weight("../../data/layer1/weight_n.txt");
`endif
end

`ifdef LAYER1
    parameter HW = 16;
    parameter CK = 16;
    parameter T = 8;
`elsif LAYER2
    parameter HW = 13;
    parameter CK = 16;
    parameter T = 8;
`elsif LAYER3
    parameter HW = 10;
    parameter CK = 16;
    parameter T = 8;
`elsif LAYER4
    parameter HW = 7;
    parameter CK = 16;
    parameter T = 8;
`elsif LAYER5
    parameter HW = 4;
    parameter CK = 16;
    parameter T = 8;
`else
    parameter HW = 16;
    parameter CK = 16;
    parameter T = 8;
`endif

integer input_finish, output_finish;
initial begin
    input_finish = 0;
    RSTB = 0;
    IN_VALID = 0;
    CFG_WE = 0;
    CFG_D = 0;
    @(posedge CLK);
    #1;
    RSTB = 1;

`ifdef LAYER1
    LoadCFG(HW, "../../data/layer1/vth.txt");
`elsif LAYER2
    LoadCFG(HW, "../../data/layer2/vth.txt");
`elsif LAYER3
    LoadCFG(HW, "../../data/layer3/vth.txt");
`elsif LAYER4
    LoadCFG(HW, "../../data/layer4/vth.txt");
`elsif LAYER5
    LoadCFG(HW, "../../data/layer5/vth.txt");
`else
    LoadCFG(HW, "../../data/layer1/vth.txt");
`endif

    repeat (NIMG) begin
`ifdef LAYER1
        InputSpike("../../data/layer1/input_spike.txt");
`elsif LAYER2
        InputSpike("../../data/layer2/input_spike.txt");
`elsif LAYER3
        InputSpike("../../data/layer3/input_spike.txt");
`elsif LAYER4
        InputSpike("../../data/layer4/input_spike.txt");
`elsif LAYER5
        InputSpike("../../data/layer5/input_spike.txt");
`else
        InputSpike("../../data/layer1/input_spike.txt");
`endif
    end
    input_finish = 1;
end

initial begin
    while(input_finish == 0 || output_finish == 0)
        @(posedge CLK);
    #1000;
    $finish;
end

reg error = 0;
reg [15:0] output_spike;
reg [15:0] mem_output [0:HW*HW*T-1];
integer n = 0, line = 0, fd;
integer total_n = 0;
initial begin
    output_finish = 0;
`ifdef LAYER1
    $readmemb("../../data/layer1/output_spike.txt", mem_output);
`elsif LAYER2
    $readmemb("../../data/layer2/output_spike.txt", mem_output);
`elsif LAYER3
    $readmemb("../../data/layer3/output_spike.txt", mem_output);
`elsif LAYER4
    $readmemb("../../data/layer4/output_spike.txt", mem_output);
`elsif LAYER5
    $readmemb("../../data/layer5/output_spike.txt", mem_output);
`else
    $readmemb("../../data/layer1/output_spike.txt", mem_output);
`endif
    output_spike = 0;
    total_n = (1+(HW-4))*(1+(HW-4))*T*CK/IO_WIDTH;
    repeat (NIMG) begin
        n = 0;
        line = 0;
        while (n < total_n) begin
            @(posedge CLK);
            if (OUT_VALID) begin
                if (n % 200 == 0) $display("Output: %d / %0d", n, total_n);
                n = n + 1;
                output_spike = {OUT_SPIKE, output_spike[15:IO_WIDTH]};
                if (n % (CK/IO_WIDTH) == 0) begin
                    if (output_spike !== mem_output[line]) begin
                        error = 1;
                        $display("Error: time %0t ps, exp data %h, real data %h", $time, mem_output[line], output_spike);
                    end
                    line = line + 1;
                end
            end
        end
    end
    if (error == 1)
        $display("---------- Simulation Fail! ----------");
    else
        $display("---------- Simulation Pass! ----------");
    output_finish = 1;
end

task LoadCFG;
input integer HWi;
input [511:0] fname;
integer i, j, fd, vth;
reg [HW_WIDTH-1:0] hw;
reg [T_WIDTH-1:0] t;
reg [D1_WIDTH-1:0] d1;
reg [D2_WIDTH-1:0] d2;
reg [NCFG_WIDTH-1:0] ncfg;
reg [TPD_WIDTH-1:0] tpd;
reg pd_en_mem;
reg pd_en_cim;
reg bp;
reg swp;
begin
    hw = HWi-1;
    t = T-1;
    d1 = T-1;
    d2 = (HWi - 4) * T + T - 1;
    tpd = 10;
    pd_en_mem = 1;
    pd_en_cim = 1;
    bp = 0;
    swp = 0;
    
    // HW
    for (i=0; i<HW_WIDTH; i=i+1) begin
        @(posedge CLK);
        #1;
        CFG_WE = 1;
        CFG_D = hw[0];
        hw = {1'b0, hw[HW_WIDTH-1:1]};
    end
    
    // T
    for (i=0; i<T_WIDTH; i=i+1) begin
        @(posedge CLK);
        #1;
        CFG_WE = 1;
        CFG_D = t[0];
        t = {1'b0, t[T_WIDTH-1:1]};
    end
    
    // D1
    for (i=0; i<D1_WIDTH; i=i+1) begin
        @(posedge CLK);
        #1;
        CFG_WE = 1;
        CFG_D = d1[0];
        d1 = {1'b0, d1[D1_WIDTH-1:1]};
    end
    
    // D2
    for (i=0; i<D2_WIDTH; i=i+1) begin
        @(posedge CLK);
        #1;
        CFG_WE = 1;
        CFG_D = d2[0];
        d2 = {1'b0, d2[D2_WIDTH-1:1]};
    end
    
    // NCFG
    fd = $fopen(fname, "r");
    for (i=0; i<16; i=i+1) begin
        j = $fscanf(fd, "%d\n", vth);
        if (j == 1)
            ncfg[NCFG_WIDTH-1:NCFG_WIDTH-5] = vth;
        else
            ncfg[NCFG_WIDTH-1:NCFG_WIDTH-5] = 0;
        if (i != 15)
            ncfg = {5'b0, ncfg[NCFG_WIDTH-1:5]};
        else
            ncfg = {1'b0, ncfg[NCFG_WIDTH-1:1]};
    end
    $fclose(fd);
    
    fd = $fopen(fname, "r");
    for (i=0; i<16; i=i+1) begin
        j = $fscanf(fd, "%d\n", vth);
        if (j == 1)
            ncfg[NCFG_WIDTH-1] = 0;
        else
            ncfg[NCFG_WIDTH-1] = 1;
        if (i != 15)
            ncfg = {1'b0, ncfg[NCFG_WIDTH-1:1]};
    end
    $fclose(fd);
    
    for (i=0; i<NCFG_WIDTH; i=i+1) begin
        @(posedge CLK);
        #1;
        CFG_WE = 1;
        CFG_D = ncfg[0];
        ncfg = {1'b0, ncfg[NCFG_WIDTH-1:1]};
    end
    
    // TPD
    for (i=0; i<TPD_WIDTH; i=i+1) begin
        @(posedge CLK);
        #1;
        CFG_WE = 1;
        CFG_D = tpd[0];
        tpd = {1'b0, tpd[TPD_WIDTH-1:1]};
    end
    
    // PD_EN_MEM
    @(posedge CLK);
    #1;
    CFG_WE = 1;
    CFG_D = pd_en_mem;
    
    // PD_EN_CIM
    @(posedge CLK);
    #1;
    CFG_WE = 1;
    CFG_D = pd_en_cim;
    
    // BP
    @(posedge CLK);
    #1;
    CFG_WE = 1;
    CFG_D = bp;
    
    // SWP
    @(posedge CLK);
    #1;
    CFG_WE = 1;
    CFG_D = swp;
    
    // Finish
    @(posedge CLK);
    #1;
    CFG_WE = 0;
    CFG_D = 0;
end
endtask

task InputSpike;
input [511:0] fname;
reg [CK-1:0] mem [0:HW*HW*T-1];
integer i, j, k;
integer cnt, rnd, randfile;
begin
    $readmemb(fname, mem);
    for (i=0; i<HW*HW; i=i+1) begin
        for (j=0; j<T; j=j+1) begin
            for (k=0; k<CK/IO_WIDTH; k=k+1) begin
                @(posedge CLK);
                #1;
                IN_VALID = 1;
                IN_SPIKE = mem[i*T+j][IO_WIDTH-1:0];
                mem[i*T+j] = mem[i*T+j] >> IO_WIDTH;
            end
        end
    end
    @(posedge CLK);
    #1;
    IN_VALID = 0;
    IN_SPIKE = 0;
end
endtask

initial begin
    $dumpfile("wave.vcd");
    $dumpvars;
end

endmodule
