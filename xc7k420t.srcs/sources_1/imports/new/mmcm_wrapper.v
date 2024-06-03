`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2022 11:49:59 AM
// Design Name: 
// Module Name: mmcm_wrapper
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


module mmcm_wrapper(
    input  wire mmcm_in    ,
    output wire mmcm_rst   ,
    output wire mmcm_locked,
    output wire mmcm_out0  ,
    output wire mmcm_out1  ,
    output wire mmcm_out2  ,
    output wire mmcm_out3  ,
    output wire mmcm_out4  ,
    output wire mmcm_out5  ,
    output wire mmcm_out6
    );
    
//////////////////////////////////////////////////////////////////////////////////
// Clock Inputs & Resets
//////////////////////////////////////////////////////////////////////////////////
    wire mmcm_clkfb; 
    //----------------------------------------------------------------------------
    // MMCM instance
    // PFD range: 10 MHz to 500 MHz
    // VCO range: 600 MHz to 1440 MHz
    // 100 MHz in, M = 10, D = 1 sets Fvco = 1000 MHz (in range)
    // 0) Divide by 5 to get output frequency of 200MHz
    // 1) Divide by 8 to get output frequency of 125MHz
    
    MMCME2_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_USE_FINE_PS("FALSE"),
        .CLKOUT0_DIVIDE_F(5),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        
        .CLKOUT1_USE_FINE_PS("FALSE"),
        .CLKOUT1_DIVIDE(8),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        
        .CLKOUT2_USE_FINE_PS("FALSE"),
        .CLKOUT2_DIVIDE(8),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        
        .CLKOUT3_USE_FINE_PS("FALSE"),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        
        .CLKOUT4_USE_FINE_PS("FALSE"),
        .CLKOUT4_DIVIDE(1),
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
        .CLKOUT5(mmcm_out5),
        .CLKOUT6(mmcm_out6),
        .CLKFBOUT(mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED(mmcm_locked)
    );
    
endmodule
