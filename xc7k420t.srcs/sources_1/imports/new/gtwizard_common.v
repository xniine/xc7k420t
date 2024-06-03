`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2020 01:44:27 PM
// Design Name: 
// Module Name: gtwizard_common
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


module gtwizard_common #(
    parameter SIM_GTRESET_SPEEDUP = "TRUE", // Set to "true" to speed up sim reset
    parameter STABLE_CLOCK_PERIOD = 10    , // Period of the stable clock driving this state-machine, unit is [ns]
    parameter QPLLREFCLK_SEL      = 3'b001, // 3'b001: GTREFCLK0, 3'b010: GTREFCLK1
    parameter QPLL_FBDIV_TOP      = 66
    ) (
    input  wire gtrefclk_in,
    input  wire sysclk_in,
    input  wire reset_in,
    // QPLL Clock Output
    output wire qplllock_out,
    output wire qplloutclk_out,
    output wire qplloutrefclk_out,
    output wire qpllrefclklost_out,
    input  wire qpllreset_in
    );

//////////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
//////////////////////////////////////////////////////////////////////////////////

    localparam QPLL_FBDIV_IN  = (QPLL_FBDIV_TOP == 16 ) ? 10'b0000100000 :
        (QPLL_FBDIV_TOP == 20 ) ? 10'b0000110000 :
        (QPLL_FBDIV_TOP == 32 ) ? 10'b0001100000 :
        (QPLL_FBDIV_TOP == 40 ) ? 10'b0010000000 :
        (QPLL_FBDIV_TOP == 64 ) ? 10'b0011100000 :
        (QPLL_FBDIV_TOP == 66 ) ? 10'b0101000000 :
        (QPLL_FBDIV_TOP == 80 ) ? 10'b0100100000 :
        (QPLL_FBDIV_TOP == 100) ? 10'b0101110000 : 10'b0000000000;
    
    localparam QPLL_FBDIV_RATIO = (QPLL_FBDIV_TOP == 16)  ? 1'b1 :
        (QPLL_FBDIV_TOP == 20 ) ? 1'b1 :
        (QPLL_FBDIV_TOP == 32 ) ? 1'b1 :
        (QPLL_FBDIV_TOP == 40 ) ? 1'b1 :
        (QPLL_FBDIV_TOP == 64 ) ? 1'b1 :
        (QPLL_FBDIV_TOP == 66 ) ? 1'b0 :
        (QPLL_FBDIV_TOP == 80 ) ? 1'b1 :
        (QPLL_FBDIV_TOP == 100) ? 1'b1 : 1'b1;

//////////////////////////////////////////////////////////////////////////////////
// 7 Series Transceivers - Reset Requirements Upon Configuration
//////////////////////////////////////////////////////////////////////////////////

    localparam integer STARTUP_DELAY       = 500; // AR43482: Transceiver needs to wait for 500 ns after configuration
    localparam integer WAIT_CYCLES         = STARTUP_DELAY / STABLE_CLOCK_PERIOD + 10; // Number of Clock-Cycles to wait after configuration

    reg [7:0] initreset_wait = 1'b0; // 8-Bits: Assumming CLOCK_PERIOD > 2ns (Freq < 500MHz)
    reg       initreset_done = 1'b0;
    reg       qpllreset = 1'b0;
    
    always @(posedge sysclk_in) begin
        if (initreset_wait <= WAIT_CYCLES) begin
            initreset_wait <= initreset_wait + 1;
        end else
        if (initreset_done != 1'b1) begin // QPLL Init Reset
            initreset_done <= 1'b1;
            qpllreset      <= 1'b1;
        end else begin
            qpllreset <= qpllreset_in;
        end
        //-------------------------------------------------------------------------
        if (reset_in) begin
            initreset_wait <= 8'h0;
            initreset_done <= 1'h0;
        end
    end

//////////////////////////////////////////////////////////////////////////////////

    wire [63:0] tied_to_gnd = 64'h0000000000000000;
    wire [63:0] tied_to_vcc = 64'hffffffffffffffff;
    
    //----------------------------------------------------------------------------
    // External Reference Clocks
    //----------------------------------------------------------------------------
    wire [2:0] qpllrefclksel = QPLLREFCLK_SEL; 
    wire       gtrefclk0     ;
    wire       gtrefclk1     ;
    wire       gtnorthrefclk0;
    wire       gtnorthrefclk1;
    wire       gtsouthrefclk0;
    wire       gtsouthrefclk1;
    
    generate
        if (QPLLREFCLK_SEL == 3'b001) begin
            assign gtrefclk0      = gtrefclk_in;
            assign gtrefclk1      = 1'h0;
            assign gtnorthrefclk0 = 1'h0;
            assign gtnorthrefclk1 = 1'h0;
            assign gtsouthrefclk0 = 1'h0;
            assign gtsouthrefclk1 = 1'h0;
        end else
        if (QPLLREFCLK_SEL == 3'b010) begin
            assign gtrefclk0      = 1'h0;
            assign gtrefclk1      = gtrefclk_in;
            assign gtnorthrefclk0 = 1'h0;
            assign gtnorthrefclk1 = 1'h0;
            assign gtsouthrefclk0 = 1'h0;
            assign gtsouthrefclk1 = 1'h0;
        end else
        if (QPLLREFCLK_SEL == 3'b011) begin
            assign gtrefclk0      = 1'h0;
            assign gtrefclk1      = 1'h0;
            assign gtnorthrefclk0 = gtrefclk_in;
            assign gtnorthrefclk1 = 1'h0;
            assign gtsouthrefclk0 = 1'h0;
            assign gtsouthrefclk1 = 1'h0;
        end else
        if (QPLLREFCLK_SEL == 3'b100) begin
            assign gtrefclk0      = 1'h0;
            assign gtrefclk1      = 1'h0;
            assign gtnorthrefclk0 = 1'h0;
            assign gtnorthrefclk1 = gtrefclk_in;
            assign gtsouthrefclk0 = 1'h0;
            assign gtsouthrefclk1 = 1'h0;
        end else
        if (QPLLREFCLK_SEL == 3'b101) begin
            assign gtrefclk0      = 1'h0;
            assign gtrefclk1      = 1'h0;
            assign gtnorthrefclk0 = 1'h0;
            assign gtnorthrefclk1 = 1'h0;
            assign gtsouthrefclk0 = gtrefclk_in;
            assign gtsouthrefclk1 = 1'h0;
        end else
        if (QPLLREFCLK_SEL == 3'b110) begin
            assign gtrefclk0      = 1'h0;
            assign gtrefclk1      = 1'h0;
            assign gtnorthrefclk0 = 1'h0;
            assign gtnorthrefclk1 = 1'h0;
            assign gtsouthrefclk0 = 1'h0;
            assign gtsouthrefclk1 = gtrefclk_in;
        end
    endgenerate

//////////////////////////////////////////////////////////////////////////////////
// 7 Series Transceivers - Shared Features
//////////////////////////////////////////////////////////////////////////////////

    GTXE2_COMMON #(
        //------------------------ Simulation attributes -------------------------
        .SIM_RESET_SPEEDUP              (SIM_GTRESET_SPEEDUP),
        .SIM_QPLLREFCLK_SEL             (QPLLREFCLK_SEL), // (3'b001: GTREFCLK0, 3'b010: GTREFCLK1)
        .SIM_VERSION                    ("4.0"),
        //---------------------- COMMON BLOCK Attributes -------------------------
        .BIAS_CFG                       (64'h0000040000001000),
        .COMMON_CFG                     (32'h00000000),
        .QPLL_CFG                       (27'h0680181),
        .QPLL_CLKOUT_CFG                (4'b0000),
        .QPLL_COARSE_FREQ_OVRD          (6'b010000),
        .QPLL_COARSE_FREQ_OVRD_EN       (1'b0),
        .QPLL_CP                        (10'b0000011111),
        .QPLL_CP_MONITOR_EN             (1'b0),
        .QPLL_DMONITOR_SEL              (1'b0),
        .QPLL_FBDIV                     (QPLL_FBDIV_IN),
        .QPLL_FBDIV_MONITOR_EN          (1'b0),
        .QPLL_FBDIV_RATIO               (QPLL_FBDIV_RATIO),
        .QPLL_INIT_CFG                  (24'h000006),
        .QPLL_LOCK_CFG                  (16'h21E8),
        .QPLL_LPF                       (4'b1111),
        .QPLL_REFCLK_DIV                (1)
    )
    gtxe2_common_0 (
        //---------- Common Block - Dynamic Reconfiguration Port (DRP) -----------
        .DRPADDR                        (tied_to_gnd),
        .DRPCLK                         (tied_to_gnd),
        .DRPDI                          (tied_to_gnd),
        .DRPDO                          (),
        .DRPEN                          (tied_to_gnd),
        .DRPRDY                         (),
        .DRPWE                          (tied_to_gnd),
        //------------------- Common Block - Ref Clock Ports ---------------------
        .GTGREFCLK                      (tied_to_gnd),
        .GTNORTHREFCLK0                 (gtnorthrefclk0),
        .GTNORTHREFCLK1                 (gtnorthrefclk1),
        .GTREFCLK0                      (gtrefclk0     ),
        .GTREFCLK1                      (gtrefclk1     ),
        .GTSOUTHREFCLK0                 (gtsouthrefclk0),
        .GTSOUTHREFCLK1                 (gtsouthrefclk1),
        //-------------------- Common Block - Clocking Ports ---------------------
        .QPLLOUTCLK                     (qplloutclk_out),
        .QPLLOUTREFCLK                  (qplloutrefclk_out),
        .REFCLKOUTMONITOR               (),
        //---------------------- Common Block - QPLL Ports -----------------------
        .QPLLDMONITOR                   (),
        .QPLLFBCLKLOST                  (),
        .QPLLLOCK                       (qplllock_out),
        .QPLLLOCKDETCLK                 (sysclk_in),
        .QPLLLOCKEN                     (tied_to_vcc),
        .QPLLOUTRESET                   (tied_to_gnd),
        .QPLLPD                         (tied_to_gnd),
        .QPLLREFCLKLOST                 (qpllrefclklost_out),
        .QPLLREFCLKSEL                  (qpllrefclksel), // (3'b001: GTREFCLK0, 3'b010: GTREFCLK1)
        .QPLLRESET                      (qpllreset), // reset signal with 500ns delay upon configuration
        .QPLLRSVD1                      (16'b0000000000000000),
        .QPLLRSVD2                      (5'b11111),
        //------------------------------ QPLL Ports ------------------------------
        .BGBYPASSB                      (tied_to_vcc),
        .BGMONITORENB                   (tied_to_vcc),
        .BGPDB                          (tied_to_vcc),
        .BGRCALOVRD                     (5'b11111),
        .PMARSVD                        (8'b00000000),
        .RCALENB                        (tied_to_vcc)
    );

endmodule
