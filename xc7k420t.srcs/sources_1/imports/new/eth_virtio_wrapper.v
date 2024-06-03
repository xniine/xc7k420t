`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2022 10:56:42 AM
// Design Name: 
// Module Name: eth_virtio_wrapper
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


module eth_virtio_wrapper #(
    parameter MSI_X_CAP = 1,
    parameter MSI_CAP = 0,
    
    parameter VQ_SPLIT = 0,
    parameter TX_FRAME_FIFO = 1,
    parameter RX_FRAME_FIFO = 1,
    parameter TX_DEPTH = 4096,
    parameter RX_DEPTH = 4096,
    parameter TXRX_CNT = 1,
    parameter VIRQ_CNT = TXRX_CNT + TXRX_CNT + 1,
    parameter MSIX_CNT = TXRX_CNT + TXRX_CNT + 1,
    parameter MSIX_TAB = MSIX_CNT * 128
    ) (
    input  wire         pcie_rst_n  ,
    input  wire         pcie_clk    ,
    
    output wire [  3:0] pcie_txp    ,
    output wire [  3:0] pcie_txn    ,
    input  wire [  3:0] pcie_rxp    ,
    input  wire [  3:0] pcie_rxn    ,
    
    output wire         virtio_ctl_cmd_en,
    output wire [  7:0] virtio_ctl_class ,
    output wire [  7:0] virtio_ctl_cmd   ,
    output wire         virtio_ctl_tvalid,
    input  wire         virtio_ctl_tready,
    output wire [127:0] virtio_ctl_tdata ,
    output wire [ 15:0] virtio_ctl_tkeep ,
    output wire         virtio_ctl_tlast ,
    
    output wire         virtio_reset, 
    input  wire [ 15:0] virtio_net_status,
    input  wire [ 47:0] virtio_net_mac,
    input  wire [ 15:0] virtio_net_mtu,
    
    output wire         user_clk,
    output wire         user_rst,
    output wire         user_lnk,
    output wire         user_rdy,
    
    input  wire [127:0] s_axis_tdata,
    input  wire [ 15:0] s_axis_tkeep,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    
    output wire [127:0] m_axis_tdata,
    output wire [ 15:0] m_axis_tkeep,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
    );
    
    //----------------------------------------------------------------------------
    // ETH Virtio               
    //----------------------------------------------------------------------------
    wire [  7:0] pcie_cq_axi_awid   ;
    wire [ 31:0] pcie_cq_axi_awaddr ;
    wire [  7:0] pcie_cq_axi_awlen  ;
    wire [  2:0] pcie_cq_axi_awsize ;
    wire [  1:0] pcie_cq_axi_awburst;
    wire         pcie_cq_axi_awlock ;
    wire [  3:0] pcie_cq_axi_awcache;
    wire [  2:0] pcie_cq_axi_awprot ;
    wire         pcie_cq_axi_awvalid;
    wire         pcie_cq_axi_awready;
    wire [127:0] pcie_cq_axi_wdata  ;
    wire [ 15:0] pcie_cq_axi_wstrb  ;
    wire         pcie_cq_axi_wlast  ;
    wire         pcie_cq_axi_wvalid ;
    wire         pcie_cq_axi_wready ;
    wire [  7:0] pcie_cq_axi_bid    ;
    wire [  1:0] pcie_cq_axi_bresp  ;
    wire         pcie_cq_axi_bvalid ;
    wire         pcie_cq_axi_bready ;
    wire [  7:0] pcie_cq_axi_arid   ;
    wire [ 31:0] pcie_cq_axi_araddr ;
    wire [  7:0] pcie_cq_axi_arlen  ;
    wire [  2:0] pcie_cq_axi_arsize ;
    wire [  1:0] pcie_cq_axi_arburst;
    wire         pcie_cq_axi_arlock ;
    wire [  3:0] pcie_cq_axi_arcache;
    wire [  2:0] pcie_cq_axi_arprot ;
    wire         pcie_cq_axi_arvalid;
    wire         pcie_cq_axi_arready;
    wire [  7:0] pcie_cq_axi_rid    ;
    wire [127:0] pcie_cq_axi_rdata  ;
    wire [  1:0] pcie_cq_axi_rresp  ;
    wire         pcie_cq_axi_rlast  ;
    wire         pcie_cq_axi_rvalid ;
    wire         pcie_cq_axi_rready ;
    
    //----------------------------------------------------------------------------
    // Virtio Reset Output
    // wire         virtio_reset     ;
    
    // Virtio Network Specific
    // wire [ 15:0] virtio_net_status = 1'h1; // VIRTIO_NET_S_LINK_UP(1)
    // wire [ 47:0] virtio_net_mac = 48'hEEEEEEEEEEEE;
    // wire [ 15:0] virtio_net_mtu = 16'h2048;
    
    // Virtio Virtq Specific
    wire [64*VIRQ_CNT-1:0] virtq_desc       ;
    wire [64*VIRQ_CNT-1:0] virtq_driver     ;
    wire [64*VIRQ_CNT-1:0] virtq_device     ;
    wire [ 1*VIRQ_CNT-1:0] virtq_notify_en  ;
    wire [32*VIRQ_CNT-1:0] virtq_notify     ;
    wire [16*VIRQ_CNT-1:0] virtq_size       ;
    wire [16*VIRQ_CNT-1:0] virtq_msix_vector;
    wire [16*VIRQ_CNT-1:0] virtq_enable     ;
    
    //----------------------------------------------------------------------------
    // For MSIx Table & PBA
    wire [MSIX_TAB-1:0] virtio_msix_tab;
    wire [MSIX_CNT-1:0] virtio_msix_pba;
    
    // Interrupt Handling
    wire         pci_interrupt;
    wire         pci_interrupt_rdy;
    wire         pci_interrupt_assert;
    
    reg  [ 31:0] virtio_isr_status;
    wire         virtio_isr_reset;
    wire         virtio_interrupt = 1'h0; // MSI is not enabled
    wire         virtio_interrupt_rdy;
    
    always @(posedge user_clk) begin
        if (user_rst || virtio_isr_reset) begin
            virtio_isr_status <= 32'h0;
        end else
        if (virtio_interrupt) begin
            virtio_isr_status <= 32'h1;
        end
    end
    
    assign pci_interrupt_assert = 1'h0; // INTx is not enabled
    assign pci_interrupt = virtio_interrupt;
    assign virtio_interrupt_rdy = pci_interrupt_rdy;
    
    //----------------------------------------------------------------------------
    eth_virtio_completer #(
        .VQ_SPLIT(VQ_SPLIT),
        .TXRX_CNT(TXRX_CNT),
        .VIRQ_CNT(VIRQ_CNT),
        .MSIX_CNT(MSIX_CNT),
        .MSIX_TAB(MSIX_TAB)
    ) eth_virtio_completer_inst (
        .clk                 (user_clk           ),
        .rst                 (user_rst           ),
        // MSIx Table & PB
        .virtio_msix_tab     (virtio_msix_tab    ),
        .virtio_msix_pba     (virtio_msix_pba    ),
        // Interrup
        .virtio_isr_status   (virtio_isr_status  ),
        .virtio_isr_reset    (virtio_isr_reset   ),
        .virtio_interrupt    (virtio_interrupt   ),
        // Virtio Network Specific
        .virtio_net_status   (virtio_net_status  ),
        .virtio_net_mac      (virtio_net_mac     ),
        .virtio_net_mtu      (virtio_net_mtu     ),
        // Virtio Virtq Specific
        .virtq_desc          (virtq_desc         ),
        .virtq_driver        (virtq_driver       ),
        .virtq_device        (virtq_device       ),
        .virtq_notify_en     (virtq_notify_en    ),
        .virtq_notify        (virtq_notify       ),
        .virtq_size          (virtq_size         ),
        .virtq_msix_vector   (virtq_msix_vector  ),
        .virtq_enable        (virtq_enable       ),
        // Virtio Reset Output
        .virtio_reset        (virtio_reset       ),
        // AXI
        .s_axi_awid          (pcie_cq_axi_awid   ),
        .s_axi_awaddr        (pcie_cq_axi_awaddr ),
        .s_axi_awlen         (pcie_cq_axi_awlen  ),
        .s_axi_awsize        (pcie_cq_axi_awsize ),
        .s_axi_awburst       (pcie_cq_axi_awburst),
        .s_axi_awlock        (pcie_cq_axi_awlock ),
        .s_axi_awcache       (pcie_cq_axi_awcache),
        .s_axi_awprot        (pcie_cq_axi_awprot ),
        .s_axi_awvalid       (pcie_cq_axi_awvalid),
        .s_axi_awready       (pcie_cq_axi_awready),
        .s_axi_wdata         (pcie_cq_axi_wdata  ),
        .s_axi_wstrb         (pcie_cq_axi_wstrb  ),
        .s_axi_wlast         (pcie_cq_axi_wlast  ),
        .s_axi_wvalid        (pcie_cq_axi_wvalid ),
        .s_axi_wready        (pcie_cq_axi_wready ),
        .s_axi_bid           (pcie_cq_axi_bid    ),
        .s_axi_bresp         (pcie_cq_axi_bresp  ),
        .s_axi_bvalid        (pcie_cq_axi_bvalid ),
        .s_axi_bready        (pcie_cq_axi_bready ),
        .s_axi_arid          (pcie_cq_axi_arid   ),
        .s_axi_araddr        (pcie_cq_axi_araddr ),
        .s_axi_arlen         (pcie_cq_axi_arlen  ),
        .s_axi_arsize        (pcie_cq_axi_arsize ),
        .s_axi_arburst       (pcie_cq_axi_arburst),
        .s_axi_arlock        (pcie_cq_axi_arlock ),
        .s_axi_arcache       (pcie_cq_axi_arcache),
        .s_axi_arprot        (pcie_cq_axi_arprot ),
        .s_axi_arvalid       (pcie_cq_axi_arvalid),
        .s_axi_arready       (pcie_cq_axi_arready),
        .s_axi_rid           (pcie_cq_axi_rid    ),
        .s_axi_rdata         (pcie_cq_axi_rdata  ),
        .s_axi_rresp         (pcie_cq_axi_rresp  ),
        .s_axi_rlast         (pcie_cq_axi_rlast  ),
        .s_axi_rvalid        (pcie_cq_axi_rvalid ),
        .s_axi_rready        (pcie_cq_axi_rready )
    );
    
    //----------------------------------------------------------------------------
    // Virtio VQ
    //----------------------------------------------------------------------------
    // AXI-S RQ
    wire         tlp_rq_ready       ;
    wire [127:0] tlp_rq_data        ;
    wire         tlp_rq_valid       ;
    wire         tlp_rq_start_flag  ;
    wire [  3:0] tlp_rq_start_offset;
    wire         tlp_rq_end_flag    ;
    wire [  3:0] tlp_rq_end_offset  ;
    // AXI-S RC                                          ;
    wire [127:0] tlp_rc_data        ;
    wire         tlp_rc_valid       ;
    wire         tlp_rc_start_flag  ;
    wire [  3:0] tlp_rc_start_offset;
    wire         tlp_rc_end_flag    ;
    wire [  3:0] tlp_rc_end_offset  ;
    wire         tlp_rc_ready       ;
    // PCIe Device Specific
    wire [  7:0] pci_bus_number;
    wire [  4:0] pci_device_number;
    wire [  2:0] pci_function_number;
    // Virtio PCIe Specific
    wire [ 15:0] virtio_pci_rid = {
        pci_bus_number     ,
        pci_device_number  ,
        pci_function_number
    };
    
    //----------------------------------------------------------------------------
    wire [8*VIRQ_CNT-1:0] virtio_pci_tag;
    genvar n1;
    generate
    for (n1 = 0; n1 < VIRQ_CNT; n1 = n1 + 1) begin
        assign virtio_pci_tag[8*n1+:8] = n1 + 1;
    end
    endgenerate
    
    //----------------------------------------------------------------------------
    eth_virtio_vq #(
        .VQ_SPLIT(VQ_SPLIT),
        .TX_FRAME_FIFO(TX_FRAME_FIFO),
        .RX_FRAME_FIFO(RX_FRAME_FIFO),
        .TX_DEPTH(TX_DEPTH),
        .RX_DEPTH(RX_DEPTH),
        .TXRX_CNT(TXRX_CNT),
        .VIRQ_CNT(VIRQ_CNT),
        .MSIX_CNT(MSIX_CNT),
        .MSIX_TAB(MSIX_TAB)
    ) eth_virtio_vq_inst (
        .clk                (user_clk           ),
        .rst                (user_rst || virtio_reset),
        // MSIx Table & PBA
        .virtio_msix_tab    (virtio_msix_tab    ),
        .virtio_msix_pba    (virtio_msix_pba    ),
        // Virtio PCIe Specific
        .virtio_pci_tag     (virtio_pci_tag     ),
        .virtio_pci_rid     (virtio_pci_rid     ),
        // Virtio Control VQ
        .virtio_ctl_cmd_en  (virtio_ctl_cmd_en  ),
        .virtio_ctl_class   (virtio_ctl_class   ),
        .virtio_ctl_cmd     (virtio_ctl_cmd     ),
        .virtio_ctl_tvalid  (virtio_ctl_tvalid  ),
        .virtio_ctl_tready  (virtio_ctl_tready  ),
        .virtio_ctl_tdata   (virtio_ctl_tdata   ),
        .virtio_ctl_tkeep   (virtio_ctl_tkeep   ),
        .virtio_ctl_tlast   (virtio_ctl_tlast   ),
        // Virtio Virtq Specific
        .virtq_desc         (virtq_desc         ),
        .virtq_driver       (virtq_driver       ),
        .virtq_device       (virtq_device       ),
        .virtq_notify_en    (virtq_notify_en    ),
        .virtq_notify       (virtq_notify       ),
        .virtq_size         (virtq_size         ),
        .virtq_msix_vector  (virtq_msix_vector  ),
        .virtq_enable       (virtq_enable       ),
        // AXI-S RQ
        .tlp_rq_ready       (tlp_rq_ready       ),
        .tlp_rq_data        (tlp_rq_data        ),
        .tlp_rq_valid       (tlp_rq_valid       ),
        .tlp_rq_start_flag  (tlp_rq_start_flag  ),
        .tlp_rq_start_offset(tlp_rq_start_offset),
        .tlp_rq_end_flag    (tlp_rq_end_flag    ),
        .tlp_rq_end_offset  (tlp_rq_end_offset  ),
        // AXI-S RC                                          ;
        .tlp_rc_data        (tlp_rc_data        ),
        .tlp_rc_valid       (tlp_rc_valid       ),
        .tlp_rc_start_flag  (tlp_rc_start_flag  ),
        .tlp_rc_start_offset(tlp_rc_start_offset),
        .tlp_rc_end_flag    (tlp_rc_end_flag    ),
        .tlp_rc_end_offset  (tlp_rc_end_offset  ),
        .tlp_rc_ready       (tlp_rc_ready       ),
        // Input
        .s_axis_tdata       (s_axis_tdata       ),
        .s_axis_tkeep       (s_axis_tkeep       ),
        .s_axis_tvalid      (s_axis_tvalid      ),
        .s_axis_tready      (s_axis_tready      ),
        .s_axis_tlast       (s_axis_tlast       ),
        // Output
        .m_axis_tdata       (m_axis_tdata       ),
        .m_axis_tkeep       (m_axis_tkeep       ),
        .m_axis_tvalid      (m_axis_tvalid      ),
        .m_axis_tready      (m_axis_tready      ),
        .m_axis_tlast       (m_axis_tlast       )
    );
    
    //----------------------------------------------------------------------------
    // wire user_clk;
    // wire user_rst;
    // wire user_lnk;
    // wire user_rdy;
    
    pcie_axi_wrapper #(
        .MSI_X_CAP(MSI_X_CAP),
        .MSI_CAP(MSI_CAP)
    ) pcie_axi_wrapper_inst(
        .sys_rst_n           (pcie_rst_n          ),
        .sys_clk             (pcie_clk            ),

        // PCIe Interface
        .pci_exp_txp         (pcie_txp            ),
        .pci_exp_txn         (pcie_txn            ),
        .pci_exp_rxp         (pcie_rxp            ),
        .pci_exp_rxn         (pcie_rxn            ),
        
        // PCIe Interrupt
        .cfg_interrupt       (pci_interrupt       ),
        .cfg_interrupt_rdy   (pci_interrupt_rdy   ),
        .cfg_interrupt_assert(pci_interrupt_assert),
        .cfg_interrupt_di    (8'h0                ),
        // PCIe Device Specific
        .cfg_bus_number      (pci_bus_number      ),
        .cfg_device_number   (pci_device_number   ),
        .cfg_function_number (pci_function_number ),
        // PCIe Rx/Tx Common
        .user_clk_out        (user_clk            ),
        .user_reset_out      (user_rst            ),
        .user_lnk_up         (user_lnk            ),
        .user_app_rdy        (user_rdy            ),
        // AXI-S RQ
        .tlp_rq_ready        (tlp_rq_ready        ),
        .tlp_rq_data         (tlp_rq_data         ),
        .tlp_rq_valid        (tlp_rq_valid        ),
        .tlp_rq_start_flag   (tlp_rq_start_flag   ),
        .tlp_rq_start_offset (tlp_rq_start_offset ),
        .tlp_rq_end_flag     (tlp_rq_end_flag     ),
        .tlp_rq_end_offset   (tlp_rq_end_offset   ),
        // AXI-S RC                                            ;
        .tlp_rc_data         (tlp_rc_data         ),
        .tlp_rc_valid        (tlp_rc_valid        ),
        .tlp_rc_start_flag   (tlp_rc_start_flag   ),
        .tlp_rc_start_offset (tlp_rc_start_offset ),
        .tlp_rc_end_flag     (tlp_rc_end_flag     ),
        .tlp_rc_end_offset   (tlp_rc_end_offset   ),
        .tlp_rc_ready        (tlp_rc_ready        ),
        // AXI
        .m_axi_awid          (pcie_cq_axi_awid    ),
        .m_axi_awaddr        (pcie_cq_axi_awaddr  ),
        .m_axi_awlen         (pcie_cq_axi_awlen   ),
        .m_axi_awsize        (pcie_cq_axi_awsize  ),
        .m_axi_awburst       (pcie_cq_axi_awburst ),
        .m_axi_awlock        (pcie_cq_axi_awlock  ),
        .m_axi_awcache       (pcie_cq_axi_awcache ),
        .m_axi_awprot        (pcie_cq_axi_awprot  ),
        .m_axi_awvalid       (pcie_cq_axi_awvalid ),
        .m_axi_awready       (pcie_cq_axi_awready ),
        .m_axi_wdata         (pcie_cq_axi_wdata   ),
        .m_axi_wstrb         (pcie_cq_axi_wstrb   ),
        .m_axi_wlast         (pcie_cq_axi_wlast   ),
        .m_axi_wvalid        (pcie_cq_axi_wvalid  ),
        .m_axi_wready        (pcie_cq_axi_wready  ),
        .m_axi_bid           (pcie_cq_axi_bid     ),
        .m_axi_bresp         (pcie_cq_axi_bresp   ),
        .m_axi_bvalid        (pcie_cq_axi_bvalid  ),
        .m_axi_bready        (pcie_cq_axi_bready  ),
        .m_axi_arid          (pcie_cq_axi_arid    ),
        .m_axi_araddr        (pcie_cq_axi_araddr  ),
        .m_axi_arlen         (pcie_cq_axi_arlen   ),
        .m_axi_arsize        (pcie_cq_axi_arsize  ),
        .m_axi_arburst       (pcie_cq_axi_arburst ),
        .m_axi_arlock        (pcie_cq_axi_arlock  ),
        .m_axi_arcache       (pcie_cq_axi_arcache ),
        .m_axi_arprot        (pcie_cq_axi_arprot  ),
        .m_axi_arvalid       (pcie_cq_axi_arvalid ),
        .m_axi_arready       (pcie_cq_axi_arready ),
        .m_axi_rid           (pcie_cq_axi_rid     ),
        .m_axi_rdata         (pcie_cq_axi_rdata   ),
        .m_axi_rresp         (pcie_cq_axi_rresp   ),
        .m_axi_rlast         (pcie_cq_axi_rlast   ),
        .m_axi_rvalid        (pcie_cq_axi_rvalid  ),
        .m_axi_rready        (pcie_cq_axi_rready  )
    );
    
endmodule
