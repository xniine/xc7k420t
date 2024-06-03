`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2022 09:52:59 PM
// Design Name: 
// Module Name: pcie_pipe_clock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pcie_pipe_clock #(
    parameter PCIE_ASYNC_EN = "FALSE",
    parameter PCIE_LANE = 4
    ) (
    input  wire                 sys_clk           ,
    
    input  wire                 pipe_txoutclk_in  ,
    input  wire [PCIE_LANE-1:0] pipe_rxoutclk_in  ,
    input  wire [PCIE_LANE-1:0] pipe_pclk_sel_in  ,
    input  wire                 pipe_gen3_in      ,
    input  wire                 pipe_mmcm_rst_n   ,

    output wire                 pipe_pclk_out     ,
    output wire                 pipe_rxusrclk_out ,
    output wire [PCIE_LANE-1:0] pipe_rxoutclk_out ,
    output wire                 pipe_dclk_out     ,
    output wire                 pipe_userclk2_out ,
    output wire                 pipe_userclk1_out ,
    output wire                 pipe_oobclk_out   ,
    output wire                 pipe_mmcm_lock_out
    );
    
    //----------------------------------------------------------------------------
    wire mmcm_in    ;
    wire mmcm_clkfb ;
    wire mmcm_rst   ;
    wire mmcm_out0  ;
    wire mmcm_out1  ;
    wire mmcm_out2  ;
    wire mmcm_out3  ;
    wire mmcm_out4  ;
    wire mmcm_locked;
    
    BUFG(.O(mmcm_in), .I(pipe_txoutclk_in));
    //----------------------------------------------------------------------------
    // MMCM instance
    // PFD range: 10 MHz to 500 MHz
    // VCO range: 600 MHz to 1440 MHz
    // 100 MHz in, M = 10, D = 1 sets Fvco = 1000 MHz (in range)
    // 0) Divide by  8 to get output frequency of 125 MHz
    // 1) Divide by  4 to get output frequency of 250 MHz
    // 2) Divide by 16/8/4 to get output frequency for usrclk1 (62.5 MHz/125 MHz/250 MHz)
    // 3) Divide by 16/8/4 to get output frequency for usrclk2 (62.5 MHz/125 MHz/250 MHz)
    // 4) Divide by 20 to get output frequency of 50 MHz
    //----------------------------------------------------------------------------
    MMCME2_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_USE_FINE_PS("FALSE"),
        .CLKOUT0_DIVIDE_F(8),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_USE_FINE_PS("FALSE"),
        .CLKOUT1_DIVIDE(4),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_USE_FINE_PS("FALSE"),
        .CLKOUT2_DIVIDE(4),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_USE_FINE_PS("FALSE"),
        .CLKOUT3_DIVIDE(8),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_USE_FINE_PS("FALSE"),
        .CLKOUT4_DIVIDE(20),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT5_USE_FINE_PS("FALSE"),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        .CLKOUT6_USE_FINE_PS("FALSE"),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE(0),
        .CLKFBOUT_USE_FINE_PS("FALSE"),
        .CLKFBOUT_MULT_F(10),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .CLKIN1_PERIOD(10),
        .STARTUP_WAIT("FALSE"),
        .CLKOUT4_CASCADE("FALSE")
    )
    mmcm2_adv_0 (
        .CLKIN1(mmcm_in),
        .CLKFBIN(mmcm_clkfb),
        .RST(mmcm_rst),
        .PWRDWN(1'b0),
        .CLKOUT0(mmcm_out0),
        .CLKOUT0B(),
        .CLKOUT1(mmcm_out1),
        .CLKOUT1B(),
        .CLKOUT2(mmcm_out2),
        .CLKOUT2B(),
        .CLKOUT3(mmcm_out3),
        .CLKOUT3B(),
        .CLKOUT4(mmcm_out4),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED(mmcm_locked)
    );

    //----------------------------------------------------------------------------
    wire clk_125m, clk_250m, clk_500m;
    BUFG (.I(mmcm_out0), .O(clk_125m));
    BUFG (.I(mmcm_out1), .O(clk_250m));

    //----------------------------------------------------------------------------
    wire                 pipe_rst = !pipe_mmcm_rst_n;
    wire                 pipe_pclk;
    
    reg  [2:0] pipe_pclk_s0_q;
    reg        pipe_pclk_s0;
    reg  [2:0] pipe_pclk_s1_q;
    reg        pipe_pclk_s1;

    always @(posedge clk_250m) begin
        if (pipe_rst || !pipe_pclk_sel_in) begin
            // pipe_pclk_s0_q[0] <= 1'h1;
            pipe_pclk_s1_q[0] <= 1'h0;
        end else
        if (&pipe_pclk_sel_in) begin
            // pipe_pclk_s0_q[0] <= 1'h0;
            pipe_pclk_s1_q[0] <= 1'h1;
        end
    end
    always @(posedge clk_250m) begin
        if (pipe_rst) begin
            // pipe_pclk_s0 <= 1'h1;
            pipe_pclk_s1 <= 1'h0;
        end else begin
            // {pipe_pclk_s0,pipe_pclk_s0_q[2:1]} <= pipe_pclk_s0_q;
            {pipe_pclk_s1,pipe_pclk_s1_q[2:1]} <= pipe_pclk_s1_q;
        end
    end
    
    /* BUFGCTRL
    (
        .CE0    (1'd1),         
        .CE1    (1'd1),        
        .I0     (clk_125m),   
        .I1     (clk_250m),   
        .IGNORE0(1'd0),        
        .IGNORE1(1'd0),        
        .S0     (pipe_pclk_s0),    
        .S1     (pipe_pclk_s1),    
        .O      (pipe_pclk)
    ); */
    BUFGMUX
    (    
        .I0     (clk_125m),
        .I1     (clk_250m),
        .S      (pipe_pclk_s1),   
        .O      (pipe_pclk)
    );
    assign pipe_pclk_out     = pipe_pclk;
    assign pipe_rxusrclk_out = pipe_pclk;

    //----------------------------------------------------------------------------
    assign pipe_dclk_out = clk_125m;
    BUFG (.I(mmcm_out2), .O(pipe_userclk1_out));
    BUFG (.I(mmcm_out3), .O(pipe_userclk2_out));
    BUFG (.I(mmcm_out4), .O(pipe_oobclk_out  ));
    
    assign pipe_mmcm_lock_out = mmcm_locked;
    
    //----------------------------------------------------------------------------
    genvar n1;
    generate
    if (PCIE_ASYNC_EN == "TRUE") begin
    for (n1 = 0; n1 < PCIE_LANE; n1 = n1 + 1) begin
    BUFG (.I(pipe_rxoutclk_in), .O(pipe_rxoutclk_out));
    end
    end
    
    if (PCIE_ASYNC_EN != "TRUE") begin
    assign pipe_rxoutclk_out = {PCIE_LANE{1'h0}};
    end
    endgenerate

endmodule
