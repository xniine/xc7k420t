`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2020 12:21:28 PM
// Design Name: 
// Module Name: gtwizard_usrclk
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


module gtwizard_usrclk #(
    parameter CLOCK_STYLE="PLL",
    parameter N=1
    ) (
    output wire [N-1:0] gtusrclk2_out,
    output wire [N-1:0] gtusrclk_out ,
    input  wire         gtoutclk_in  ,
    input  wire [N-1:0] mmcm_reset_in,
    output wire [N-1:0] mmcm_lock_out
    );
    
//////////////////////////////////////////////////////////////////////////////////
    genvar n1;
    generate
        for (n1 = 1; n1 < N; n1 = n1 + 1) begin
            assign gtusrclk_out [n1] = gtusrclk_out [0];
            assign gtusrclk2_out[n1] = gtusrclk2_out[0];
        end
    endgenerate
//////////////////////////////////////////////////////////////////////////////////
if (CLOCK_STYLE == "MMCM") begin
    wire mmcm_clkfb, mmcm_rst, mmcm_locked;
    wire mmcm_in  ;
    wire mmcm_out0;
    wire mmcm_out1;
//--------------------------------------------------------------------------------
    // MMCM instance
    // PFD range: 10 MHz to 500 MHz
    // VCO range: 600 MHz to 1440 MHz
    // 322.26 MHz in, M = 2, D = 1 sets Fvco = 644.53 MHz (in range)
    // 1) Divide by 2 to get output frequency of 322.26 MHz
    // 2) Divide by 4 to get output frequency of 161.13 MHz
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F(2),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(4),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE(0),
        .CLKFBOUT_MULT_F(2),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .CLKIN1_PERIOD(3.103),
        .STARTUP_WAIT("FALSE"),
        .CLKOUT4_CASCADE("FALSE")
    )
    mmcm2_base_0 (
        .CLKIN1(mmcm_in),
        .CLKFBIN(mmcm_clkfb),
        .RST(mmcm_rst),
        .PWRDWN(1'b0),
        .CLKOUT0(mmcm_out0),
        .CLKOUT0B(),
        .CLKOUT1(mmcm_out1),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED(mmcm_locked)
    );
//--------------------------------------------------------------------------------
    assign mmcm_lock_out = {N{mmcm_locked}};
    assign mmcm_rst = |mmcm_reset_in;
//--------------------------------------------------------------------------------
    BUFG bufg_0 (.I(gtoutclk_in), .O(mmcm_in         ));
    BUFG bufg_1 (.I(mmcm_out0  ), .O(gtusrclk_out [0]));
    BUFG bufg_2 (.I(mmcm_out1  ), .O(gtusrclk2_out[0]));
end
//////////////////////////////////////////////////////////////////////////////////
if (CLOCK_STYLE == "PLL") begin
    wire pll_clkfb, pll_rst, pll_locked;
    wire pll_in  ;
    wire pll_out0;
    wire pll_out1;
//--------------------------------------------------------------------------------
    // PLL instance
    // PFD range: 10 MHz to 500 MHz
    // VCO range: 800 MHz to 1866 MHz
    // 322.26 MHz in, M = 4, D = 1 sets Fvco = 1289.06 MHz (in range)
    // 1) Divide by 4 to get output frequency of 322.26 MHz
    // 2) Divide by 8 to get output frequency of 161.13 MHz
    PLLE2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_DIVIDE(4),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(8),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        .CLKFBOUT_MULT(4),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .CLKIN1_PERIOD(3.103),
        .STARTUP_WAIT("FALSE")
    )
    plle2_base_0 (
        .CLKIN1(pll_in),
        .CLKFBIN(pll_clkfb),
        .RST(pll_rst),
        .PWRDWN(1'b0),
        .CLKOUT0(pll_out0),
        .CLKOUT1(pll_out1),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKFBOUT(pll_clkfb),
        .LOCKED(pll_locked)
    );
//--------------------------------------------------------------------------------
    assign mmcm_lock_out = {N{pll_locked}};
    assign pll_rst = |mmcm_reset_in;
//--------------------------------------------------------------------------------
    BUFG bufg_gtoutlck  (.I(gtoutclk_in), .O(pll_in          ));
    BUFG bufg_gtusrclk  (.I(pll_out0   ), .O(gtusrclk_out [0]));
    BUFG bufg_gtusrclk2 (.I(pll_out1   ), .O(gtusrclk2_out[0]));
end
//////////////////////////////////////////////////////////////////////////////////

endmodule
