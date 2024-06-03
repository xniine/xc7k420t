`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2022 11:25:05 AM
// Design Name: 
// Module Name: gtx_adapter
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


module mac_adapter #(
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    
    parameter CLOCK_STYLE = "BUFMR",
    parameter TX_FIFO_DEPTH = 4096,
    parameter TX_FRAME_FIFO = 1,
    parameter RX_FIFO_DEPTH = 4096,
    parameter RX_FRAME_FIFO = 0
    ) (
    input  wire        gtx_txreset_done ,
    input  wire        gtx_rxreset_done ,
    input  wire        gtx_txusrclk2    ,
    input  wire        gtx_rxusrclk2    ,
    input  wire        clk              ,
    input  wire        rst              ,
    // PRBS & Block Lock
    input  wire        tx_prbs31_enable ,
    input  wire        rx_prbs31_enable ,
    output wire [ 6:0] rx_error_count   , 
    output wire        rx_block_lock    ,
    // TX Flow Control
    input  wire [15:0] tx_axis_credit   ,
    input  wire [15:0] tx_axis_window   ,
    input  wire [15:0] tx_axis_adjust   ,
    input  wire [15:0] tx_axis_punish   ,
    // Gearbox
    input  wire [ 6:0] gtx_txsequence   ,
    output wire [ 1:0] gtx_txheader     ,
    output wire [63:0] gtx_txdata       ,
    input  wire        gtx_rxheadervalid,
    input  wire        gtx_rxdatavalid  ,
    input  wire [ 1:0] gtx_rxheader     ,
    input  wire [63:0] gtx_rxdata       ,
    output wire        gtx_rxgearboxslip,
    // AXI-S Tx
    input  wire [AXIS_DATA_WIDTH-1:0] tx_axis_tdata ,
    input  wire [AXIS_KEEP_WIDTH-1:0] tx_axis_tkeep ,
    input  wire                       tx_axis_tvalid,
    output wire                       tx_axis_tready,
    input  wire                       tx_axis_tlast ,
    input  wire                       tx_axis_tuser ,
    // AXI-S Rx
    output wire [AXIS_DATA_WIDTH-1:0] rx_axis_tdata ,
    output wire [AXIS_KEEP_WIDTH-1:0] rx_axis_tkeep ,
    output wire                       rx_axis_tvalid,
    input  wire                       rx_axis_tready,
    output wire                       rx_axis_tlast ,
    output wire                       rx_axis_tuser
    );
    
    // XGMII
    wire [63:0] gtx_txd;
    wire [ 7:0] gtx_txc;
    wire [63:0] gtx_rxd;
    wire [ 7:0] gtx_rxc;
    
    //=========================================================================
    // Clock and Reset
    //=========================================================================
    reg  gtx_txusrclk2_ce; // Walkaround for txsequence handling
    always @(negedge gtx_txusrclk2) begin
        if (rst) begin
            gtx_txusrclk2_ce <= 1'b0;
        end else
        if (gtx_txreset_done && gtx_txsequence != 7'd31) begin
            gtx_txusrclk2_ce <= 1'b1;
        end else begin
            gtx_txusrclk2_ce <= 1'b0;
        end
    end
    //-------------------------------------------------------------------------
    reg       gtx_rxusrclk2_ce;
    reg [7:0] gtx_rxsequence;
    always @(negedge gtx_rxusrclk2) begin
        if (rst) begin
            gtx_rxsequence <= 7'h0;
        end else
        if (gtx_rxreset_done && gtx_rxheadervalid && gtx_rxdatavalid) begin
            gtx_rxsequence <= gtx_rxsequence + 1'h1;
        end else begin
            gtx_rxsequence <= 7'h0;
        end
    end
    always @(negedge gtx_rxusrclk2) begin
        if (rst) begin
            gtx_rxusrclk2_ce <= 1'b0;
        end else
        if (gtx_rxreset_done && gtx_rxsequence != 7'd32) begin
            gtx_rxusrclk2_ce <= 1'b1;
        end else begin
            gtx_rxusrclk2_ce <= 1'b0;
        end
    end
    
    //-------------------------------------------------------------------------
    wire gtx_tx_clk;
    wire gtx_rx_clk;
    
    if (CLOCK_STYLE == "BUFG") begin
        BUFGCE bufgce_0 (.I(gtx_txusrclk2), .O(gtx_tx_clk), .CE(gtx_txusrclk2_ce));
        BUFGCE bufgce_1 (.I(gtx_rxusrclk2), .O(gtx_rx_clk), .CE(gtx_rxusrclk2_ce));
    end else
    if (CLOCK_STYLE == "BUMR") begin
        BUFMRCE bufmrce_0 (.I(gtx_txusrclk2), .O(gtx_tx_clk), .CE(gtx_txusrclk2_ce));
        BUFMRCE bufmrce_1 (.I(gtx_rxusrclk2), .O(gtx_rx_clk), .CE(gtx_rxusrclk2_ce));
    end else
    if (CLOCK_STYLE == "BUFH") begin
        BUFHCE bufhce_0 (.I(gtx_txusrclk2), .O(gtx_tx_clk), .CE(gtx_txusrclk2_ce));
        BUFHCE bufhce_1 (.I(gtx_rxusrclk2), .O(gtx_rx_clk), .CE(gtx_rxusrclk2_ce));
    end else begin // CLOCK_STYLE == "NONE"
        assign gtx_tx_clk = gtx_txusrclk2_ce & gtx_txusrclk2;
        assign gtx_rx_clk = gtx_rxusrclk2_ce & gtx_rxusrclk2;
    end
    
    //-------------------------------------------------------------------------
    wire gtx_tx_rst = !gtx_txreset_done;
    wire gtx_rx_rst = !gtx_rxreset_done;
    
    //=========================================================================
    // Ethernet PHY
    //=========================================================================
    eth_phy_10g #(
        .SLIP_COUNT_WIDTH(5),
        .PRBS31_ENABLE(1),
        .BIT_REVERSE(1)
    )
    eth_phy_10g_inst (
        .tx_clk           (gtx_tx_clk       ),
        .tx_rst           (gtx_tx_rst       ),
        .rx_clk           (gtx_rx_clk       ),
        .rx_rst           (gtx_rx_rst       ),
        .xgmii_txd        (gtx_txd          ),
        .xgmii_txc        (gtx_txc          ),
        .xgmii_rxd        (gtx_rxd          ),
        .xgmii_rxc        (gtx_rxc          ),
        .serdes_tx_data   (gtx_txdata       ),
        .serdes_tx_hdr    (gtx_txheader     ),
        .serdes_rx_data   (gtx_rxdata       ),
        .serdes_rx_hdr    (gtx_rxheader     ),
        .serdes_rx_bitslip(gtx_rxgearboxslip),
        .rx_block_lock    (rx_block_lock    ),
        .rx_high_ber      (                 ),
        .tx_prbs31_enable (tx_prbs31_enable ),
        .rx_prbs31_enable (rx_prbs31_enable ),
        .rx_error_count   (rx_error_count   )
    );

    //=========================================================================
    // Ethernet MAC
    //=========================================================================
    eth_mac_10g_fifo #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .ENABLE_PADDING(1),
        .ENABLE_DIC(1),
        .MIN_FRAME_LENGTH(64),
        .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
        .TX_FRAME_FIFO(TX_FRAME_FIFO),
        .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
        .RX_FRAME_FIFO(RX_FRAME_FIFO)
    )
    eth_mac_10g_fifo_inst (
        .tx_clk            (gtx_tx_clk    ),
        .tx_rst            (gtx_tx_rst    ),
        .rx_clk            (gtx_rx_clk    ),
        .rx_rst            (gtx_rx_rst    ),
        .logic_clk         (clk           ),
        .logic_rst         (rst           ),
        // Tx Flow Control
        .tx_axis_window    (tx_axis_window),
        .tx_axis_credit    (tx_axis_credit),
        .tx_axis_adjust    (tx_axis_adjust),
        .tx_axis_punish    (tx_axis_punish),
        // AXI output
        .tx_axis_tdata     (tx_axis_tdata ),
        .tx_axis_tkeep     (tx_axis_tkeep ),
        .tx_axis_tvalid    (tx_axis_tvalid),
        .tx_axis_tready    (tx_axis_tready),
        .tx_axis_tlast     (tx_axis_tlast ),
        .tx_axis_tuser     (tx_axis_tuser ),
        // AXI input
        .rx_axis_tdata     (rx_axis_tdata ),
        .rx_axis_tkeep     (rx_axis_tkeep ),
        .rx_axis_tvalid    (rx_axis_tvalid),
        .rx_axis_tready    (rx_axis_tready),
        .rx_axis_tlast     (rx_axis_tlast ),
        .rx_axis_tuser     (rx_axis_tuser ),
        // XGMII
        .xgmii_rxd         (gtx_rxd       ),
        .xgmii_rxc         (gtx_rxc       ),
        .xgmii_txd         (gtx_txd       ),
        .xgmii_txc         (gtx_txc       ),
        // FIFO
        .tx_fifo_overflow  (              ),
        .tx_fifo_bad_frame (              ),
        .tx_fifo_good_frame(              ),
        .rx_error_bad_frame(              ),
        .rx_error_bad_fcs  (              ),
        .rx_fifo_overflow  (              ),
        .rx_fifo_bad_frame (              ),
        .rx_fifo_good_frame(              ),
        .ifg_delay         (8'd12         )
    );
    
endmodule
