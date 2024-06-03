`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2022 05:20:47 PM
// Design Name: 
// Module Name: top
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

module top(
    //----------------------------------------------------------------------------
    // CLK
    //----------------------------------------------------------------------------
    input  wire [ 1:0] CLK_100MHz,
    input  wire        RESET,
    
    //----------------------------------------------------------------------------
    // LED & KEY
    //----------------------------------------------------------------------------
    output wire [ 7:0] LED ,
    input  wire [ 7:0] KEY ,
    input  wire        KEY3,
    
    //----------------------------------------------------------------------------
    // GPIO
    //----------------------------------------------------------------------------
    inout  wire [33:0] GPIO,
    
    //----------------------------------------------------------------------------
    // UART
    //----------------------------------------------------------------------------
    input  wire        UART_RXD,
    output wire        UART_TXD,
    
    //----------------------------------------------------------------------------
    // MGT
    //----------------------------------------------------------------------------
    input  wire [ 0:0] SFP_GTREFCLK_P,
    input  wire [ 0:0] SFP_GTREFCLK_N,
    output wire [ 3:0] SFP_TXP,
    output wire [ 3:0] SFP_TXN,
    input  wire [ 3:0] SFP_RXP,
    input  wire [ 3:0] SFP_RXN,
    output wire [ 3:0] SFP_TX_DISABLE,
    input  wire [ 3:0] SFP_RS0,
    inout  wire [ 3:0] SFP_SDA,
    inout  wire [ 3:0] SFP_SCL,
    
    //----------------------------------------------------------------------------
    // PCIE
    //----------------------------------------------------------------------------
    input  wire        PCIE_CLK_P,
    input  wire        PCIE_CLK_N,
    input  wire        PCIE_RST_N,
    output wire [ 3:0] PCIE_TXP,
    output wire [ 3:0] PCIE_TXN,
    input  wire [ 3:0] PCIE_RXP,
    input  wire [ 3:0] PCIE_RXN
    );
    
//////////////////////////////////////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////////////////////////////////////
    wire clk_100mhz;
    IBUF clk_100mhz_ibuf (.O(clk_100mhz), .I(CLK_100MHz[0]));
    
    //----------------------------------------------------------------------------
    wire mmcm_rst = 1'h0;
    wire mmcm_locked;
    wire clk_200mhz ;
    wire clk_125mhz ;
    
    //----------------------------------------------------------------------------
    mmcm_wrapper mmcm_wrapper_inst(
        .mmcm_in    (clk_100mhz ),
        .mmcm_rst   (1'h0       ),
        .mmcm_locked(mmcm_locked),
        .mmcm_out0  (clk_200mhz ),
        .mmcm_out1  (clk_125mhz )
    );
    
    wire rst = !mmcm_locked;
    
//////////////////////////////////////////////////////////////////////////////////
// PCIe & Virtio
//////////////////////////////////////////////////////////////////////////////////
    wire pcie_rst_n;
    wire pcie_clk  ;
    
    IBUFDS_GTE2 pcie_refclk_ibuf (.O(pcie_clk  ), .I(PCIE_CLK_P), .IB(PCIE_CLK_N));
    IBUF        pcie_resetn_ibuf (.O(pcie_rst_n), .I(PCIE_RST_N));
    
    //----------------------------------------------------------------------------
    wire [3:0] pcie_txp, pcie_txn;
    assign PCIE_TXP = pcie_txp;
    assign PCIE_TXN = pcie_txn;
    
    wire [3:0] pcie_rxp, pcie_rxn;
    assign pcie_rxp = PCIE_RXP;
    assign pcie_rxn = PCIE_RXN;
    
    //----------------------------------------------------------------------------
    wire         user_clk;
    wire         user_rst;
    wire         user_lnk;
    wire         user_rdy;
    
    //----------------------------------------------------------------------------
    wire         virtio_reset;
    wire [ 15:0] virtio_net_status = 16'h1;
    wire [ 47:0] virtio_net_mac    = 48'hEEEEEEEEEEEE;
    wire [ 15:0] virtio_net_mtu    = 16'h2048;
    
    //----------------------------------------------------------------------------
    wire         virtio_ctl_cmd_en;
    wire [  7:0] virtio_ctl_class ;
    wire [  7:0] virtio_ctl_cmd   ;
    wire         virtio_ctl_tvalid;
    wire         virtio_ctl_tready;
    wire [127:0] virtio_ctl_tdata ;
    wire [ 15:0] virtio_ctl_tkeep ;
    wire         virtio_ctl_tlast ;
    
    assign virtio_ctl_tready = 1'h1;
    
    //----------------------------------------------------------------------------
    wire [127:0] s_axis_vio_tdata;
    wire [ 15:0] s_axis_vio_tkeep;
    wire         s_axis_vio_tvalid;
    wire         s_axis_vio_tready;
    wire         s_axis_vio_tlast;
    
    wire [127:0] m_axis_vio_tdata;
    wire [ 15:0] m_axis_vio_tkeep;
    wire         m_axis_vio_tvalid;
    wire         m_axis_vio_tready;
    wire         m_axis_vio_tlast;
    
    //----------------------------------------------------------------------------
    eth_virtio_wrapper #(
        .TX_FRAME_FIFO(1),
        .RX_FRAME_FIFO(0),
        .TX_DEPTH(2048),
        .RX_DEPTH(2048),
        .TXRX_CNT(4)
    ) eth_virtio_wrapper_inst (
        .pcie_rst_n       (pcie_rst_n),
        .pcie_clk         (pcie_clk  ),
        
        .pcie_txp         (pcie_txp  ),
        .pcie_txn         (pcie_txn  ),
        .pcie_rxp         (pcie_rxp  ),
        .pcie_rxn         (pcie_rxn  ),
        
        .user_clk         (user_clk  ),
        .user_rst         (user_rst  ),
        .user_lnk         (user_lnk  ),
        .user_rdy         (user_rdy  ),
        
        .virtio_reset     (virtio_reset),
        .virtio_net_status(virtio_net_status),
        .virtio_net_mac   (virtio_net_mac),  
        .virtio_net_mtu   (virtio_net_mtu),  
      
        .virtio_ctl_cmd_en(virtio_ctl_cmd_en),
        .virtio_ctl_class (virtio_ctl_class ),
        .virtio_ctl_cmd   (virtio_ctl_cmd   ),
        .virtio_ctl_tvalid(virtio_ctl_tvalid),
        .virtio_ctl_tready(virtio_ctl_tready),
        .virtio_ctl_tdata (virtio_ctl_tdata ),
        .virtio_ctl_tkeep (virtio_ctl_tkeep ),
        .virtio_ctl_tlast (virtio_ctl_tlast ),
        
        .s_axis_tdata     (s_axis_vio_tdata ),
        .s_axis_tkeep     (s_axis_vio_tkeep ),
        .s_axis_tvalid    (s_axis_vio_tvalid),
        .s_axis_tready    (s_axis_vio_tready),
        .s_axis_tlast     (s_axis_vio_tlast ),
     
        .m_axis_tdata     (m_axis_vio_tdata ),
        .m_axis_tkeep     (m_axis_vio_tkeep ),
        .m_axis_tvalid    (m_axis_vio_tvalid),
        .m_axis_tready    (m_axis_vio_tready),
        .m_axis_tlast     (m_axis_vio_tlast )
    );

//////////////////////////////////////////////////////////////////////////////////
// GTX
//////////////////////////////////////////////////////////////////////////////////
    // TX Gearbox
    wire [ 6:0] gtx_txsequence   [3:0];
    wire [ 1:0] gtx_txheader     [3:0];
    wire [63:0] gtx_txdata       [3:0];
    // RX GearBox
    wire [ 3:0] gtx_rxgearboxslip;
    wire [ 3:0] gtx_rxheadervalid;
    wire [ 1:0] gtx_rxheader     [3:0];
    wire [ 3:0] gtx_rxdatavalid;
    wire [63:0] gtx_rxdata       [3:0];
    // GTX ResetDone
    wire [ 3:0] gtx_txreset_done;
    wire [ 3:0] gtx_rxreset_done;
    // GTX UsrClk2
    wire [ 3:0] gtx_txusrclk2;
    wire [ 3:0] gtx_rxusrclk2;
    // GTX DRP
    wire [31:0] gtx_drpaddr;
    wire [63:0] gtx_drpdi  ;
    wire [63:0] gtx_drpdo  ;
    wire [ 3:0] gtx_drpen  ;
    wire [ 3:0] gtx_drpwe  ;
    wire [ 3:0] gtx_drprdy ;
    
    wire [ 3:0] gtx_rxreset;
    wire [ 3:0] gtx_txreset = 4'h0;
    
    //----------------------------------------------------------------------------
    gtx_wrapper #(
        .SYSCLK_PERIOD(10)
    ) gtx_wrapper_inst(
        .soft_reset      (user_rst      ),
        .sysclk          (clk_100mhz    ),
        .gtx_txreset     (gtx_txreset   ),
        .gtx_rxreset     (gtx_rxreset   ),
       
        .gtrefclkp       (SFP_GTREFCLK_P),
        .gtrefclkn       (SFP_GTREFCLK_N),
        .gtx_txp         (SFP_TXP       ),
        .gtx_txn         (SFP_TXN       ),
        .gtx_rxp         (SFP_RXP       ),
        .gtx_rxn         (SFP_RXN       ),
        
        .gtx_txreset_done(gtx_txreset_done),
        .gtx_rxreset_done(gtx_rxreset_done),
        .gtx_txusrclk2   (gtx_txusrclk2   ),
        .gtx_rxusrclk2   (gtx_rxusrclk2   ),
        
        .gtx_drpaddr     (gtx_drpaddr),
        .gtx_drpdi       (gtx_drpdi  ),
        .gtx_drpdo       (gtx_drpdo  ),
        .gtx_drpen       (gtx_drpen  ),
        .gtx_drpwe       (gtx_drpwe  ),
        .gtx_drprdy      (gtx_drprdy ),
        
        .txsequence      ({gtx_txsequence   [3],gtx_txsequence   [2],gtx_txsequence   [1],gtx_txsequence   [0]}),
        .txheader        ({gtx_txheader     [3],gtx_txheader     [2],gtx_txheader     [1],gtx_txheader     [0]}),
        .txdata          ({gtx_txdata       [3],gtx_txdata       [2],gtx_txdata       [1],gtx_txdata       [0]}),
                     
        .rxgearboxslip   ({gtx_rxgearboxslip[3],gtx_rxgearboxslip[2],gtx_rxgearboxslip[1],gtx_rxgearboxslip[0]}),
        .rxheadervalid   ({gtx_rxheadervalid[3],gtx_rxheadervalid[2],gtx_rxheadervalid[1],gtx_rxheadervalid[0]}),
        .rxheader        ({gtx_rxheader     [3],gtx_rxheader     [2],gtx_rxheader     [1],gtx_rxheader     [0]}),
        .rxdatavalid     ({gtx_rxdatavalid  [3],gtx_rxdatavalid  [2],gtx_rxdatavalid  [1],gtx_rxdatavalid  [0]}),
        .rxdata          ({gtx_rxdata       [3],gtx_rxdata       [2],gtx_rxdata       [1],gtx_rxdata       [0]})
    );
    
    OBUF(.I(1'h0), .O(SFP_TX_DISABLE[0]));
    OBUF(.I(1'h0), .O(SFP_TX_DISABLE[1]));
    OBUF(.I(1'h0), .O(SFP_TX_DISABLE[2]));
    OBUF(.I(1'h0), .O(SFP_TX_DISABLE[3]));
    
    //----------------------------------------------------------------------------
    // GTX Gearbox Adapter
    //----------------------------------------------------------------------------
    // AXI-S Tx
    wire [127:0] tx_axis_tdata [3:0];
    wire [ 15:0] tx_axis_tkeep [3:0];
    wire [  3:0] tx_axis_tvalid;
    wire [  3:0] tx_axis_tready;
    wire [  3:0] tx_axis_tlast ;
    wire [  3:0] tx_axis_tuser ;
    // AXI-S Rx
    wire [127:0] rx_axis_tdata [3:0];
    wire [ 15:0] rx_axis_tkeep [3:0];
    wire [  3:0] rx_axis_tvalid;
    wire [  3:0] rx_axis_tready;
    wire [  3:0] rx_axis_tlast ;
    wire [  3:0] rx_axis_tuser ;
    
    //----------------------------------------------------------------------------
    wire [  3:0] rx_block_lock;
    wire [  6:0] rx_error_count [3:0];
    wire [  3:0] rx_prbs31_enable;
    wire [  3:0] tx_prbs31_enable;
    
    wire [ 15:0] tx_axis_credit;
    wire [ 15:0] tx_axis_window;
    wire [ 15:0] tx_axis_punish;
    wire [ 15:0] tx_axis_adjust;
    
    genvar n1;
    generate
    for (n1 = 0; n1 < 4; n1 = n1 + 1) begin
        mac_adapter #(
            .TX_FIFO_DEPTH(2048),
            .TX_FRAME_FIFO(0),
            .RX_FIFO_DEPTH(2048),
            .RX_FRAME_FIFO(1),
            .AXIS_DATA_WIDTH(128)
        )
        mac_adapter_inst (
            .clk               (user_clk),
            .rst               (user_rst),
            // PRBS
            .tx_prbs31_enable  (tx_prbs31_enable[n1]),
            .rx_prbs31_enable  (rx_prbs31_enable[n1]),
            .rx_error_count    (rx_error_count  [n1]),
            // Tx Flow Control
            .tx_axis_credit    (tx_axis_credit      ),
            .tx_axis_window    (tx_axis_window      ),
            .tx_axis_punish    (tx_axis_punish      ),
            .tx_axis_adjust    (tx_axis_adjust      ),
        
            .gtx_txreset_done (gtx_txreset_done [n1]),
            .gtx_rxreset_done (gtx_rxreset_done [n1]),
            .gtx_txusrclk2    (gtx_txusrclk2    [n1]),
            .gtx_rxusrclk2    (gtx_rxusrclk2    [n1]),
        
            .gtx_txsequence   (gtx_txsequence   [n1]),
            .gtx_txheader     (gtx_txheader     [n1]),
            .gtx_txdata       (gtx_txdata       [n1]),
                         
            .gtx_rxgearboxslip(gtx_rxgearboxslip[n1]),
            .gtx_rxheadervalid(gtx_rxheadervalid[n1]),
            .gtx_rxheader     (gtx_rxheader     [n1]),
            .gtx_rxdatavalid  (gtx_rxdatavalid  [n1]),
            .gtx_rxdata       (gtx_rxdata       [n1]),
            
            .rx_block_lock    (rx_block_lock    [n1]),
            
            .tx_axis_tdata    (tx_axis_tdata    [n1]),
            .tx_axis_tkeep    (tx_axis_tkeep    [n1]),
            .tx_axis_tvalid   (tx_axis_tvalid   [n1]),
            .tx_axis_tready   (tx_axis_tready   [n1]),
            .tx_axis_tlast    (tx_axis_tlast    [n1]),
            .tx_axis_tuser    (tx_axis_tuser    [n1]),
            
            .rx_axis_tdata    (rx_axis_tdata    [n1]),
            .rx_axis_tkeep    (rx_axis_tkeep    [n1]),
            .rx_axis_tvalid   (rx_axis_tvalid   [n1]),
            .rx_axis_tready   (rx_axis_tready   [n1]),
            .rx_axis_tlast    (rx_axis_tlast    [n1]),
            .rx_axis_tuser    (rx_axis_tuser    [n1])
        );
    end
    endgenerate
    
    //----------------------------------------------------------------------------
    // GTX DRP Monitor
    //----------------------------------------------------------------------------
    gtx_drp_mon #(.N(4)) gtx_drp_mon_inst (
        .rst               ({4{user_rst}}),
        .rx_block_lock     (rx_block_lock),

        .gtx_drpclk        (clk_100mhz ),
        .gtx_drpaddr       (gtx_drpaddr),
        .gtx_drpdi         (gtx_drpdi  ),
        .gtx_drpen         (gtx_drpen  ),
        .gtx_drpwe         (gtx_drpwe  ),
        .gtx_drprdy        (gtx_drprdy ),

        .gtx_reset_done    (gtx_rxreset_done),
        .gtx_reset_out     (gtx_rxreset)
    );
    
//////////////////////////////////////////////////////////////////////////////////
// Test Stub
//////////////////////////////////////////////////////////////////////////////////

    //----------------------------------------------------------------------------
    // GTX-0 <-> PCIE
    //----------------------------------------------------------------------------
    assign m_axis_vio_tready = tx_axis_tready[0];
    assign tx_axis_tdata [0] = m_axis_vio_tdata ;
    assign tx_axis_tkeep [0] = m_axis_vio_tkeep ;
    assign tx_axis_tvalid[0] = m_axis_vio_tvalid;
    assign tx_axis_tlast [0] = m_axis_vio_tlast ;
    assign tx_axis_tuser [0] = 1'h0;
    
    assign rx_axis_tready[0] = s_axis_vio_tready;
    assign s_axis_vio_tdata  = rx_axis_tdata [0];
    assign s_axis_vio_tkeep  = rx_axis_tkeep [0];
    assign s_axis_vio_tvalid = rx_axis_tvalid[0];
    assign s_axis_vio_tlast  = rx_axis_tlast [0];
    
//////////////////////////////////////////////////////////////////////////////////
// LED
//////////////////////////////////////////////////////////////////////////////////
    reg [31:0] count = 32'h0;
    reg [ 7:0] light =  1'h0;
    always @(posedge clk_200mhz) begin
        count <= count + 1'h1;
        if (count == 32'd200_000_000) begin
            light <= light ? light << 1 : 1;
            count <= 32'h0;
        end
    end
    assign LED = ~light;
    
//////////////////////////////////////////////////////////////////////////////////
// ILA
//////////////////////////////////////////////////////////////////////////////////
    //----------------------------------------------------------------------------
    // Local Cached iLA Data
    //----------------------------------------------------------------------------
    wire key3_in ; IBUF ibuf_key3(.I(KEY3), .O(key3_in));
    wire key3;
    debounce (.clk(user_clk), .switch_in(key3_in), .switch_raise(key3));
    
    //////////////////////////////////////////////////////////////////////////////
    
    reg [7:0] vio_tx_state, vio_rx_state, tlp_rq_state;
    
    always @(posedge user_clk) begin
        vio_tx_state <= eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_stat;
        vio_rx_state <= eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_stat;
        tlp_rq_state <= eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_tlp_rq_inst.tlp_int_rq_state;
    end
    wire vio_tx_probe = eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_stat != vio_tx_state;
    wire vio_rx_probe = eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_stat != vio_rx_state;
    wire tlp_rq_probe = eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_tlp_rq_inst.tlp_int_rq_state != tlp_rq_state;
    
    //----------------------------------------------------------------------------
    wire [ 15:0] probe_total, probe_index;
    wire [479:0] probe_input, probe_value;
    reg  [479:0] probe_cache;
    wire         probe_error;
    wire         probe_flush = key3;
    wire         probe_valid = (
        vio_rx_probe || tlp_rq_probe
        
        // eth_virtio_wrapper_inst.eth_virtio_vq_inst.virtq_notify_en || 
        // eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rc_valid    ||
        // eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rq_valid
    );
    
    assign probe_input = {
        4'hF,
        
        eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_tlp_rq_inst.tlp_rd_valid,
        eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_tlp_rq_inst.tlp_rd_ready,
        eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_tlp_rq_inst.tlp_int_rq_state,
        
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_flag,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_curr,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_read,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_h_wp,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_wrap,
        
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_flag,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_curr,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_read,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_h_wp,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_wrap,
        
        eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_stat,
        eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_stat,
        eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.vio_int_stat,
        //eth_virtio_wrapper_inst.eth_virtio_vq_inst.virtq_notify_en,
        
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tx_err_drop,
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tx_buf_av,  
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.fc_tx_npd,  
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.fc_tx_nph,  
        
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tdata, 
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tvalid,
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tready,
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tlast, 
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tkeep, 
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tuser, 
        
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tdata, 
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tready,
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tvalid,
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tlast, 
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tkeep, 
        eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tuser  
    };
    
    always @(posedge user_clk) begin
        probe_cache <= probe_input;
    end
    
    //----------------------------------------------------------------------------
    reg [7:0] probe_delay;
    always @(posedge user_clk) begin
        if (user_rst) begin
            probe_delay <= 1'h0;
        end else
        if (probe_valid) begin
            probe_delay <= 8'h20;
        end else
        if (probe_delay) begin
            probe_delay <= probe_delay - 8'h1;
        end
    end
    
    ila_cache #(.WIDTH(480), .DEPTH(2048)) ila_cache_inst(
        .clock(user_clk),
        .reset(user_rst),
        .total(probe_total),
        .valid(probe_valid || probe_delay),
        .probe(probe_cache),
        .flush(probe_flush),
        .index(probe_index),
        .value(probe_value)
    );
    
    //////////////////////////////////////////////////////////////////////////////
    /*
    wire [31:0] freq_out;
    clock_mon clock_mon_inst (
        .rst0_in (user_rst),
        .clk0_in (clk_100mhz),
        .frq0_in (32'd100_000_000),
        
        .rst1_in (user_rst),
        .clk1_in (user_clk),
        .frq1_out(freq_out)
    );
    */
    //////////////////////////////////////////////////////////////////////////////
    
    ila_0 ila_0_inst (
        .clk(user_clk),
        .probe0 ({
            probe_flush, probe_index, probe_value, probe_error,
            
            //-------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_totl,
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tdata,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tkeep,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tmove,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tlast,
            
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_tdata,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_tkeep,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_tlast,
            
            tx_axis_tvalid[0],
            tx_axis_tready[0],
            tx_axis_tlast [0],
            
            rx_axis_tvalid[0],
            rx_axis_tready[0],
            rx_axis_tlast [0],
            */
            //-------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_stat,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_read,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_curr,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_head,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_flag,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_wrap,
            
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_totl,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_expt,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_rest,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_sent,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_cont,
            
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_hint,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_next,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.vio_int_indx,
            
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rx_tdata,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rx_tlast,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rx_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rx_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rq_tsize,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rq_taddr,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rd_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_rd_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_wr_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_wr_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_wr_tlast,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].eth_virtio_vq_packed_rx_inst.tlp_wr_tdata,
            */
            //-------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tdata,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tkeep,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tmove,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk1[0].s_axis_pkt_tlast,
            
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.s_axis_tdata ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.s_axis_tkeep ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.s_axis_tvalid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.s_axis_tready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.s_axis_tlast ,
            */
            //-------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_stat,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_read,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_curr,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_head,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_flag,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.vio_int_wrap,
            
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rx_tdata,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rx_tlast,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rx_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rx_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rq_tsize,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rq_taddr,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rd_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_rd_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_wr_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_wr_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_wr_tlast,
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].eth_virtio_vq_packed_tx_inst.tlp_wr_tdata,
            */
            //-------------------------------------------------------------------
            /*
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_tdata,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_tkeep,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.genblk2[1].m_axis_pkt_tlast,
            
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.m_axis_tdata ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.m_axis_tkeep ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.m_axis_tvalid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.m_axis_tready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.m_axis_tlast ,
            */
            //-------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.vio_int_stat,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.vio_int_read,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.vio_int_curr,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.vio_int_head,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.vio_int_flag,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.vio_int_wrap,
            
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_rx_tlast,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_rx_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_rx_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_rq_tsize,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_rq_taddr,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_rd_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_rd_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_wr_valid,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_wr_ready,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_wr_tlast,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.eth_virtio_vq_packed_cx_inst.tlp_wr_tdata,
            */
            //--------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.virtio_msix_pba,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.virtq_notify_en,
            
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rc_data      ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rc_ready     ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rc_valid     ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rc_end_flag  ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rc_end_offset,
            
            //eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rq_data      ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rq_ready     ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rq_valid     ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rq_end_flag  ,
            eth_virtio_wrapper_inst.eth_virtio_vq_inst.tlp_rq_end_offset,
            */
            //--------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.vio_queue_msix_vector[0][0+:4],
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.vio_queue_msix_vector[1][0+:4],
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.vio_queue_msix_vector[2][0+:4],
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.vio_queue_msix_vector[3][0+:4],
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.vio_queue_msix_vector[4][0+:4],
            
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.vio_net_max_virtqueue_pairs,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.vio_num_queues,
            
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_awvalid ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_awready ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_awaddr  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_awsize  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_wvalid  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_wready  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_wdata   ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_wstrb   ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_bvalid  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_bready  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_arvalid ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_arready ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_araddr  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_rvalid  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_rready  ,
            eth_virtio_wrapper_inst.eth_virtio_completer_inst.s_axi_rdata   ,
            */
            //--------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_start_flag,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_end_flag,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_valid,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_off_q2,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_ext_q,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_act_q,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_off_q,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_sop_q,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_ext,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_off,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_efp,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_fmt,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_sel,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tlp_shr_rx_tdata,
            */
            //--------------------------------------------------------------------
            /*
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tx_err_drop,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.tx_buf_av,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.fc_tx_npd,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.fc_tx_nph,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.fc_tx_pd,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.fc_tx_ph,
            
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tdata, 
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tvalid,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tready,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tlast, 
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tkeep, 
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.s_axis_tx_tuser, 
            
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tdata, 
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tready,
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tvalid,
            // eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tlast, 
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tkeep, 
            eth_virtio_wrapper_inst.pcie_axi_wrapper_inst.m_axis_rx_tuser, 
            */
            //--------------------------------------------------------------------
            
            rx_block_lock //, clk_vip_trig, clk_vip_freq
        })
    );
    
    /*
    ila_1 ila_1_inst (
        .clk(gtx_txusrclk2[0]), //gtx_wrapper_inst.gtx_txusrclk[0]),
            rx_error_count[3],
            rx_error_count[2],
            rx_error_count[1],
            rx_error_count[0],
            
            genblk1[0].mac_adapter_inst.gtx_txd,
            genblk1[0].mac_adapter_inst.gtx_txc,
            
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo.m_status_good_frame,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo.m_status_bad_frame,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo.m_status_overflow, 
            
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo_axis_tdata ,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo_axis_tkeep ,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo_axis_tvalid,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo_axis_tready,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.tx_fifo_axis_tlast,
            
            genblk1[0].mac_adapter_inst.gtx_rxd,
            genblk1[0].mac_adapter_inst.gtx_rxc,
            
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.rx_fifo.m_status_good_frame,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.rx_fifo.m_status_bad_frame,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.rx_fifo.m_status_overflow,
            
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.rx_fifo_axis_tdata ,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.rx_fifo_axis_tkeep ,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.rx_fifo_axis_tvalid,
            genblk1[0].mac_adapter_inst.eth_mac_10g_fifo_inst.rx_fifo_axis_tlast
        })
    );
    
    wire [7:0] probe_out0;
    vio_0 vio_0_inst (
        .clk(user_clk),
        .probe_out0({ // 76'h0100_0010_000A_0002_00
            tx_prbs31_enable,
            rx_prbs31_enable,
            tx_axis_window,
            tx_axis_credit,
            tx_axis_punish,
            tx_axis_adjust,
            probe_out0
        })
    );
    */
endmodule
