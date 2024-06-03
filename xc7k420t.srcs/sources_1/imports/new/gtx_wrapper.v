`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2022 10:09:46 AM
// Design Name: 
// Module Name: gtx
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


module gtx_wrapper #(
    parameter SYSCLK_PERIOD = 10
    ) (
    input  wire         soft_reset ,
    input  wire         sysclk     ,
    input  wire [  3:0] gtx_rxreset,
    input  wire [  3:0] gtx_txreset,
    // GTX Transceivers
    input  wire [  0:0] gtrefclkp ,
    input  wire [  0:0] gtrefclkn ,
    output wire [  3:0] gtx_txn   ,
    output wire [  3:0] gtx_txp   ,
    input  wire [  3:0] gtx_rxn   ,
    input  wire [  3:0] gtx_rxp   ,
    // GTX ResetDone, GTX UserCLK2
    output wire [  3:0] gtx_txreset_done,
    output wire [  3:0] gtx_rxreset_done,
    output wire [  3:0] gtx_txusrclk2,
    output wire [  3:0] gtx_rxusrclk2,
    // GTX DRP
    input  wire [ 31:0] gtx_drpaddr,
    input  wire [ 63:0] gtx_drpdi  ,
    output wire [ 63:0] gtx_drpdo  ,
    input  wire [  3:0] gtx_drpen  ,
    input  wire [  3:0] gtx_drpwe  ,
    output wire [  3:0] gtx_drprdy ,
    // GTX GearBox
    output wire [ 27:0] txsequence,
    input  wire [  7:0] txheader  ,
    input  wire [255:0] txdata    ,
    // RX Gearbox
    input  wire [  3:0] rxgearboxslip,
    output wire [  3:0] rxheadervalid,
    output wire [  7:0] rxheader     ,
    output wire [  3:0] rxdatavalid  ,
    output wire [255:0] rxdata
    );

    wire [ 2:0] gtx_loopback [3:0]; // Default to 3'h0
    wire [ 2:0] gtx_txprbssel[3:0]; // Default to 3'h0
    wire [ 2:0] gtx_rxprbssel[3:0]; // Default to 3'h0
    
    wire [ 3:0] gtx_rxprbserr;
    wire [ 3:0] gtx_txprbsforceerr = 4'h0;
    //----------------------------------------------------------------------------
    assign gtx_loopback [0] = 3'h0;
    assign gtx_txprbssel[0] = 3'h0;
    assign gtx_rxprbssel[0] = 3'h0;
    
    assign gtx_loopback [1] = 3'h0;
    assign gtx_txprbssel[1] = 3'h0;
    assign gtx_rxprbssel[1] = 3'h0;
     
    assign gtx_loopback [2] = 3'h0;
    assign gtx_txprbssel[2] = 3'h0;
    assign gtx_rxprbssel[2] = 3'h0;
    
    assign gtx_loopback [3] = 3'h0;
    assign gtx_txprbssel[3] = 3'h0;
    assign gtx_rxprbssel[3] = 3'h0;

//////////////////////////////////////////////////////////////////////////////////
// Xilinx DRP
//////////////////////////////////////////////////////////////////////////////////
    wire        drpclk = sysclk;
    wire [ 8:0] drpaddr[3:0];
    wire [15:0] drpdi  [3:0];
    wire [15:0] drpdo  [3:0];
    wire [ 3:0] drpen;
    wire [ 3:0] drpwe;
    wire        drprdy [3:0];
    //----------------------------------------------------------------------------
    /*
    assign drpaddr[0] =  9'h0;
    assign drpdi  [0] = 16'h0;
    assign drpen  [0] =  1'h0;
    assign drpwe  [0] =  1'h0;
    
    assign drpaddr[1] =  9'h0;
    assign drpdi  [1] = 16'h0;
    assign drpen  [1] =  1'h0;
    assign drpwe  [1] =  1'h0;
    
    assign drpaddr[2] =  9'h0;
    assign drpdi  [2] = 16'h0;
    assign drpen  [2] =  1'h0;
    assign drpwe  [2] =  1'h0;
    
    assign drpaddr[3] =  9'h0;
    assign drpdi  [3] = 16'h0;
    assign drpen  [3] =  1'h0;
    assign drpwe  [3] =  1'h0;
    */
    
    assign              {drpaddr[3],drpaddr[2],drpaddr[1],drpaddr[0]} = gtx_drpaddr;
    assign              {drpdi  [3],drpdi  [2],drpdi  [1],drpdi  [0]} = gtx_drpdi  ;
    assign              {drpen  [3],drpen  [2],drpen  [1],drpen  [0]} = gtx_drpen  ;
    assign              {drpwe  [3],drpwe  [2],drpwe  [1],drpwe  [0]} = gtx_drpwe  ;
    assign gtx_drpdo  = {drpdo  [3],drpdo  [2],drpdo  [1],drpdo  [0]};
    assign gtx_drprdy = {drprdy [3],drprdy [2],drprdy [1],drprdy [0]};
    
//////////////////////////////////////////////////////////////////////////////////
// GTX Transceiver (COMMON)
//////////////////////////////////////////////////////////////////////////////////
    wire [0:0] gtx_gtrefclk;
    IBUFDS_GTE2 (.O(gtx_gtrefclk[0]), .CEB(1'b0), .I(gtrefclkp[0]), .IB(gtrefclkn[0]));
    //----------------------------------------------------------------------------
    wire       gtx_soft_reset_tx = soft_reset;
    wire       gtx_soft_reset_rx = soft_reset;
    wire       gtx_soft_reset    = soft_reset;
    wire       gtx_sysclk        = sysclk;
    //////////////////////////////////////////////////////////////////////////////
    wire [1:0] qpllreset     ; // QPLL Clock with Reset from GTX Channels
    wire [1:0] qplllock      ;
    wire [1:0] qplloutclk    ;
    wire [1:0] qplloutrefclk ;
    wire [1:0] qpllrefclklost;
    //----------------------------------------------------------------------------
    gtwizard_common #(
        .STABLE_CLOCK_PERIOD(SYSCLK_PERIOD),
        .QPLLREFCLK_SEL(3'b001) // (3'b001 -> GTREFCLK0)
    )
    gtwizard_common_0 (
        .reset_in          (gtx_soft_reset   ),
        .gtrefclk_in       (gtx_gtrefclk  [0]),
        .sysclk_in         (gtx_sysclk       ), // => clock period == stable-clock-period (10ns)
        .qplllock_out      (qplllock      [0]),
        .qplloutclk_out    (qplloutclk    [0]),
        .qplloutrefclk_out (qplloutrefclk [0]),
        .qpllrefclklost_out(qpllrefclklost[0]),
        .qpllreset_in      (qpllreset     [0])
    );
    //----------------------------------------------------------------------------
    gtwizard_common #(
        .STABLE_CLOCK_PERIOD(SYSCLK_PERIOD),
        .QPLLREFCLK_SEL(3'b001)
    )
    gtwizard_common_1 (
        .reset_in          (gtx_soft_reset   ),
        .gtrefclk_in       (gtx_gtrefclk  [0]),
        .sysclk_in         (gtx_sysclk       ), // => clock period == stable-clock-period (10ns)
        .qplllock_out      (qplllock      [1]),
        .qplloutclk_out    (qplloutclk    [1]),
        .qplloutrefclk_out (qplloutrefclk [1]),
        .qpllrefclklost_out(qpllrefclklost[1]),
        .qpllreset_in      (qpllreset     [1])
    );
    
//////////////////////////////////////////////////////////////////////////////////
// TX Driver/RX AFE (Analog Front End) Ports and some useful constants
//////////////////////////////////////////////////////////////////////////////////
    wire [63:0] tied_to_gnd = 64'h0000000000000000;
    wire [63:0] tied_to_vcc = 64'hffffffffffffffff;

//////////////////////////////////////////////////////////////////////////////////
// Transceiver TX/RX User Fabic Clocks
//////////////////////////////////////////////////////////////////////////////////
    wire [ 3:0] gtx_txoutclk, gtx_rxoutclk;
    wire [ 3:0] gtx_txusrclk; //, gtx_txusrclk2;
    wire [ 3:0] gtx_rxusrclk; //, gtx_rxusrclk2;
    wire [ 3:0] gtx_tx_mmcm_reset;
    wire [ 3:0] gtx_tx_mmcm_lock ;
    wire [ 3:0] gtx_rx_mmcm_reset;
    wire [ 3:0] gtx_rx_mmcm_lock ;
    //----------------------------------------------------------------------------
    gtwizard_usrclk gtwizard_usrclk_0 (
        .gtusrclk2_out(gtx_rxusrclk2    [0]),
        .gtusrclk_out (gtx_rxusrclk     [0]),
        .gtoutclk_in  (gtx_rxoutclk     [0]),
        .mmcm_reset_in(gtx_rx_mmcm_reset[0]),
        .mmcm_lock_out(gtx_rx_mmcm_lock [0])
    );
    gtwizard_usrclk gtwizard_usrclk_1 (
        .gtusrclk2_out(gtx_rxusrclk2    [1]),
        .gtusrclk_out (gtx_rxusrclk     [1]),
        .gtoutclk_in  (gtx_rxoutclk     [1]),
        .mmcm_reset_in(gtx_rx_mmcm_reset[1]),
        .mmcm_lock_out(gtx_rx_mmcm_lock [1])
    );
    gtwizard_usrclk gtwizard_usrclk_2 (
        .gtusrclk2_out(gtx_rxusrclk2    [2]),
        .gtusrclk_out (gtx_rxusrclk     [2]),
        .gtoutclk_in  (gtx_rxoutclk     [2]),
        .mmcm_reset_in(gtx_rx_mmcm_reset[2]),
        .mmcm_lock_out(gtx_rx_mmcm_lock [2])
    );
    gtwizard_usrclk gtwizard_usrclk_3 (
        .gtusrclk2_out(gtx_rxusrclk2    [3]),
        .gtusrclk_out (gtx_rxusrclk     [3]),
        .gtoutclk_in  (gtx_rxoutclk     [3]),
        .mmcm_reset_in(gtx_rx_mmcm_reset[3]),
        .mmcm_lock_out(gtx_rx_mmcm_lock [3])
    );
    gtwizard_usrclk #(.N(4)) gtwizard_usrclk_4 (
        .gtusrclk2_out(gtx_txusrclk2       ),
        .gtusrclk_out (gtx_txusrclk        ),
        .gtoutclk_in  (gtx_txoutclk     [0]),
        .mmcm_reset_in(gtx_tx_mmcm_reset   ),
        .mmcm_lock_out(gtx_tx_mmcm_lock    )
    );

//////////////////////////////////////////////////////////////////////////////////
// GTX Transceiver (CHANNELS)
//////////////////////////////////////////////////////////////////////////////////
    wire [ 4:0] gtx_txprecursor  = 5'b00111; // 5'b00111 => 1.67db
    wire [ 6:0] gtx_txmaincursor = 7'b00000;
    wire [ 4:0] gtx_txpostcursor = 5'b00011; // 5'b00011 => 0.68db
    wire [ 3:0] gtx_txdiffctrl   = 4'b1100 ; // 4'b1100  => 1018mV
    wire [ 0:0] gtx_rxlpmen      = 1'b1    ; // 0'b0: DFE, 1'b1: LPM
    //----------------------------------------------------------------------------
    // wire [ 3:0] gtx_txreset_done, gtx_rxreset_done; // TX/RX Ready Signals, connected to MAC Layer
    wire [ 3:0] gtx_gttxreset = gtx_txreset;
    wire [ 3:0] gtx_gtrxreset = gtx_rxreset;
    //----------------------------------------------------------------------------
    // TX Gearbox
    reg  [ 6:0] gtx_txsequence   [3:0];
    wire [ 1:0] gtx_txheader     [3:0];
    wire [ 0:0] gtx_datavalid    [3:0];
    wire [63:0] gtx_txdata       [3:0];
    // RX Gearbox
    wire [ 0:0] gtx_rxgearboxslip[3:0];
    wire [ 0:0] gtx_rxheadervalid[3:0];
    wire [ 1:0] gtx_rxheader     [3:0];
    wire [ 0:0] gtx_rxdatavalid  [3:0];
    wire [63:0] gtx_rxdata       [3:0];
    //----------------------------------------------------------------------------
    assign gtx_datavalid[0] = !gtx_txprbssel[0];
    assign gtx_datavalid[1] = !gtx_txprbssel[1];
    assign gtx_datavalid[2] = !gtx_txprbssel[2];
    assign gtx_datavalid[3] = !gtx_txprbssel[3];
    //----------------------------------------------------------------------------
    gtwizard_0 gtwizard_0 (
        .sysclk_in                  (gtx_sysclk           ),
        .soft_reset_tx_in           (gtx_soft_reset_tx    ),
        .soft_reset_rx_in           (gtx_soft_reset_rx    ),
        .dont_reset_on_data_error_in(tied_to_gnd          ),
        .gt0_tx_fsm_reset_done_out  (                     ),
        .gt0_rx_fsm_reset_done_out  (                     ),
        .gt0_data_valid_in          (gtx_datavalid     [0]),
        .gt0_tx_mmcm_lock_in        (gtx_tx_mmcm_lock  [0]),
        .gt0_tx_mmcm_reset_out      (gtx_tx_mmcm_reset [0]),
        .gt0_rx_mmcm_lock_in        (gtx_rx_mmcm_lock  [0]),
        .gt0_rx_mmcm_reset_out      (gtx_rx_mmcm_reset [0]),
        .gt1_tx_fsm_reset_done_out  (                     ),
        .gt1_rx_fsm_reset_done_out  (                     ),
        .gt1_data_valid_in          (gtx_datavalid     [1]),
        .gt1_tx_mmcm_lock_in        (gtx_tx_mmcm_lock  [1]),
        .gt1_tx_mmcm_reset_out      (gtx_tx_mmcm_reset [1]),
        .gt1_rx_mmcm_lock_in        (gtx_rx_mmcm_lock  [1]),
        .gt1_rx_mmcm_reset_out      (gtx_rx_mmcm_reset [1]),
        .gt2_tx_fsm_reset_done_out  (                     ),
        .gt2_rx_fsm_reset_done_out  (                     ),
        .gt2_data_valid_in          (gtx_datavalid     [2]),
        .gt2_tx_mmcm_lock_in        (gtx_tx_mmcm_lock  [2]),
        .gt2_tx_mmcm_reset_out      (gtx_tx_mmcm_reset [2]),
        .gt2_rx_mmcm_lock_in        (gtx_rx_mmcm_lock  [2]),
        .gt2_rx_mmcm_reset_out      (gtx_rx_mmcm_reset [2]),
        .gt3_tx_fsm_reset_done_out  (                     ),
        .gt3_rx_fsm_reset_done_out  (                     ),
        .gt3_data_valid_in          (gtx_datavalid     [3]),
        .gt3_tx_mmcm_lock_in        (gtx_tx_mmcm_lock  [3]),
        .gt3_tx_mmcm_reset_out      (gtx_tx_mmcm_reset [3]),
        .gt3_rx_mmcm_lock_in        (gtx_rx_mmcm_lock  [3]),
        .gt3_rx_mmcm_reset_out      (gtx_rx_mmcm_reset [3]),
        // CHANNEL-0
        .gt0_gtnorthrefclk0_in      (tied_to_gnd          ), // Clocking Ports
        .gt0_gtnorthrefclk1_in      (tied_to_gnd          ), // -
        .gt0_gtsouthrefclk0_in      (tied_to_gnd          ), // -
        .gt0_gtsouthrefclk1_in      (tied_to_gnd          ), // -
        .gt0_drpaddr_in             (drpaddr           [0]), // DRP Ports
        .gt0_drpclk_in              (drpclk               ), // -
        .gt0_drpdi_in               (drpdi             [0]), // -
        .gt0_drpdo_out              (drpdo             [0]), // -
        .gt0_drpen_in               (drpen             [0]), // -
        .gt0_drprdy_out             (drprdy            [0]), // -
        .gt0_drpwe_in               (drpwe             [0]), // -
        .gt0_dmonitorout_out        (                     ), // Digital Monitor
        .gt0_loopback_in            (gtx_loopback      [0]), // Loopback (3'b000: Normal operation)
        .gt0_rxrate_in              (3'b000               ), // RX Serial Clock Divider
        .gt0_eyescanreset_in        (tied_to_gnd          ),
        .gt0_rxuserrdy_in           (tied_to_vcc          ),
        .gt0_eyescandataerror_out   (                     ), // RX Margin Analysis
        .gt0_eyescantrigger_in      (tied_to_gnd          ), // -
        .gt0_rxcdrhold_in           (tied_to_gnd          ), // RX CDR
        .gt0_rxusrclk_in            (gtx_rxusrclk      [0]),
        .gt0_rxusrclk2_in           (gtx_rxusrclk2     [0]),
        .gt0_rxdata_out             (gtx_rxdata        [0]),
        .gt0_rxprbserr_out          (gtx_rxprbserr     [0]), // RX Pattern Checker
        .gt0_rxprbssel_in           (gtx_rxprbssel     [0]), // - (3'b000: Standard operation mode)
        .gt0_rxprbscntreset_in      (tied_to_gnd          ), // -
        .gt0_gtxrxp_in              (gtx_rxp           [0]), // RX AFE
        .gt0_gtxrxn_in              (gtx_rxn           [0]), // -
        .gt0_rxbufreset_in          (tied_to_gnd          ), // RX Buffer Bypass
        .gt0_rxbufstatus_out        (                     ), // -
        .gt0_rxdfelpmreset_in       (tied_to_gnd          ), // RX Equalizer
        .gt0_rxmonitorout_out       (                     ), // -
        .gt0_rxmonitorsel_in        (2'b00                ), // - (2'b00: Reserved)
        .gt0_rxratedone_out         (                     ), // -
        .gt0_rxoutclk_out           (gtx_rxoutclk      [0]), // RX Fabric ClocK
        .gt0_rxoutclkfabric_out     (                     ), // -
        .gt0_rxdatavalid_out        (gtx_rxdatavalid   [0]), // RX Gearbox
        .gt0_rxheader_out           (gtx_rxheader      [0]), // -
        .gt0_rxheadervalid_out      (gtx_rxheadervalid [0]), // -
        .gt0_rxgearboxslip_in       (gtx_rxgearboxslip [0]), // -
        .gt0_gtrxreset_in           (gtx_gtrxreset     [0]),
        .gt0_rxpcsreset_in          (tied_to_gnd          ),
        .gt0_rxpmareset_in          (tied_to_gnd          ),
        .gt0_rxlpmen_in             (gtx_rxlpmen          ), // RX Margin Analysis (1'b0: DFE, 1'b1: LPM)
        .gt0_rxpolarity_in          (tied_to_gnd          ), // RX Polarity Control
        .gt0_rxresetdone_out        (gtx_rxreset_done  [0]), // RX Init and Reset
        .gt0_txpostcursor_in        (gtx_txpostcursor     ), // TX Configurable Driver (5'b0 ~ 5'b11111, 0db ~ 6.02db)
        .gt0_txprecursor_in         (gtx_txprecursor      ), // - (5'b0 ~ 5'b11111, 0db ~ 12.96db)
        .gt0_gttxreset_in           (gtx_gttxreset     [0]),
        .gt0_txuserrdy_in           (tied_to_vcc          ),
        .gt0_txusrclk_in            (gtx_txusrclk      [0]),
        .gt0_txusrclk2_in           (gtx_txusrclk2     [0]),
        .gt0_txprbsforceerr_in      (gtx_txprbsforceerr[0]), // Pattern Generator
        .gt0_txbufstatus_out        (                     ), // TX Buffer
        .gt0_txdiffctrl_in          (gtx_txdiffctrl       ), // TX Configurable Driver (4'b0 ~ 4'b1111, 0.269V ~ 1.119V)
        .gt0_txinhibit_in           (tied_to_gnd          ), // -
        .gt0_txmaincursor_in        (gtx_txmaincursor     ), // -
        .gt0_txdata_in              (gtx_txdata        [0]),
        .gt0_gtxtxn_out             (gtx_txn           [0]), // TX Driver
        .gt0_gtxtxp_out             (gtx_txp           [0]), // -
        .gt0_txoutclk_out           (gtx_txoutclk      [0]), // TX Fabric Clock
        .gt0_txoutclkfabric_out     (                     ), // -
        .gt0_txoutclkpcs_out        (                     ), // -
        .gt0_txheader_in            (gtx_txheader      [0]), // TX Gearbox
        .gt0_txsequence_in          (gtx_txsequence    [0]), // -
        .gt0_txpcsreset_in          (tied_to_gnd          ),
        .gt0_txpmareset_in          (tied_to_gnd          ),
        .gt0_txresetdone_out        (gtx_txreset_done  [0]),
        .gt0_txpolarity_in          (tied_to_gnd          ), // TX Polarity
        .gt0_txprbssel_in           (gtx_txprbssel     [0]), // TX Pattern Generator (3'b000: Standard operation mode)
        // CHANNEL-1
        .gt1_gtnorthrefclk0_in      (tied_to_gnd          ), // Clocking Ports
        .gt1_gtnorthrefclk1_in      (tied_to_gnd          ), // -
        .gt1_gtsouthrefclk0_in      (tied_to_gnd          ), // -
        .gt1_gtsouthrefclk1_in      (tied_to_gnd          ), // -
        .gt1_drpaddr_in             (drpaddr           [1]), // DRP Ports
        .gt1_drpclk_in              (drpclk               ), // -
        .gt1_drpdi_in               (drpdi             [1]), // -
        .gt1_drpdo_out              (drpdo             [1]), // -
        .gt1_drpen_in               (drpen             [1]), // -
        .gt1_drprdy_out             (drprdy            [1]), // -
        .gt1_drpwe_in               (drpwe             [1]), // -
        .gt1_dmonitorout_out        (                     ), // Digital Monitor
        .gt1_loopback_in            (gtx_loopback      [1]), // Loopback (3'b000: Normal operation)
        .gt1_rxrate_in              (3'b000               ), // RX Serial Clock Divider
        .gt1_eyescanreset_in        (tied_to_gnd          ),
        .gt1_rxuserrdy_in           (tied_to_vcc          ),
        .gt1_eyescandataerror_out   (                     ), // RX Margin Analysis
        .gt1_eyescantrigger_in      (tied_to_gnd          ), // -
        .gt1_rxcdrhold_in           (tied_to_gnd          ), // RX CDR
        .gt1_rxusrclk_in            (gtx_rxusrclk      [1]),
        .gt1_rxusrclk2_in           (gtx_rxusrclk2     [1]),
        .gt1_rxdata_out             (gtx_rxdata        [1]),
        .gt1_rxprbserr_out          (gtx_rxprbserr     [1]), // RX Pattern Checker
        .gt1_rxprbssel_in           (gtx_rxprbssel     [1]), // - (3'b000: Standard operation mode)
        .gt1_rxprbscntreset_in      (tied_to_gnd          ), // -
        .gt1_gtxrxp_in              (gtx_rxp           [1]), // RX AFE
        .gt1_gtxrxn_in              (gtx_rxn           [1]), // -
        .gt1_rxbufreset_in          (tied_to_gnd          ), // RX Buffer Bypass
        .gt1_rxbufstatus_out        (                     ), // -
        .gt1_rxdfelpmreset_in       (tied_to_gnd          ), // RX Equalizer
        .gt1_rxmonitorout_out       (                     ), // -
        .gt1_rxmonitorsel_in        (2'b00                ), // - (2'b00: Reserved)
        .gt1_rxratedone_out         (                     ), // -
        .gt1_rxoutclk_out           (gtx_rxoutclk      [1]), // RX Fabric ClocK
        .gt1_rxoutclkfabric_out     (                     ), // -
        .gt1_rxdatavalid_out        (gtx_rxdatavalid   [1]), // RX Gearbox
        .gt1_rxheader_out           (gtx_rxheader      [1]), // -
        .gt1_rxheadervalid_out      (gtx_rxheadervalid [1]), // -
        .gt1_rxgearboxslip_in       (gtx_rxgearboxslip [1]), // -
        .gt1_gtrxreset_in           (gtx_gtrxreset     [1]),
        .gt1_rxpcsreset_in          (tied_to_gnd          ),
        .gt1_rxpmareset_in          (tied_to_gnd          ),
        .gt1_rxlpmen_in             (gtx_rxlpmen          ), // RX Margin Analysis (1'b0: DFE, 1'b1: LPM)
        .gt1_rxpolarity_in          (tied_to_gnd          ), // RX Polarity Control
        .gt1_rxresetdone_out        (gtx_rxreset_done  [1]), // RX Init and Reset
        .gt1_txpostcursor_in        (gtx_txpostcursor     ), // TX Configurable Driver (5'b0 ~ 5'b11111/0db ~ 6.02db)
        .gt1_txprecursor_in         (gtx_txprecursor      ), // - (5'b0 ~ 5'b11111/0db ~ 12.96db)
        .gt1_gttxreset_in           (gtx_gttxreset     [1]),
        .gt1_txuserrdy_in           (tied_to_vcc          ),
        .gt1_txusrclk_in            (gtx_txusrclk      [1]),
        .gt1_txusrclk2_in           (gtx_txusrclk2     [1]),
        .gt1_txprbsforceerr_in      (gtx_txprbsforceerr[1]), // Pattern Generator
        .gt1_txbufstatus_out        (                     ), // TX Buffer
        .gt1_txdiffctrl_in          (gtx_txdiffctrl       ), // TX Configurable Driver (4'b0 ~ 4'b1111, 0.269V ~ 1.119V)
        .gt1_txinhibit_in           (tied_to_gnd          ), // -
        .gt1_txmaincursor_in        (gtx_txmaincursor     ), // -
        .gt1_txdata_in              (gtx_txdata        [1]),
        .gt1_gtxtxn_out             (gtx_txn           [1]), // TX Driver
        .gt1_gtxtxp_out             (gtx_txp           [1]), // -
        .gt1_txoutclk_out           (gtx_txoutclk      [1]), // TX Fabric Clock
        .gt1_txoutclkfabric_out     (                     ), // -
        .gt1_txoutclkpcs_out        (                     ), // -
        .gt1_txheader_in            (gtx_txheader      [1]), // TX Gearbox
        .gt1_txsequence_in          (gtx_txsequence    [1]), // -
        .gt1_txpcsreset_in          (tied_to_gnd          ),
        .gt1_txpmareset_in          (tied_to_gnd          ),
        .gt1_txresetdone_out        (gtx_txreset_done  [1]),
        .gt1_txpolarity_in          (tied_to_gnd          ), // TX Polarity
        .gt1_txprbssel_in           (gtx_txprbssel     [1]), // TX Pattern Generator (3'b000: Standard operation mode)
        // CHANNEL-2
        .gt2_gtnorthrefclk0_in      (tied_to_gnd          ), // Clocking Ports
        .gt2_gtnorthrefclk1_in      (tied_to_gnd          ), // -
        .gt2_gtsouthrefclk0_in      (tied_to_gnd          ), // -
        .gt2_gtsouthrefclk1_in      (tied_to_gnd          ), // -
        .gt2_drpaddr_in             (drpaddr           [2]), // DRP Ports
        .gt2_drpclk_in              (drpclk               ), // -
        .gt2_drpdi_in               (drpdi             [2]), // -
        .gt2_drpdo_out              (drpdo             [2]), // -
        .gt2_drpen_in               (drpen             [2]), // -
        .gt2_drprdy_out             (drprdy            [2]), // -
        .gt2_drpwe_in               (drpwe             [2]), // -
        .gt2_dmonitorout_out        (                     ), // Digital Monitor
        .gt2_loopback_in            (gtx_loopback      [2]), // Loopback (3'b000: Normal operation)
        .gt2_rxrate_in              (3'b000               ), // RX Serial Clock Divider
        .gt2_eyescanreset_in        (tied_to_gnd          ),
        .gt2_rxuserrdy_in           (tied_to_vcc          ),
        .gt2_eyescandataerror_out   (                     ), // RX Margin Analysis
        .gt2_eyescantrigger_in      (tied_to_gnd          ), // -
        .gt2_rxcdrhold_in           (tied_to_gnd          ), // RX CDR
        .gt2_rxusrclk_in            (gtx_rxusrclk      [2]),
        .gt2_rxusrclk2_in           (gtx_rxusrclk2     [2]),
        .gt2_rxdata_out             (gtx_rxdata        [2]),
        .gt2_rxprbserr_out          (gtx_rxprbserr     [2]), // RX Pattern Checker
        .gt2_rxprbssel_in           (gtx_rxprbssel     [2]), // - (3'b000: Standard operation mode)
        .gt2_rxprbscntreset_in      (tied_to_gnd          ), // -
        .gt2_gtxrxp_in              (gtx_rxp           [2]), // RX AFE
        .gt2_gtxrxn_in              (gtx_rxn           [2]), // -
        .gt2_rxbufreset_in          (tied_to_gnd          ), // RX Buffer Bypass
        .gt2_rxbufstatus_out        (                     ), // -
        .gt2_rxdfelpmreset_in       (tied_to_gnd          ), // RX Equalizer
        .gt2_rxmonitorout_out       (                     ), // -
        .gt2_rxmonitorsel_in        (2'b00                ), // - (2'b00: Reserved)
        .gt2_rxratedone_out         (                     ), // -
        .gt2_rxoutclk_out           (gtx_rxoutclk      [2]), // RX Fabric ClocK
        .gt2_rxoutclkfabric_out     (                     ), // -
        .gt2_rxdatavalid_out        (gtx_rxdatavalid   [2]), // RX Gearbox
        .gt2_rxheader_out           (gtx_rxheader      [2]), // -
        .gt2_rxheadervalid_out      (gtx_rxheadervalid [2]), // -
        .gt2_rxgearboxslip_in       (gtx_rxgearboxslip [2]), // -
        .gt2_gtrxreset_in           (gtx_gtrxreset     [2]),
        .gt2_rxpcsreset_in          (tied_to_gnd          ),
        .gt2_rxpmareset_in          (tied_to_gnd          ),
        .gt2_rxlpmen_in             (gtx_rxlpmen          ), // RX Margin Analysis (1'b0: DFE, 1'b1: LPM)
        .gt2_rxpolarity_in          (tied_to_gnd          ), // RX Polarity Control
        .gt2_rxresetdone_out        (gtx_rxreset_done  [2]), // RX Init and Reset
        .gt2_txpostcursor_in        (gtx_txpostcursor     ), // TX Configurable Driver (5'b0 ~ 5'b11111/0db ~ 6.02db)
        .gt2_txprecursor_in         (gtx_txprecursor      ), // - (5'b0 ~ 5'b11111/0db ~ 12.96db)
        .gt2_gttxreset_in           (gtx_gttxreset     [2]),
        .gt2_txuserrdy_in           (tied_to_vcc          ),
        .gt2_txusrclk_in            (gtx_txusrclk      [2]),
        .gt2_txusrclk2_in           (gtx_txusrclk2     [2]),
        .gt2_txprbsforceerr_in      (gtx_txprbsforceerr[2]), // Pattern Generator
        .gt2_txbufstatus_out        (                     ), // TX Buffer
        .gt2_txdiffctrl_in          (gtx_txdiffctrl       ), // TX Configurable Driver (4'b0 ~ 4'b1111, 0.269V ~ 1.119V)
        .gt2_txinhibit_in           (tied_to_gnd          ), // -
        .gt2_txmaincursor_in        (gtx_txmaincursor     ), // -
        .gt2_txdata_in              (gtx_txdata        [2]),
        .gt2_gtxtxn_out             (gtx_txn           [2]), // TX Driver
        .gt2_gtxtxp_out             (gtx_txp           [2]), // -
        .gt2_txoutclk_out           (gtx_txoutclk      [2]), // TX Fabric Clock
        .gt2_txoutclkfabric_out     (                     ), // -
        .gt2_txoutclkpcs_out        (                     ), // -
        .gt2_txheader_in            (gtx_txheader      [2]), // TX Gearbox
        .gt2_txsequence_in          (gtx_txsequence    [2]), // -
        .gt2_txpcsreset_in          (tied_to_gnd          ),
        .gt2_txpmareset_in          (tied_to_gnd          ),
        .gt2_txresetdone_out        (gtx_txreset_done  [2]),
        .gt2_txpolarity_in          (tied_to_gnd          ), // TX Polarity
        .gt2_txprbssel_in           (gtx_txprbssel     [2]), // TX Pattern Generator (3'b000: Standard operation mode)
        // CHANNEL-3
        .gt3_gtnorthrefclk0_in      (tied_to_gnd          ), // Clocking Ports
        .gt3_gtnorthrefclk1_in      (tied_to_gnd          ), // -
        .gt3_gtsouthrefclk0_in      (tied_to_gnd          ), // -
        .gt3_gtsouthrefclk1_in      (tied_to_gnd          ), // -
        .gt3_drpaddr_in             (drpaddr           [3]), // DRP Ports
        .gt3_drpclk_in              (drpclk               ), // -
        .gt3_drpdi_in               (drpdi             [3]), // -
        .gt3_drpdo_out              (drpdo             [3]), // -
        .gt3_drpen_in               (drpen             [3]), // -
        .gt3_drprdy_out             (drprdy            [3]), // -
        .gt3_drpwe_in               (drpwe             [3]), // -
        .gt3_dmonitorout_out        (                     ), // Digital Monitor
        .gt3_loopback_in            (gtx_loopback      [3]), // Loopback (3'b000: Normal operation)
        .gt3_rxrate_in              (3'b000               ), // RX Serial Clock Divider
        .gt3_eyescanreset_in        (tied_to_gnd          ),
        .gt3_rxuserrdy_in           (tied_to_vcc          ),
        .gt3_eyescandataerror_out   (                     ), // RX Margin Analysis
        .gt3_eyescantrigger_in      (tied_to_gnd          ), // -
        .gt3_rxcdrhold_in           (tied_to_gnd          ), // RX CDR
        .gt3_rxusrclk_in            (gtx_rxusrclk      [3]),
        .gt3_rxusrclk2_in           (gtx_rxusrclk2     [3]),
        .gt3_rxdata_out             (gtx_rxdata        [3]),
        .gt3_rxprbserr_out          (gtx_rxprbserr     [3]), // RX Pattern Checker
        .gt3_rxprbssel_in           (gtx_rxprbssel     [3]), // - (3'b000: Standard operation mode)
        .gt3_rxprbscntreset_in      (tied_to_gnd          ), // -
        .gt3_gtxrxp_in              (gtx_rxp           [3]), // RX AFE
        .gt3_gtxrxn_in              (gtx_rxn           [3]), // -
        .gt3_rxbufreset_in          (tied_to_gnd          ), // RX Buffer Bypass
        .gt3_rxbufstatus_out        (                     ), // -
        .gt3_rxdfelpmreset_in       (tied_to_gnd          ), // RX Equalizer
        .gt3_rxmonitorout_out       (                     ), // -
        .gt3_rxmonitorsel_in        (2'b00                ), // - (2'b00: Reserved)
        .gt3_rxratedone_out         (                     ), // -
        .gt3_rxoutclk_out           (gtx_rxoutclk      [3]), // RX Fabric ClocK
        .gt3_rxoutclkfabric_out     (                     ), // -
        .gt3_rxdatavalid_out        (gtx_rxdatavalid   [3]), // RX Gearbox
        .gt3_rxheader_out           (gtx_rxheader      [3]), // -
        .gt3_rxheadervalid_out      (gtx_rxheadervalid [3]), // -
        .gt3_rxgearboxslip_in       (gtx_rxgearboxslip [3]), // -
        .gt3_gtrxreset_in           (gtx_gtrxreset     [3]),
        .gt3_rxpcsreset_in          (tied_to_gnd          ),
        .gt3_rxpmareset_in          (tied_to_gnd          ),
        .gt3_rxlpmen_in             (gtx_rxlpmen          ), // RX Margin Analysis (1'b0: DFE, 1'b1: LPM)
        .gt3_rxpolarity_in          (tied_to_gnd          ), // RX Polarity Control
        .gt3_rxresetdone_out        (gtx_rxreset_done  [3]), // RX Init and Reset
        .gt3_txpostcursor_in        (gtx_txpostcursor     ), // TX Configurable Driver (5'b0 ~ 5'b11111/0db ~ 6.02db)
        .gt3_txprecursor_in         (gtx_txprecursor      ), // - (5'b0 ~ 5'b11111/0db ~ 12.96db)
        .gt3_gttxreset_in           (gtx_gttxreset     [3]),
        .gt3_txuserrdy_in           (tied_to_vcc          ),
        .gt3_txusrclk_in            (gtx_txusrclk      [3]),
        .gt3_txusrclk2_in           (gtx_txusrclk2     [3]),
        .gt3_txprbsforceerr_in      (gtx_txprbsforceerr[3]), // Pattern Generator
        .gt3_txbufstatus_out        (                     ), // TX Buffer
        .gt3_txdiffctrl_in          (gtx_txdiffctrl       ), // TX Configurable Driver (4'b0 ~ 4'b1111, 0.269V ~ 1.119V)
        .gt3_txinhibit_in           (tied_to_gnd          ), // -
        .gt3_txmaincursor_in        (gtx_txmaincursor     ), // -
        .gt3_txdata_in              (gtx_txdata        [3]),
        .gt3_gtxtxn_out             (gtx_txn           [3]), // TX Driver
        .gt3_gtxtxp_out             (gtx_txp           [3]), // -
        .gt3_txoutclk_out           (gtx_txoutclk      [3]), // TX Fabric Clock
        .gt3_txoutclkfabric_out     (                     ), // -
        .gt3_txoutclkpcs_out        (                     ), // -
        .gt3_txheader_in            (gtx_txheader      [3]), // TX Gearbox
        .gt3_txsequence_in          (gtx_txsequence    [3]), // -
        .gt3_txpcsreset_in          (tied_to_gnd          ),
        .gt3_txpmareset_in          (tied_to_gnd          ),
        .gt3_txresetdone_out        (gtx_txreset_done  [3]),
        .gt3_txpolarity_in          (tied_to_gnd          ), // TX Polarity
        .gt3_txprbssel_in           (gtx_txprbssel     [3]), // TX Pattern Generator (3'b000: Standard operation mode)
        
        // COMMON PORTS
        .gt0_qplllock_in            (qplllock          [0]),
        .gt0_qpllrefclklost_in      (qpllrefclklost    [0]),
        .gt0_qpllreset_out          (qpllreset         [0]),
        .gt0_qplloutclk_in          (qplloutclk        [0]),
        .gt0_qplloutrefclk_in       (qplloutrefclk     [0]),
        
        .gt1_qplllock_in            (qplllock          [1]),
        .gt1_qpllrefclklost_in      (qpllrefclklost    [1]),
        .gt1_qpllreset_out          (qpllreset         [1]),
        .gt1_qplloutclk_in          (qplloutclk        [1]),
        .gt1_qplloutrefclk_in       (qplloutrefclk     [1])
    );

//////////////////////////////////////////////////////////////////////////////////
// Modified Tx/Rx Clock & Data
//////////////////////////////////////////////////////////////////////////////////
    genvar n1;
    generate
    for (n1 = 0; n1 < 4; n1 = n1 + 1) begin
    always @(posedge gtx_txusrclk2[n1]) begin
        if (gtx_txreset_done[n1] && gtx_txsequence[n1] != 7'd32) begin
            gtx_txsequence[n1] <= gtx_txsequence[n1] + 1'b1;
        end else begin
            gtx_txsequence[n1] <= 7'd0;
        end
    end
    end
    endgenerate
    
//////////////////////////////////////////////////////////////////////////////////
    assign txsequence = {gtx_txsequence[3],gtx_txsequence[2],gtx_txsequence[1],gtx_txsequence[0]};
    
    assign {gtx_txheader[3],gtx_txheader[2],gtx_txheader[1],gtx_txheader[0]} = txheader;
    assign {gtx_txdata  [3],gtx_txdata  [2],gtx_txdata  [1],gtx_txdata  [0]} = txdata  ;
    
    //-------------------------------------------------------------------------
    assign {gtx_rxgearboxslip[3],gtx_rxgearboxslip[2],gtx_rxgearboxslip[1],gtx_rxgearboxslip[0]} = rxgearboxslip;
    
    assign rxheadervalid = {gtx_rxheadervalid[3],gtx_rxheadervalid[2],gtx_rxheadervalid[1],gtx_rxheadervalid[0]};
    assign rxheader      = {gtx_rxheader     [3],gtx_rxheader     [2],gtx_rxheader     [1],gtx_rxheader     [0]};
    assign rxdatavalid   = {gtx_rxdatavalid  [3],gtx_rxdatavalid  [2],gtx_rxdatavalid  [1],gtx_rxdatavalid  [0]};
    assign rxdata        = {gtx_rxdata       [3],gtx_rxdata       [2],gtx_rxdata       [1],gtx_rxdata       [0]};
    
//////////////////////////////////////////////////////////////////////////////////

endmodule
