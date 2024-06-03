`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/31/2022 10:19:07 PM
// Design Name:
// Module Name: pcie_axi_wrapper
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


module pcie_axi_wrapper #(
    // MSI-X Capability is Enabled
    parameter MSI_X_CAP = 1,
    // MSI Capability is Enabled
    parameter MSI_CAP = 0,                               
    // Width of PCIe AXI stream interfaces in bits             
    parameter PCIE_DATA_WIDTH = 128,
    // PCIe AXI stream tkeep signal width 
    parameter PCIE_KEEP_WIDTH = (PCIE_DATA_WIDTH/8),
    // Width of TLP input/output to Host side
    parameter TLP_DATA_WIDTH = 128,
    // Width of AXI data bus in bits
    parameter AXI_DATA_WIDTH = 128,
    // Width of AXI address bus in bits
    parameter AXI_ADDR_WIDTH = 32,
    // Width of AXI wstrb (width of data bus in words)
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    // Width of AXI ID signal
    parameter AXI_ID_WIDTH = 8
    ) (
    // System (SYS) Interface
    input  wire          sys_clk,
    input  wire          sys_rst_n,
    // Tx
    output wire [   3:0] pci_exp_txp,
    output wire [   3:0] pci_exp_txn,
    // Rx
    input  wire [   3:0] pci_exp_rxp,
    input  wire [   3:0] pci_exp_rxn,
    // PCIe Device Specific
    output wire [   7:0] cfg_bus_number,
    output wire [   4:0] cfg_device_number,
    output wire [   2:0] cfg_function_number,
    // Interrupt
    input  wire          cfg_interrupt           ,
    output wire          cfg_interrupt_rdy       ,
    input  wire          cfg_interrupt_assert    ,
    input  wire [   7:0] cfg_interrupt_di        ,
    output wire [   7:0] cfg_interrupt_do        ,
    output wire [   2:0] cfg_interrupt_mmenable  ,
    output wire          cfg_interrupt_msienable ,
    output wire          cfg_interrupt_msixenable,
    output wire          cfg_interrupt_msixfm    ,
    // PCIe Rx/Tx Common
    output wire          user_clk_out  ,
    output wire          user_reset_out,
    output wire          user_lnk_up   ,
    output wire          user_app_rdy  ,
    // AXI
    output wire [AXI_ID_WIDTH  -1:0] m_axi_awid         ,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_awaddr       ,
    output wire [7:0]                m_axi_awlen        ,
    output wire [2:0]                m_axi_awsize       ,
    output wire [1:0]                m_axi_awburst      ,
    output wire                      m_axi_awlock       ,
    output wire [3:0]                m_axi_awcache      ,
    output wire [2:0]                m_axi_awprot       ,
    output wire                      m_axi_awvalid      ,
    input  wire                      m_axi_awready      ,
    output wire [AXI_DATA_WIDTH-1:0] m_axi_wdata        ,
    output wire [AXI_STRB_WIDTH-1:0] m_axi_wstrb        ,
    output wire                      m_axi_wlast        ,
    output wire                      m_axi_wvalid       ,
    input  wire                      m_axi_wready       ,
    input  wire [AXI_ID_WIDTH  -1:0] m_axi_bid          ,
    input  wire [1:0]                m_axi_bresp        ,
    input  wire                      m_axi_bvalid       ,
    output wire                      m_axi_bready       ,
    output wire [AXI_ID_WIDTH  -1:0] m_axi_arid         ,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_araddr       ,
    output wire [7:0]                m_axi_arlen        ,
    output wire [2:0]                m_axi_arsize       ,
    output wire [1:0]                m_axi_arburst      ,
    output wire                      m_axi_arlock       ,
    output wire [3:0]                m_axi_arcache      ,
    output wire [2:0]                m_axi_arprot       ,
    output wire                      m_axi_arvalid      ,
    input  wire                      m_axi_arready      ,
    input  wire [AXI_ID_WIDTH  -1:0] m_axi_rid          ,
    input  wire [AXI_DATA_WIDTH-1:0] m_axi_rdata        ,
    input  wire [1:0]                m_axi_rresp        ,
    input  wire                      m_axi_rlast        ,
    input  wire                      m_axi_rvalid       ,
    output wire                      m_axi_rready       ,
    // AXI-S RQ
    output wire                      tlp_rq_ready       ,
    input  wire [TLP_DATA_WIDTH-1:0] tlp_rq_data        ,
    input  wire                      tlp_rq_valid       ,
    input  wire                      tlp_rq_start_flag  ,
    input  wire [               3:0] tlp_rq_start_offset,
    input  wire                      tlp_rq_end_flag    ,
    input  wire [               3:0] tlp_rq_end_offset  ,
    // AXI-S RC
    output wire [TLP_DATA_WIDTH-1:0] tlp_rc_data        ,
    output wire                      tlp_rc_valid       ,
    output wire                      tlp_rc_start_flag  ,
    output wire [               3:0] tlp_rc_start_offset,
    output wire                      tlp_rc_end_flag    ,
    output wire [               3:0] tlp_rc_end_offset  ,
    input  wire                      tlp_rc_ready
    );

    // AXI-S Tx
    wire [                5:0] tx_buf_av       ;
    wire                       tx_err_drop     ;
    wire                       tx_cfg_req      ;
    wire [PCIE_DATA_WIDTH-1:0] s_axis_tx_tdata ;
    wire                       s_axis_tx_tvalid;
    wire                       s_axis_tx_tready;
    wire [PCIE_KEEP_WIDTH-1:0] s_axis_tx_tkeep ;
    wire                       s_axis_tx_tlast ;
    wire [                3:0] s_axis_tx_tuser ;
    wire                       tx_cfg_gnt      ;

    // AXI-S Rx
    wire [PCIE_DATA_WIDTH-1:0] m_axis_rx_tdata ;
    wire                       m_axis_rx_tvalid;
    wire                       m_axis_rx_tready;
    wire [PCIE_KEEP_WIDTH-1:0] m_axis_rx_tkeep ;
    wire                       m_axis_rx_tlast ;
    wire [               21:0] m_axis_rx_tuser ;
    wire                       rx_np_ok        ;
    wire                       rx_np_req       ;

    // Flow Contol
    wire [ 11:0] fc_cpld      ;
    wire [  7:0] fc_cplh      ;
    wire [ 11:0] fc_npd       ;
    wire [  7:0] fc_nph       ;
    wire [ 11:0] fc_pd        ;
    wire [  7:0] fc_ph        ;
    reg  [  2:0] fc_sel       ;

    // Configuration
    wire [ 15:0] cfg_status   ;
    wire [ 15:0] cfg_command  ;
    wire [ 15:0] cfg_dstatus  ;
    wire [ 15:0] cfg_dcommand ;
    wire [ 15:0] cfg_lstatus  ;
    wire [ 15:0] cfg_lcommand ;
    wire [ 15:0] cfg_dcommand2;
    wire [  2:0] cfg_pcie_link_state;

    wire         cfg_pmcsr_pme_en;
    wire [  1:0] cfg_pmcsr_powerstate;
    wire         cfg_pmcsr_pme_status;
    wire         cfg_received_func_lvl_rst;

    wire [ 31:0] cfg_mgmt_do;
    wire         cfg_mgmt_rd_wr_done;
    wire [ 31:0] cfg_mgmt_di;
    wire [  3:0] cfg_mgmt_byte_en;
    wire [  9:0] cfg_mgmt_dwaddr;
    wire         cfg_mgmt_wr_en;
    wire         cfg_mgmt_rd_en;
    wire         cfg_mgmt_wr_readonly;

    // Interrupt
    // wire         cfg_interrupt           ; 
    // wire         cfg_interrupt_rdy       ; 
    // wire         cfg_interrupt_assert    ;
    // wire [  7:0] cfg_interrupt_di        ; 
    // wire [  7:0] cfg_interrupt_do        ; 
    // wire [  2:0] cfg_interrupt_mmenable  ; 
    // wire         cfg_interrupt_msienable ; 
    // wire         cfg_interrupt_msixenable; 
    // wire         cfg_interrupt_msixfm    ; 
    
    // EP Specific
    // wire [  7:0] cfg_bus_number;
    // wire [  4:0] cfg_device_number;
    // wire [  2:0] cfg_function_number;

    // PCIe DRP
    wire         pcie_drp_clk ;
    reg          pcie_drp_en  ;
    reg          pcie_drp_we  ;
    reg  [  8:0] pcie_drp_addr;
    reg  [ 15:0] pcie_drp_di  ;
    wire         pcie_drp_rdy ;
    wire [ 15:0] pcie_drp_do  ;

    //////////////////////////////////////////////////////////////////////////////
    // Integrated Block for PCI-E
    //////////////////////////////////////////////////////////////////////////////

    pcie_wrapper pcie_wrapper_inst(
        // System (SYS) Interface
        .sys_clk                  (sys_clk                  ),
        .sys_rst_n                (sys_rst_n                ),

        .pci_exp_txp              (pci_exp_txp              ),
        .pci_exp_txn              (pci_exp_txn              ),
        .pci_exp_rxp              (pci_exp_rxp              ),
        .pci_exp_rxn              (pci_exp_rxn              ),

        // Common
        .user_clk_out             (user_clk_out             ),
        .user_reset_out           (user_reset_out           ),
        .user_lnk_up              (user_lnk_up              ),
        .user_app_rdy             (user_app_rdy             ),

        // AXI Tx
        .tx_buf_av                (tx_buf_av                ),
        .tx_err_drop              (tx_err_drop              ),
        .tx_cfg_req               (tx_cfg_req               ),
        .s_axis_tx_tdata          (s_axis_tx_tdata          ),
        .s_axis_tx_tvalid         (s_axis_tx_tvalid         ),
        .s_axis_tx_tready         (s_axis_tx_tready         ),
        .s_axis_tx_tkeep          (s_axis_tx_tkeep          ),
        .s_axis_tx_tlast          (s_axis_tx_tlast          ),
        .s_axis_tx_tuser          (s_axis_tx_tuser          ),
        .tx_cfg_gnt               (tx_cfg_gnt               ),

        // AXI Rx
        .m_axis_rx_tdata          (m_axis_rx_tdata          ),
        .m_axis_rx_tvalid         (m_axis_rx_tvalid         ),
        .m_axis_rx_tready         (m_axis_rx_tready         ),
        .m_axis_rx_tkeep          (m_axis_rx_tkeep          ),
        .m_axis_rx_tlast          (m_axis_rx_tlast          ),
        .m_axis_rx_tuser          (m_axis_rx_tuser          ),
        .rx_np_ok                 (rx_np_ok                 ),
        .rx_np_req                (rx_np_req                ),

        // Flow Contol
        .fc_cpld                  (fc_cpld                  ),
        .fc_cplh                  (fc_cplh                  ),
        .fc_npd                   (fc_npd                   ),
        .fc_nph                   (fc_nph                   ),
        .fc_pd                    (fc_pd                    ),
        .fc_ph                    (fc_ph                    ),
        .fc_sel                   (fc_sel                   ),

        // Configuration
        .cfg_status               (cfg_status               ),
        .cfg_command              (cfg_command              ),
        .cfg_dstatus              (cfg_dstatus              ),
        .cfg_dcommand             (cfg_dcommand             ),
        .cfg_lstatus              (cfg_lstatus              ),
        .cfg_lcommand             (cfg_lcommand             ),
        .cfg_dcommand2            (cfg_dcommand2            ),
        .cfg_pcie_link_state      (cfg_pcie_link_state      ),

        .cfg_pmcsr_pme_en         (cfg_pmcsr_pme_en         ),
        .cfg_pmcsr_powerstate     (cfg_pmcsr_powerstate     ),
        .cfg_pmcsr_pme_status     (cfg_pmcsr_pme_status     ),
        .cfg_received_func_lvl_rst(cfg_received_func_lvl_rst),

        .cfg_mgmt_do              (cfg_mgmt_do              ),
        .cfg_mgmt_rd_wr_done      (cfg_mgmt_rd_wr_done      ),
        .cfg_mgmt_di              (cfg_mgmt_di              ),
        .cfg_mgmt_byte_en         (cfg_mgmt_byte_en         ),
        .cfg_mgmt_dwaddr          (cfg_mgmt_dwaddr          ),
        .cfg_mgmt_wr_en           (cfg_mgmt_wr_en           ),
        .cfg_mgmt_rd_en           (cfg_mgmt_rd_en           ),
        .cfg_mgmt_wr_readonly     (cfg_mgmt_wr_readonly     ),

        // Interrupt
        .cfg_interrupt            (cfg_interrupt            ), 
        .cfg_interrupt_rdy        (cfg_interrupt_rdy        ), 
        .cfg_interrupt_assert     (cfg_interrupt_assert     ),
        .cfg_interrupt_di         (cfg_interrupt_di         ), 
        .cfg_interrupt_do         (cfg_interrupt_do         ), 
        .cfg_interrupt_mmenable   (cfg_interrupt_mmenable   ), 
        .cfg_interrupt_msienable  (cfg_interrupt_msienable  ), 
        .cfg_interrupt_msixenable (cfg_interrupt_msixenable ), 
        .cfg_interrupt_msixfm     (cfg_interrupt_msixfm     ), 

        .cfg_bus_number           (cfg_bus_number           ),
        .cfg_device_number        (cfg_device_number        ),
        .cfg_function_number      (cfg_function_number      ),

         // PCIe DRP
        .pcie_drp_clk             (pcie_drp_clk             ),
        .pcie_drp_en              (pcie_drp_en              ),
        .pcie_drp_we              (pcie_drp_we              ),
        .pcie_drp_addr            (pcie_drp_addr            ),
        .pcie_drp_di              (pcie_drp_di              ),
        .pcie_drp_rdy             (pcie_drp_rdy             ),
        .pcie_drp_do              (pcie_drp_do              )
    );

    wire pcie_user_rst = user_reset_out;
    wire pcie_user_clk = user_clk_out;
    
    //----------------------------------------------------------------------------
    assign rx_np_ok   = 1'h1;
    assign rx_np_req  = 1'h1;
    assign tx_cfg_gnt = 1'h1;

    //////////////////////////////////////////////////////////////////////////////
    // PCI-E Configuration Space (DRP & TLP)
    //////////////////////////////////////////////////////////////////////////////
    reg  [7:0] pcie_cfg_state;
    assign pcie_drp_clk = pcie_user_clk;

    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            pcie_cfg_state <=  8'h0;
            pcie_drp_di    <= 32'h0;
            pcie_drp_en    <=  1'h0;
            pcie_drp_we    <=  1'h0;
            pcie_drp_addr  <=  9'h0;
            pcie_drp_di    <= 16'h0;
        end else begin
            case (pcie_cfg_state)
                8'h00: begin
                    pcie_cfg_state <= 8'h01;
                    // MSI_CAP_NEXTPTR = 0x29 [7:0], MSIX_CAP_NEXTPTR[7:0] = 0x02b, PCIE_CAP_NEXTPTR[7:0] = 0x32 [15:8]
                    pcie_drp_addr  <= MSI_X_CAP ? 9'h2B: (MSI_CAP ? 9'h29 : 9'h32);
                    pcie_drp_en    <=  1'h1;
                    pcie_drp_we    <=  1'h0;
                end
                8'h01: begin
                    pcie_drp_en <= 1'h0;
                    pcie_drp_we <= 1'h0;
                    if (pcie_drp_rdy) begin
                        pcie_cfg_state <= 8'h02;
                        pcie_drp_di    <= (MSI_CAP || MSI_X_CAP) ? {pcie_drp_do[15:8],8'hA8} : {8'hA8,pcie_drp_do[7:0]}; // 8'hA8 = 4 x 8'h2A: const value from "pcie_config_space.v"
                        pcie_drp_en    <= 1'h1;
                        pcie_drp_we    <= 1'h1;
                    end
                end
                8'h02: begin
                    pcie_drp_en <= 1'h0;
                    pcie_drp_we <= 1'h0;
                    if (pcie_drp_rdy) begin
                        pcie_cfg_state <= 8'h03;
                        pcie_drp_en    <= 1'h1;
                    end
                end
                8'h03: begin
                    pcie_drp_en <= 1'h0;
                    pcie_drp_we <= 1'h0;
                end
            endcase
        end
    end
    //----------------------------------------------------------------------------
    wire [PCIE_DATA_WIDTH-1:0] s_axis_cx_tdata ;
    wire                       s_axis_cx_tvalid;
    wire                       s_axis_cx_tready;
    wire                       s_axis_cx_start_flag;
    wire [                3:0] s_axis_cx_start_offset;
    wire                       s_axis_cx_end_flag;
    wire [                3:0] s_axis_cx_end_offset;

    wire [PCIE_DATA_WIDTH-1:0] m_axis_cx_tdata ;
    wire                       m_axis_cx_tvalid;
    wire                       m_axis_cx_tready;
    wire [PCIE_KEEP_WIDTH-1:0] m_axis_cx_tkeep ;
    wire                       m_axis_cx_start_flag;
    wire [                3:0] m_axis_cx_start_offset;
    wire                       m_axis_cx_end_flag;
    wire [                3:0] m_axis_cx_end_offset;
    
    wire [                3:0] m_axis_cx_tuser;
    wire                       m_axis_cx_tlast;

    pcie_config_space #(
        .PCI_DATA_WIDTH(128)
    ) pcie_config_space_inst(
        .clk                (pcie_user_clk          ),
        .rst                (pcie_user_rst          ),

        .rx_cfg_data        (s_axis_cx_tdata        ),
        .rx_cfg_valid       (s_axis_cx_tvalid       ),
        .rx_cfg_start_flag  (s_axis_cx_start_flag   ),
        .rx_cfg_start_offset(s_axis_cx_start_offset ),
        .rx_cfg_end_flag    (s_axis_cx_end_flag     ),
        .rx_cfg_end_offset  (s_axis_cx_end_offset   ),
        .rx_cfg_ready       (s_axis_cx_tready       ),

        .tx_cfg_ready       (m_axis_cx_tready       ),
        .tx_cfg_data        (m_axis_cx_tdata        ),
        .tx_cfg_valid       (m_axis_cx_tvalid       ),
        .tx_cfg_start_flag  (m_axis_cx_start_flag   ),
        .tx_cfg_start_offset(m_axis_cx_start_offset ),
        .tx_cfg_end_flag    (m_axis_cx_end_flag     ),
        .tx_cfg_end_offset  (m_axis_cx_end_offset   )
    );

    assign m_axis_cx_tlast = m_axis_cx_end_flag;
    assign m_axis_cx_tuser = 4'h0;
    assign m_axis_cx_tkeep = m_axis_cx_tlast ? {
        {4{&m_axis_cx_end_offset[3:2]}},
        {4{ m_axis_cx_end_offset[3:3]}},
        {4{|m_axis_cx_end_offset[3:2]}}, 4'hF
    } : 16'hFFFF;

    //////////////////////////////////////////////////////////////////////////////
    // PCI-E Root to AXI Endpoint (Completer)
    //////////////////////////////////////////////////////////////////////////////
    localparam PCIE_WORD_COUNT = PCIE_DATA_WIDTH / 32;
    
    wire [PCIE_DATA_WIDTH-1:0] s_axis_cq_tdata ;
    wire [PCIE_KEEP_WIDTH-1:0] s_axis_cq_tkeep ;
    wire [PCIE_WORD_COUNT-1:0] s_axis_cq_wcount = {|s_axis_cq_tkeep[12+:4],|s_axis_cq_tkeep[8+:4],|s_axis_cq_tkeep[4+:4],|s_axis_cq_tkeep[0+:4]};
    wire                       s_axis_cq_tvalid;
    wire                       s_axis_cq_tready;
    wire                       s_axis_cq_tlast ;
    wire [               84:0] s_axis_cq_tuser ;

    wire [PCIE_DATA_WIDTH-1:0] m_axis_cc_tdata ;
    wire [PCIE_WORD_COUNT-1:0] m_axis_cc_wcount;
    wire [PCIE_KEEP_WIDTH-1:0] m_axis_cc_tkeep = {{4{m_axis_cc_wcount[3]}},{4{m_axis_cc_wcount[2]}},{4{m_axis_cc_wcount[1]}},{4{m_axis_cc_wcount[0]}}};
    wire                       m_axis_cc_tvalid;
    wire                       m_axis_cc_tready;
    wire                       m_axis_cc_tlast ;
    wire [               31:0] m_axis_cc_tuser ;

    wire [               15:0] completer_id = {cfg_bus_number, cfg_device_number, cfg_function_number};

    pcie_us_axi_master #(
        .AXIS_PCIE_DATA_WIDTH(PCIE_DATA_WIDTH),
        .AXI_ADDR_WIDTH      ( 32),
        .AXI_MAX_BURST_LEN   (128)
    ) pcie_us_axi_master_inst(
        .clk                (pcie_user_clk   ),
        .rst                (pcie_user_rst   ),

        .s_axis_cq_tdata    (s_axis_cq_tdata ),
        .s_axis_cq_tkeep    (s_axis_cq_tkeep ),
        .s_axis_cq_tvalid   (s_axis_cq_tvalid),
        .s_axis_cq_tready   (s_axis_cq_tready),
        .s_axis_cq_tlast    (s_axis_cq_tlast ),
        .s_axis_cq_tuser    (s_axis_cq_tuser ),

        .m_axis_cc_tdata    (m_axis_cc_tdata ),
        .m_axis_cc_tkeep    (m_axis_cc_wcount),
        .m_axis_cc_tvalid   (m_axis_cc_tvalid),
        .m_axis_cc_tready   (m_axis_cc_tready),
        .m_axis_cc_tlast    (m_axis_cc_tlast ),
        .m_axis_cc_tuser    (m_axis_cc_tuser ),

        .m_axi_awid         (m_axi_awid      ),
        .m_axi_awaddr       (m_axi_awaddr    ),
        .m_axi_awlen        (m_axi_awlen     ),
        .m_axi_awsize       (m_axi_awsize    ),
        .m_axi_awburst      (m_axi_awburst   ),
        .m_axi_awlock       (m_axi_awlock    ),
        .m_axi_awcache      (m_axi_awcache   ),
        .m_axi_awprot       (m_axi_awprot    ),
        .m_axi_awvalid      (m_axi_awvalid   ),
        .m_axi_awready      (m_axi_awready   ),
        .m_axi_wdata        (m_axi_wdata     ),
        .m_axi_wstrb        (m_axi_wstrb     ),
        .m_axi_wlast        (m_axi_wlast     ),
        .m_axi_wvalid       (m_axi_wvalid    ),
        .m_axi_wready       (m_axi_wready    ),
        .m_axi_bid          (m_axi_bid       ),
        .m_axi_bresp        (m_axi_bresp     ),
        .m_axi_bvalid       (m_axi_bvalid    ),
        .m_axi_bready       (m_axi_bready    ),
        .m_axi_arid         (m_axi_arid      ),
        .m_axi_araddr       (m_axi_araddr    ),
        .m_axi_arlen        (m_axi_arlen     ),
        .m_axi_arsize       (m_axi_arsize    ),
        .m_axi_arburst      (m_axi_arburst   ),
        .m_axi_arlock       (m_axi_arlock    ),
        .m_axi_arcache      (m_axi_arcache   ),
        .m_axi_arprot       (m_axi_arprot    ),
        .m_axi_arvalid      (m_axi_arvalid   ),
        .m_axi_arready      (m_axi_arready   ),
        .m_axi_rid          (m_axi_rid       ),
        .m_axi_rdata        (m_axi_rdata     ),
        .m_axi_rresp        (m_axi_rresp     ),
        .m_axi_rlast        (m_axi_rlast     ),
        .m_axi_rvalid       (m_axi_rvalid    ),
        .m_axi_rready       (m_axi_rready    ),

        .completer_id       (completer_id    ),
        .completer_id_enable(1'h1            ),
        .max_payload_size   (3'h3            )
    );

    //////////////////////////////////////////////////////////////////////////////
    // PCI-E Rx Packet Split and Demux
    //////////////////////////////////////////////////////////////////////////////

    //----------------------------------------------------------------------------
    // PCIE RX Split
    //----------------------------------------------------------------------------
    wire         m_axis_rx_start_flag   = m_axis_rx_tuser[14:14] && m_axis_rx_tvalid;
    wire [  4:0] m_axis_rx_start_offset = m_axis_rx_tuser[13:10];
    wire         m_axis_rx_end_flag     = m_axis_rx_tuser[21:21] && m_axis_rx_tvalid;
    wire [  4:0] m_axis_rx_end_offset   = m_axis_rx_tuser[20:17];
    
    reg          tlp_shr_rx_start_flag;
    wire [  3:0] tlp_shr_rx_start_offset;
    reg          tlp_shr_rx_end_flag;
    wire [  3:0] tlp_shr_rx_end_offset;
    
    reg  [127:0] tlp_shr_rx_tdata;
    reg  [ 15:0] tlp_shr_rx_tkeep;
    reg          tlp_shr_rx_valid;
    reg          tlp_shr_rx_ready;
    
    reg  [255:0] tlp_shr_rx_val_q, tlp_shr_rx_val;
    reg  [  7:0] tlp_shr_rx_off_q, tlp_shr_rx_off, tlp_shr_rx_off_q2; // Start-of-Packet Offset (in bits)
    reg  [  7:0] tlp_shr_rx_efp_q, tlp_shr_rx_efp;
    reg          tlp_shr_rx_ext_q, tlp_shr_rx_ext;
    reg          tlp_shr_rx_sop_q;
    reg          tlp_shr_rx_act_q;
    
    //----------------------------------------------------------------------------
    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_act_q <= 1'h0;
        end else
        if (m_axis_rx_tvalid && m_axis_rx_tready) begin
            case ({m_axis_rx_start_flag,m_axis_rx_end_flag})
                2'b01: tlp_shr_rx_act_q <= tlp_shr_rx_act_q && !m_axis_rx_tready;
                2'b10: tlp_shr_rx_act_q <= 1'h1;
            endcase
        end
    end
    
    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_sop_q <= 1'h0;
        end else
        if (!tlp_shr_rx_ready) begin
            tlp_shr_rx_sop_q <= tlp_shr_rx_start_flag;
        end else
        if (tlp_shr_rx_ext_q) begin
            tlp_shr_rx_sop_q <= 1'h1;
        end else
        if (m_axis_rx_end_flag && !tlp_shr_rx_ext) begin
            tlp_shr_rx_sop_q <= 1'h1;
        end else begin
            tlp_shr_rx_sop_q <= 1'h0;
        end
    end
    
    always @(*) begin
        if (pcie_user_rst || tlp_shr_rx_ext_q) begin
            tlp_shr_rx_start_flag = 1'h0;
        end else
        if (m_axis_rx_start_flag && !tlp_shr_rx_act_q) begin
            tlp_shr_rx_start_flag = 1'h1;
        end else begin
            tlp_shr_rx_start_flag = tlp_shr_rx_sop_q;
        end
    end
   
    //----------------------------------------------------------------------------
    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_off_q2 <=   8'h0;
            tlp_shr_rx_off_q  <=   8'h0;
            tlp_shr_rx_val_q  <= 256'h0;
        end else
        if (m_axis_rx_tvalid && m_axis_rx_tready) begin
            tlp_shr_rx_off_q2 <= tlp_shr_rx_off_q;
            tlp_shr_rx_off_q  <= tlp_shr_rx_off;
            tlp_shr_rx_val_q  <= tlp_shr_rx_val;
            
            if (m_axis_rx_start_flag) begin
                tlp_shr_rx_off_q2 <= tlp_shr_rx_off_q;
                tlp_shr_rx_off_q <= {m_axis_rx_start_offset,3'h0};
            end
        end
    end

    always @(*) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_val = 256'h0;
            tlp_shr_rx_off =   8'h0;
        end else
        if (m_axis_rx_tvalid && !tlp_shr_rx_ext_q) begin
            tlp_shr_rx_val = {m_axis_rx_tdata,tlp_shr_rx_val_q[128+:128]};
            tlp_shr_rx_off = tlp_shr_rx_off_q;

            if (m_axis_rx_start_flag && !tlp_shr_rx_act_q) begin
                tlp_shr_rx_off = {m_axis_rx_start_offset,3'h0};
            end
        end else begin
            tlp_shr_rx_val = tlp_shr_rx_val_q;
            tlp_shr_rx_off = tlp_shr_rx_off_q;
        end
    end
    
    //----------------------------------------------------------------------------
    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_efp_q <= 8'h0;
            tlp_shr_rx_ext_q <= 1'h0;
        end else
        if (tlp_shr_rx_valid && tlp_shr_rx_ready) begin
            tlp_shr_rx_efp_q <= tlp_shr_rx_efp;
            tlp_shr_rx_ext_q <= tlp_shr_rx_ext;
        end
    end

    always @(*) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_end_flag = 1'h0;
            tlp_shr_rx_efp = 8'h0;
            tlp_shr_rx_ext = 1'h0;
        end else
        if (tlp_shr_rx_ext_q) begin
            tlp_shr_rx_end_flag = 1'h1;
            tlp_shr_rx_efp = tlp_shr_rx_efp_q;
            tlp_shr_rx_ext = 1'h0;
        end else
        if (m_axis_rx_tvalid && m_axis_rx_end_flag) begin
            case ({tlp_shr_rx_off[6:5],m_axis_rx_end_offset[3:2]})
                4'h0, 4'h1, 4'h2, 4'h3: begin // start = 0, end = X
                    tlp_shr_rx_end_flag = 1'h1;
                    tlp_shr_rx_ext = 1'h0;
                    tlp_shr_rx_efp = {m_axis_rx_end_offset[3:2],5'b11_111};
                end

                4'h4, 4'h9, 4'hE: begin // start:end = 4:3(01:00), 8:7(10:01), 12:11(11:10)
                    tlp_shr_rx_end_flag = 1'h1;
                    tlp_shr_rx_ext = 1'h0;
                    tlp_shr_rx_efp = 8'h7F;
                end

                4'h8, 4'hD: begin // start:end = 8:3(10:00), 12:7(11:01)
                    tlp_shr_rx_end_flag = 1'h1;
                    tlp_shr_rx_ext = 1'h0;
                    tlp_shr_rx_efp = 8'h5F;
                end

                4'hC: begin // start:end = 12:3(11:00)
                    tlp_shr_rx_end_flag = 1'h1;
                    tlp_shr_rx_ext = 1'h0;
                    tlp_shr_rx_efp = 8'h3F;
                end

                4'h5, 4'hA, 4'hF: begin // start:end = 4:7(01:01), 8:11(10:10), 12:15(11:11)
                    tlp_shr_rx_end_flag = 1'h0;
                    tlp_shr_rx_ext = 1'h1;
                    tlp_shr_rx_efp = 8'h1F;
                end

                4'h6, 4'hB: begin // start:end = 4:11(01:10), 8:15(10:11)
                    tlp_shr_rx_end_flag = 1'h0;
                    tlp_shr_rx_ext = 1'h1;
                    tlp_shr_rx_efp = 8'h3F;
                end

                4'h7: begin // start = 4:15(01:11)
                    tlp_shr_rx_end_flag = 1'h0;
                    tlp_shr_rx_ext = 1'h1;
                    tlp_shr_rx_efp = 8'h5F;
                end
            endcase
        end else begin
            tlp_shr_rx_end_flag = 1'h0;
            tlp_shr_rx_efp = tlp_shr_rx_efp_q;
            tlp_shr_rx_ext = 1'h0;
        end
    end
    
    //----------------------------------------------------------------------------
    always @(*) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_tdata = 128'h0;
        end else
        if (tlp_shr_rx_ext_q) begin
            // 1) Extended cycle from last (not-finished) data transmission
            tlp_shr_rx_tdata = tlp_shr_rx_val[128+:128] >> tlp_shr_rx_off_q2;
        end else
        if (m_axis_rx_start_flag && !tlp_shr_rx_act_q && !m_axis_rx_start_offset) begin
            // 2) First cycle of the aligned transmission
            tlp_shr_rx_tdata = m_axis_rx_tdata;
        end else
        if (tlp_shr_rx_off_q) begin
            // 3) Cached data with un-aligned transmission, because of start_offset != 0
            tlp_shr_rx_tdata = tlp_shr_rx_val >> tlp_shr_rx_off_q;
        end else begin
            // 4) Rest of an aligned transmission
            tlp_shr_rx_tdata = m_axis_rx_tdata;
        end
    end
    
    assign tlp_shr_rx_start_offset = tlp_shr_rx_off[3+:4];
    assign tlp_shr_rx_end_offset   = tlp_shr_rx_efp[3+:4];
    
    //----------------------------------------------------------------------------
    always @(*) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_valid = 1'h0;
        end else
        if (tlp_shr_rx_ext_q) begin
            tlp_shr_rx_valid = 1'h1;
        end else
        if (m_axis_rx_tvalid) begin
            case ({m_axis_rx_start_flag,m_axis_rx_end_flag})
                2'b10: tlp_shr_rx_valid = !m_axis_rx_start_offset;
                default: begin
                    tlp_shr_rx_valid = 1'h1;
                end
            endcase
        end else begin
            tlp_shr_rx_valid = 1'h0;
        end
    end

    //----------------------------------------------------------------------------
    assign m_axis_rx_tready = m_axis_rx_tvalid && tlp_shr_rx_ready && !tlp_shr_rx_ext_q;
    
    //----------------------------------------------------------------------------
    // PCI-E Rx Route Select
    //----------------------------------------------------------------------------
    reg  [1:0] tlp_shr_rx_sel_q;
    reg  [1:0] tlp_shr_rx_sel;
    wire [6:0] tlp_shr_rx_fmt = tlp_shr_rx_tdata[24+:7];

    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_sel_q <= 2'h0;
        end else begin
            tlp_shr_rx_sel_q <= tlp_shr_rx_sel;
        end
    end

    always @(*) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_sel = 2'h0;
        end else
        if (tlp_shr_rx_valid && tlp_shr_rx_start_flag) begin
            case (tlp_shr_rx_fmt)
                default: tlp_shr_rx_sel = 2'h0;
                7'h04, 7'h05: tlp_shr_rx_sel = 2'h1;
                7'h00, 7'h40: tlp_shr_rx_sel = 2'h2;
                7'h4A       : tlp_shr_rx_sel = 2'h3;
            endcase
        end else begin
            tlp_shr_rx_sel = tlp_shr_rx_sel_q;
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // PCI-E Endpoint to Root (RQ/RC Streams)
    //////////////////////////////////////////////////////////////////////////////
    
    //----------------------------------------------------------------------------
    // RQ Stream from PCI-E Endpoint
    //----------------------------------------------------------------------------
    wire         m_axis_rq_tvalid = tlp_rq_valid;
    wire [127:0] m_axis_rq_tdata  = tlp_rq_data;
    wire [ 15:0] m_axis_rq_tkeep;
    wire         m_axis_rq_tlast  = tlp_rq_end_flag;
    wire         m_axis_rq_tready;

    assign m_axis_rq_tkeep = !tlp_rq_end_flag ? 16'hFFFF : {
        {4{&tlp_rq_end_offset[3:2]}},
        {4{ tlp_rq_end_offset[3:3]}},
        {4{|tlp_rq_end_offset[3:2]}}, 4'hF
    };
    assign tlp_rq_ready = m_axis_rq_tready;

    //----------------------------------------------------------------------------
    // RC Stream respond to PCI-E Root
    //----------------------------------------------------------------------------
    assign tlp_rc_valid        = tlp_shr_rx_valid & tlp_shr_rx_sel == 'h3;
    assign tlp_rc_data         = tlp_shr_rx_tdata;
    assign tlp_rc_start_flag   = tlp_shr_rx_start_flag  ;
    assign tlp_rc_start_offset = tlp_shr_rx_start_offset;
    assign tlp_rc_end_flag     = tlp_shr_rx_end_flag    ;
    assign tlp_rc_end_offset   = tlp_shr_rx_end_offset  ;
                                                   
    //----------------------------------------------------------------------------
    // RX Arbiter for CX(Config Spece Req)/CQ/RC from PCI-E Root
    //----------------------------------------------------------------------------
    always @(*) begin
        if (pcie_user_rst) begin
            tlp_shr_rx_ready = 1'h0;
        end else begin
            case (tlp_shr_rx_sel)
                default: tlp_shr_rx_ready = 1'h1;
                'h1: tlp_shr_rx_ready = s_axis_cx_tready;
                'h2: tlp_shr_rx_ready = s_axis_cq_tready;
                'h3: tlp_shr_rx_ready = tlp_rc_ready;
            endcase
        end
    end

    // PCI-E Configuration Space
    assign s_axis_cx_tdata        = tlp_shr_rx_tdata;
    assign s_axis_cx_tvalid       = tlp_shr_rx_valid & tlp_shr_rx_sel == 'h1;
    assign s_axis_cx_start_flag   = tlp_shr_rx_start_flag  ;
    assign s_axis_cx_start_offset = tlp_shr_rx_start_offset;
    assign s_axis_cx_end_flag     = tlp_shr_rx_end_flag    ;
    assign s_axis_cx_end_offset   = tlp_shr_rx_end_offset  ;
    
    // PCI-E Completer Query/Response
    assign s_axis_cq_tdata        = tlp_shr_rx_tdata;
    assign s_axis_cq_tvalid       = tlp_shr_rx_valid & tlp_shr_rx_sel == 'h2;
    assign s_axis_cq_tkeep        = tlp_shr_rx_tkeep;
    assign s_axis_cq_tlast        = tlp_shr_rx_end_flag;
    assign s_axis_cq_tuser[ 3: 0] =  (4'hF << tlp_shr_rx_start_offset[1:0]); // First-BE
    assign s_axis_cq_tuser[ 7: 4] = ~(4'hE << tlp_shr_rx_end_offset  [1:0]); // Last-BE
    assign s_axis_cq_tuser[39: 8] = 32'h0000FFFF;
    assign s_axis_cq_tuser[40:40] = tlp_shr_rx_start_flag;
    assign s_axis_cq_tuser[84:41] = 'h0;

    //----------------------------------------------------------------------------
    // Tx Mux for RQ/CX(Config Space Cpl)/CC from PCI-E Endpoint
    //----------------------------------------------------------------------------
    wire         s_axis_rq_tvalid;
    wire [127:0] s_axis_rq_tdata ;
    wire [ 15:0] s_axis_rq_tkeep ;
    wire         s_axis_rq_tlast ;
    wire         s_axis_rq_tready;
    axis_fifo #(
        .DEPTH(1024),
        .DATA_WIDTH(128),
        .KEEP_ENABLE(1),
        .LAST_ENABLE(1),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .FRAME_FIFO(0)
    )
    axis_fifo_inst (
        .clk(pcie_user_clk),
        .rst(pcie_user_rst),
        
        .s_axis_tdata (m_axis_rq_tdata ),
        .s_axis_tkeep (m_axis_rq_tkeep ),
        .s_axis_tvalid(m_axis_rq_tvalid),
        .s_axis_tready(m_axis_rq_tready),
        .s_axis_tlast (m_axis_rq_tlast ),
        
        .m_axis_tdata (s_axis_rq_tdata ),
        .m_axis_tkeep (s_axis_rq_tkeep ),
        .m_axis_tvalid(s_axis_rq_tvalid),
        .m_axis_tready(s_axis_rq_tready),
        .m_axis_tlast (s_axis_rq_tlast )
    );
    
    //----------------------------------------------------------------------------
    axis_arb_mux #(
        .S_COUNT    (3),
        .DATA_WIDTH (128),
        .KEEP_ENABLE(1),
        .ID_ENABLE  (0),
        .DEST_ENABLE(0),
        .USER_ENABLE(1),
        .USER_WIDTH (4),
        .LAST_ENABLE(1)
    ) axis_arb_mux_inst (
        .clk          (pcie_user_clk),
        .rst          (pcie_user_rst),

        .s_axis_tdata ({s_axis_rq_tdata ,m_axis_cx_tdata ,m_axis_cc_tdata }),
        .s_axis_tkeep ({s_axis_rq_tkeep ,m_axis_cx_tkeep ,m_axis_cc_tkeep }),
        .s_axis_tvalid({s_axis_rq_tvalid,m_axis_cx_tvalid,m_axis_cc_tvalid}),
        .s_axis_tready({s_axis_rq_tready,m_axis_cx_tready,m_axis_cc_tready}),
        .s_axis_tlast ({s_axis_rq_tlast ,m_axis_cx_tlast ,m_axis_cc_tlast }),
        .s_axis_tuser (8'h0),

        .m_axis_tdata (s_axis_tx_tdata ),
        .m_axis_tkeep (s_axis_tx_tkeep ),
        .m_axis_tvalid(s_axis_tx_tvalid),
        .m_axis_tready(s_axis_tx_tready),
        .m_axis_tlast (s_axis_tx_tlast ),
        .m_axis_tuser (s_axis_tx_tuser )
    );
    
    //////////////////////////////////////////////////////////////////////////////
    // Flow Control (Not in Use)
    //////////////////////////////////////////////////////////////////////////////
    reg [2:0] fc_sel_q, fc_sel_q2;
    
    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            fc_sel_q2 <= 3'h0;
            fc_sel_q  <= 3'h0;
            fc_sel    <= 3'h0;
        end else begin
            fc_sel_q2 <= fc_sel_q;
            fc_sel_q  <= fc_sel;
            case (fc_sel)
                3'h0: fc_sel <= 3'h4; //3'h1;
                /*
                3'h1: fc_sel <= 3'h2;
                3'h2: fc_sel <= 3'h4;
                */
                3'h4: fc_sel <= 3'h5;
                3'h5: fc_sel <= 3'h6;
                3'h6: fc_sel <= 3'h4; //3'h0;
            endcase
        end
    end
    
    //----------------------------------------------------------------------------
    reg [11:0] fc_tx_npd, fc_tx_pd;
    reg [ 7:0] fc_tx_nph, fc_tx_ph;
    
    always @(posedge pcie_user_clk) begin
        if (pcie_user_rst) begin
            fc_tx_npd <= 12'h0;
            fc_tx_nph <=  8'h0;
            fc_tx_pd  <= 12'h0;
            fc_tx_ph  <=  8'h0;
        end else begin
            case (fc_sel_q2)
                3'h4: begin
                    fc_tx_npd <= fc_npd;
                    fc_tx_nph <= fc_nph;
                    fc_tx_pd  <= fc_pd;
                    fc_tx_ph  <= fc_ph;
                end
            endcase
        end
    end
endmodule
