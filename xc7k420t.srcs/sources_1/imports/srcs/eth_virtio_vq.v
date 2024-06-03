`timescale 1ns / 1ps

module eth_virtio_vq #(
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
    input wire clk,
    input wire rst,
    // Virtio MSIx Table
    input  wire [MSIX_TAB-1:0] virtio_msix_tab,
    output reg  [MSIX_CNT-1:0] virtio_msix_pba,
    // AXI-S RQ
    output wire [127:0] tlp_rq_data        ,
    output wire         tlp_rq_valid       ,
    output wire         tlp_rq_start_flag  ,
    output wire [  3:0] tlp_rq_start_offset,
    output wire         tlp_rq_end_flag    ,
    output wire [  3:0] tlp_rq_end_offset  ,
    input  wire         tlp_rq_ready       ,
    // AXI-S RC
    input  wire [127:0] tlp_rc_data        ,
    input  wire         tlp_rc_valid       ,
    input  wire         tlp_rc_start_flag  ,
    input  wire [  3:0] tlp_rc_start_offset,
    input  wire         tlp_rc_end_flag    ,
    input  wire [  3:0] tlp_rc_end_offset  ,
    output wire         tlp_rc_ready       ,
    // Virtio Virtq Specific
    input  wire [64*VIRQ_CNT-1:0] virtq_desc       ,
    input  wire [64*VIRQ_CNT-1:0] virtq_driver     ,
    input  wire [64*VIRQ_CNT-1:0] virtq_device     ,
    input  wire [ 1*VIRQ_CNT-1:0] virtq_notify_en  ,
    input  wire [32*VIRQ_CNT-1:0] virtq_notify     ,
    input  wire [16*VIRQ_CNT-1:0] virtq_size       ,
    input  wire [16*VIRQ_CNT-1:0] virtq_msix_vector,
    input  wire [16*VIRQ_CNT-1:0] virtq_enable     ,
    // Virtio PCIe Specific
    input  wire [ 8*VIRQ_CNT-1:0] virtio_pci_tag   ,
    input  wire [           15:0] virtio_pci_rid   ,
    // Control
	output wire         virtio_ctl_cmd_en,
    output wire [  7:0] virtio_ctl_class ,
    output wire [  7:0] virtio_ctl_cmd   ,
    output wire         virtio_ctl_tvalid,
    input  wire         virtio_ctl_tready,
    output wire [127:0] virtio_ctl_tdata ,
    output wire [ 15:0] virtio_ctl_tkeep ,
    output wire         virtio_ctl_tlast ,
    // Input
    input  wire [127:0] s_axis_tdata     ,
    input  wire [ 15:0] s_axis_tkeep     ,
    input  wire         s_axis_tvalid    ,
    output wire         s_axis_tready    ,
    input  wire         s_axis_tlast     ,
    // Ouput
    output wire [127:0] m_axis_tdata     ,
    output wire [ 15:0] m_axis_tkeep     ,
    output wire         m_axis_tvalid    ,
    input  wire         m_axis_tready    ,
    output wire         m_axis_tlast
    );

    //////////////////////////////////////////////////////////////////////////////
    // TLP RQ/RC Signals
    //////////////////////////////////////////////////////////////////////////////
    wire [ 64*VIRQ_CNT-1:0] tlp_rq_taddr;
    wire [ 16*VIRQ_CNT-1:0] tlp_rq_tsize;

    wire [    VIRQ_CNT-1:0] tlp_wr_valid;
    wire [    VIRQ_CNT-1:0] tlp_wr_ready;
    wire [    VIRQ_CNT-1:0] tlp_wr_tlast;
    wire [128*VIRQ_CNT-1:0] tlp_wr_tdata;
 
    wire [    VIRQ_CNT-1:0] tlp_rd_valid;
    wire [    VIRQ_CNT-1:0] tlp_rd_ready;

    wire [    VIRQ_CNT-1:0] tlp_rx_valid;
    wire [    VIRQ_CNT-1:0] tlp_rx_ready;
    wire [    VIRQ_CNT-1:0] tlp_rx_tlast;

    wire [           127:0] tlp_rx_tdata;
    wire [            15:0] tlp_rx_tkeep;
 
    //////////////////////////////////////////////////////////////////////////////
    // TLP Request to Root Complex
    //////////////////////////////////////////////////////////////////////////////
    eth_virtio_tlp_rq #(
        .MUX_CNT(VIRQ_CNT)        
    )
    eth_virtio_tlp_rq_inst (
        .clk(clk),
        .rst(rst),

        .tlp_rq_data        (tlp_rq_data        ),
        .tlp_rq_valid       (tlp_rq_valid       ),
        .tlp_rq_start_flag  (tlp_rq_start_flag  ),
        .tlp_rq_start_offset(tlp_rq_start_offset),
        .tlp_rq_end_flag    (tlp_rq_end_flag    ),
        .tlp_rq_end_offset  (tlp_rq_end_offset  ),
        .tlp_rq_ready       (tlp_rq_ready       ),

        .virtio_pci_tag     (virtio_pci_tag     ),
        .virtio_pci_rid     (virtio_pci_rid     ),
  
        .tlp_rq_taddr       (tlp_rq_taddr       ),
        .tlp_rq_tsize       (tlp_rq_tsize       ),

        .tlp_rd_valid       (tlp_rd_valid       ),
        .tlp_rd_ready       (tlp_rd_ready       ),

        .tlp_wr_valid       (tlp_wr_valid       ),
        .tlp_wr_ready       (tlp_wr_ready       ),
        .tlp_wr_tlast       (tlp_wr_tlast       ),
        .tlp_wr_tdata       (tlp_wr_tdata       )
    );
    
    //////////////////////////////////////////////////////////////////////////////
    // TLP Complete from Root Complex
    //////////////////////////////////////////////////////////////////////////////
    eth_virtio_tlp_rc #(
        .MUX_CNT(VIRQ_CNT)
    )
    eth_virtio_tlp_rc_inst (
        .clk(clk),
        .rst(rst),

        .tlp_rc_data        (tlp_rc_data        ),
        .tlp_rc_valid       (tlp_rc_valid       ),
        .tlp_rc_start_flag  (tlp_rc_start_flag  ),
        .tlp_rc_start_offset(tlp_rc_start_offset),
        .tlp_rc_end_flag    (tlp_rc_end_flag    ),
        .tlp_rc_end_offset  (tlp_rc_end_offset  ),
        .tlp_rc_ready       (tlp_rc_ready       ),

        .virtio_pci_tag     (virtio_pci_tag     ),

        .tlp_rx_valid       (tlp_rx_valid       ),
        .tlp_rx_ready       (tlp_rx_ready       ),
        .tlp_rx_tlast       (tlp_rx_tlast       ),
        .tlp_rx_tdata       (tlp_rx_tdata       ),
        .tlp_rx_tkeep       (tlp_rx_tkeep       )
    );

    //////////////////////////////////////////////////////////////////////////////
    // MSIX PBA
    //////////////////////////////////////////////////////////////////////////////
    wire [VIRQ_CNT-1:0] vio_msix_pba;
    integer i;
    always @(*) begin
        if (rst) begin
            virtio_msix_pba = {MSIX_CNT{1'h0}};
        end else begin
            virtio_msix_pba = {MSIX_CNT{1'h0}};
            for (i = 0; i < VIRQ_CNT; i = i + 1) begin
                virtio_msix_pba[virtq_msix_vector[16*i+:16]+:1] = vio_msix_pba[i];
            end
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // Rx Virtq
    //////////////////////////////////////////////////////////////////////////////
    wire [128*TXRX_CNT-1:0] s_axis_int_tdata ;
    wire [ 16*TXRX_CNT-1:0] s_axis_int_tkeep ;
    wire [  1*TXRX_CNT-1:0] s_axis_int_tvalid;
    wire [  1*TXRX_CNT-1:0] s_axis_int_tready;
    wire [  1*TXRX_CNT-1:0] s_axis_int_tlast ;

    //----------------------------------------------------------------------------
    genvar n1;
    generate
    for (n1 = 0; n1 < TXRX_CNT + TXRX_CNT; n1 = n1 + 2) begin

    wire [  4:0] s_axis_pkt_tmove;
    wire         s_axis_pkt_valid;
    wire [127:0] s_axis_pkt_tdata;
    wire [ 15:0] s_axis_pkt_tkeep;
    wire         s_axis_pkt_tlast;

    wire [ 15:0] vio_msix_vid = virtq_msix_vector[16*n1+:16];
    wire [127:0] vio_msix_tab = ~vio_msix_vid ? virtio_msix_tab[{vio_msix_vid,7'h0}+:128] : 128'h0;

    /*if (VQ_SPLIT) begin
        eth_virtio_vq_split_rx 
        eth_virtio_vq_split_rx_inst
        (
            .clk(clk),
            .rst(rst),

            .virtio_msix_pba (vio_msix_pba[n1+:1]),
            .virtio_msix_tab (vio_msix_tab),

            .virtq_desc      (virtq_desc     [64*n1+:64]),
            .virtq_driver    (virtq_driver   [64*n1+:64]),
            .virtq_device    (virtq_device   [64*n1+:64]),
            .virtq_notify_en (virtq_notify_en[ 1*n1+: 1]),
            .virtq_notify    (virtq_notify   [32*n1+:32]),
            .virtq_size      (virtq_size     [16*n1+:16]),
            .virtq_enable    (virtq_enable   [16*n1+:16]),
 
            .tlp_rq_taddr    (tlp_rq_taddr[ 64*n1+: 64]),
            .tlp_rq_tsize    (tlp_rq_tsize[ 16*n1+: 16]),
            .tlp_wr_valid    (tlp_wr_valid[  1*n1+:  1]),
            .tlp_wr_ready    (tlp_wr_ready[  1*n1+:  1]),
            .tlp_wr_tlast    (tlp_wr_tlast[  1*n1+:  1]),
            .tlp_wr_tdata    (tlp_wr_tdata[128*n1+:128]),
            .tlp_rd_valid    (tlp_rd_valid[  1*n1+:  1]),
            .tlp_rd_ready    (tlp_rd_ready[  1*n1+:  1]),
            .tlp_rx_valid    (tlp_rx_valid[  1*n1+:  1]),
            .tlp_rx_ready    (tlp_rx_ready[  1*n1+:  1]),
            .tlp_rx_tlast    (tlp_rx_tlast[  1*n1+:  1]),
            .tlp_rx_tdata    (tlp_rx_tdata),
            .tlp_rx_tkeep    (tlp_rx_tkeep),

            .s_axis_pkt_tmove(s_axis_pkt_tmove),
            .s_axis_pkt_tdata(s_axis_pkt_tdata),
            .s_axis_pkt_tkeep(s_axis_pkt_tkeep),
            .s_axis_pkt_valid(s_axis_pkt_valid),
            .s_axis_pkt_tlast(s_axis_pkt_tlast)
        );
    end else begin*/
        eth_virtio_vq_packed_rx 
        eth_virtio_vq_packed_rx_inst
        (
            .clk(clk),
            .rst(rst),

            .virtio_msix_pba (vio_msix_pba[n1+:1]),
            .virtio_msix_tab (vio_msix_tab),

            .virtq_desc      (virtq_desc     [64*n1+:64]),
            .virtq_driver    (virtq_driver   [64*n1+:64]),
            .virtq_device    (virtq_device   [64*n1+:64]),
            .virtq_notify_en (virtq_notify_en[ 1*n1+: 1]),
            .virtq_notify    (virtq_notify   [32*n1+:32]),
            .virtq_size      (virtq_size     [16*n1+:16]),
            .virtq_enable    (virtq_enable   [16*n1+:16]),

            .tlp_rq_taddr    (tlp_rq_taddr[ 64*n1+: 64]),
            .tlp_rq_tsize    (tlp_rq_tsize[ 16*n1+: 16]),
            .tlp_wr_valid    (tlp_wr_valid[  1*n1+:  1]),
            .tlp_wr_ready    (tlp_wr_ready[  1*n1+:  1]),
            .tlp_wr_tlast    (tlp_wr_tlast[  1*n1+:  1]),
            .tlp_wr_tdata    (tlp_wr_tdata[128*n1+:128]),
            .tlp_rd_valid    (tlp_rd_valid[  1*n1+:  1]),
            .tlp_rd_ready    (tlp_rd_ready[  1*n1+:  1]),
            .tlp_rx_valid    (tlp_rx_valid[  1*n1+:  1]),
            .tlp_rx_ready    (tlp_rx_ready[  1*n1+:  1]),
            .tlp_rx_tlast    (tlp_rx_tlast[  1*n1+:  1]),
            .tlp_rx_tdata    (tlp_rx_tdata),
            .tlp_rx_tkeep    (tlp_rx_tkeep),

            .s_axis_pkt_tmove(s_axis_pkt_tmove),
            .s_axis_pkt_tdata(s_axis_pkt_tdata),
            .s_axis_pkt_tkeep(s_axis_pkt_tkeep),
            .s_axis_pkt_valid(s_axis_pkt_valid),
            .s_axis_pkt_tlast(s_axis_pkt_tlast)
        );
    //end
    
    //----------------------------------------------------------------------------
    eth_virtio_pkt_rx # (
        .FRAME_FIFO(RX_FRAME_FIFO),
        .DEPTH(RX_DEPTH)
    )
    eth_virtio_pkt_rx_inst (
        .clk(clk),
        .rst(rst),

        .m_axis_tdata (s_axis_pkt_tdata),
        .m_axis_tkeep (s_axis_pkt_tkeep),
        .m_axis_tvalid(s_axis_pkt_valid),
        .m_axis_tmove (s_axis_pkt_tmove),
        .m_axis_tlast (s_axis_pkt_tlast),

        .s_axis_tdata (s_axis_int_tdata [128*(n1/2)+:128]),
        .s_axis_tkeep (s_axis_int_tkeep [ 16*(n1/2)+: 16]),
        .s_axis_tvalid(s_axis_int_tvalid[  1*(n1/2)+:  1]),
        .s_axis_tready(s_axis_int_tready[  1*(n1/2)+:  1]),
        .s_axis_tlast (s_axis_int_tlast [  1*(n1/2)+:  1])
    );

    //----------------------------------------------------------------------------
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////
    // Tx Virtq
    //////////////////////////////////////////////////////////////////////////////
    wire [128*TXRX_CNT-1:0] m_axis_int_tdata ;
    wire [ 16*TXRX_CNT-1:0] m_axis_int_tkeep ;
    wire [    TXRX_CNT-1:0] m_axis_int_tvalid;
    wire [    TXRX_CNT-1:0] m_axis_int_tready;
    wire [    TXRX_CNT-1:0] m_axis_int_tlast ;

    //----------------------------------------------------------------------------
    genvar n2;
    generate
    for (n2 = 1; n2 < TXRX_CNT + TXRX_CNT; n2 = n2 + 2) begin

    wire         m_axis_pkt_valid;
    wire [127:0] m_axis_pkt_tdata;
    wire [ 15:0] m_axis_pkt_tkeep;
    wire         m_axis_pkt_tlast;

    wire [ 15:0] vio_msix_vid = virtq_msix_vector[16*n2+:16];
    wire [127:0] vio_msix_tab = ~vio_msix_vid ? virtio_msix_tab[{vio_msix_vid,7'h0}+:128] : 128'h0;

    /*if (VQ_SPLIT) begin
        eth_virtio_vq_split_tx 
        eth_virtio_vq_split_tx_inst
        (
            .clk(clk),
            .rst(rst),

            .virtio_msix_pba (vio_msix_pba[n2+:1]),
            .virtio_msix_tab (vio_msix_tab),
 
            .virtq_desc      (virtq_desc     [64*n2+:64]),
            .virtq_driver    (virtq_driver   [64*n2+:64]),
            .virtq_device    (virtq_device   [64*n2+:64]),
            .virtq_notify_en (virtq_notify_en[ 1*n2+: 1]),
            .virtq_notify    (virtq_notify   [32*n2+:32]),
            .virtq_size      (virtq_size     [16*n2+:16]),
            .virtq_enable    (virtq_enable   [16*n2+:16]),

            .tlp_rq_taddr    (tlp_rq_taddr[ 64*n2+: 64]),
            .tlp_rq_tsize    (tlp_rq_tsize[ 16*n2+: 16]),
            .tlp_wr_valid    (tlp_wr_valid[  1*n2+:  1]),
            .tlp_wr_ready    (tlp_wr_ready[  1*n2+:  1]),
            .tlp_wr_tlast    (tlp_wr_tlast[  1*n2+:  1]),
            .tlp_wr_tdata    (tlp_wr_tdata[128*n2+:128]),
            .tlp_rd_valid    (tlp_rd_valid[  1*n2+:  1]),
            .tlp_rd_ready    (tlp_rd_ready[  1*n2+:  1]),
            .tlp_rx_valid    (tlp_rx_valid[  1*n2+:  1]),
            .tlp_rx_ready    (tlp_rx_ready[  1*n2+:  1]),
            .tlp_rx_tlast    (tlp_rx_tlast[  1*n2+:  1]),
            .tlp_rx_tdata    (tlp_rx_tdata),
            .tlp_rx_tkeep    (tlp_rx_tkeep),

            .m_axis_pkt_valid(m_axis_pkt_valid),
            .m_axis_pkt_tdata(m_axis_pkt_tdata),
            .m_axis_pkt_tkeep(m_axis_pkt_tkeep),
            .m_axis_pkt_tlast(m_axis_pkt_tlast)
        );
    end else begin*/
        eth_virtio_vq_packed_tx 
        eth_virtio_vq_packed_tx_inst
        (
            .clk(clk),
            .rst(rst),

            .virtio_msix_pba (vio_msix_pba[n2+:1]),
            .virtio_msix_tab (vio_msix_tab),
 
            .virtq_desc      (virtq_desc     [64*n2+:64]),
            .virtq_driver    (virtq_driver   [64*n2+:64]),
            .virtq_device    (virtq_device   [64*n2+:64]),
            .virtq_notify_en (virtq_notify_en[ 1*n2+: 1]),
            .virtq_notify    (virtq_notify   [32*n2+:32]),
            .virtq_size      (virtq_size     [16*n2+:16]),
            .virtq_enable    (virtq_enable   [16*n2+:16]),

            .tlp_rq_taddr    (tlp_rq_taddr[ 64*n2+: 64]),
            .tlp_rq_tsize    (tlp_rq_tsize[ 16*n2+: 16]),
            .tlp_wr_valid    (tlp_wr_valid[  1*n2+:  1]),
            .tlp_wr_ready    (tlp_wr_ready[  1*n2+:  1]),
            .tlp_wr_tlast    (tlp_wr_tlast[  1*n2+:  1]),
            .tlp_wr_tdata    (tlp_wr_tdata[128*n2+:128]),
            .tlp_rd_valid    (tlp_rd_valid[  1*n2+:  1]),
            .tlp_rd_ready    (tlp_rd_ready[  1*n2+:  1]),
            .tlp_rx_valid    (tlp_rx_valid[  1*n2+:  1]),
            .tlp_rx_ready    (tlp_rx_ready[  1*n2+:  1]),
            .tlp_rx_tlast    (tlp_rx_tlast[  1*n2+:  1]),
            .tlp_rx_tdata    (tlp_rx_tdata),
            .tlp_rx_tkeep    (tlp_rx_tkeep),

            .m_axis_pkt_valid(m_axis_pkt_valid),
            .m_axis_pkt_tdata(m_axis_pkt_tdata),
            .m_axis_pkt_tkeep(m_axis_pkt_tkeep),
            .m_axis_pkt_tlast(m_axis_pkt_tlast)
        );
    //end

    //----------------------------------------------------------------------------
    eth_virtio_pkt_tx # (
        .FRAME_FIFO(TX_FRAME_FIFO),
        .DEPTH(TX_DEPTH)
    ) eth_virtio_pkt_tx_inst(
        .clk(clk),
        .rst(rst),

        .s_axis_tdata (m_axis_pkt_tdata),
        .s_axis_tkeep (m_axis_pkt_tkeep),
        .s_axis_tvalid(m_axis_pkt_valid),
        .s_axis_tlast (m_axis_pkt_tlast),

        .m_axis_tdata (m_axis_int_tdata [128*(n2/2)+:128]),
        .m_axis_tkeep (m_axis_int_tkeep [ 16*(n2/2)+: 16]),
        .m_axis_tvalid(m_axis_int_tvalid[  1*(n2/2)+:  1]),
        .m_axis_tready(m_axis_int_tready[  1*(n2/2)+:  1]),
        .m_axis_tlast (m_axis_int_tlast [  1*(n2/2)+:  1])
    );

    //----------------------------------------------------------------------------
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////
    // Cx Virtq
    //////////////////////////////////////////////////////////////////////////////
    wire         m_axis_ctl_valid;
    wire [127:0] m_axis_ctl_tdata;
    wire [ 15:0] m_axis_ctl_tkeep;
    wire         m_axis_ctl_tlast;
    
    wire [ 15:0] vio_msix_vid = virtq_msix_vector[16*VIRQ_CNT-1-:16];
    wire [127:0] vio_msix_tab = ~vio_msix_vid ? virtio_msix_tab[{vio_msix_vid,7'h0}+:128] : 128'h0;
    
    /*generate
    if (VQ_SPLIT) begin
        eth_virtio_vq_split_cx 
        eth_virtio_vq_split_cx_inst
        (
            .clk(clk),
            .rst(rst),

            .virtio_msix_pba (vio_msix_pba[VIRQ_CNT-1+:1]),
            .virtio_msix_tab (vio_msix_tab),

            .virtq_desc      (virtq_desc     [64*(VIRQ_CNT-1)+:64]),
            .virtq_driver    (virtq_driver   [64*(VIRQ_CNT-1)+:64]),
            .virtq_device    (virtq_device   [64*(VIRQ_CNT-1)+:64]),
            .virtq_notify_en (virtq_notify_en[ 1*(VIRQ_CNT-1)+: 1]),
            .virtq_notify    (virtq_notify   [32*(VIRQ_CNT-1)+:32]),
            .virtq_size      (virtq_size     [16*(VIRQ_CNT-1)+:16]),
            .virtq_enable    (virtq_enable   [16*(VIRQ_CNT-1)+:16]),

            .tlp_rq_taddr    (tlp_rq_taddr[ 64*(VIRQ_CNT-1)+: 64]),
            .tlp_rq_tsize    (tlp_rq_tsize[ 16*(VIRQ_CNT-1)+: 16]),
            .tlp_wr_valid    (tlp_wr_valid[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_wr_ready    (tlp_wr_ready[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_wr_tlast    (tlp_wr_tlast[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_wr_tdata    (tlp_wr_tdata[128*(VIRQ_CNT-1)+:128]),
            .tlp_rd_valid    (tlp_rd_valid[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rd_ready    (tlp_rd_ready[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_valid    (tlp_rx_valid[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_ready    (tlp_rx_ready[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_tlast    (tlp_rx_tlast[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_tdata    (tlp_rx_tdata),
            .tlp_rx_tkeep    (tlp_rx_tkeep),
            
            .m_axis_ctl_valid(m_axis_ctl_valid),
            .m_axis_ctl_tdata(m_axis_ctl_tdata),
            .m_axis_ctl_tkeep(m_axis_ctl_tkeep),
            .m_axis_ctl_tlast(m_axis_ctl_tlast)
        );
    end else begin*/
        eth_virtio_vq_packed_cx 
        eth_virtio_vq_packed_cx_inst
        (
            .clk(clk),
            .rst(rst),

            .virtio_msix_pba (vio_msix_pba[VIRQ_CNT-1+:1]),
            .virtio_msix_tab (vio_msix_tab),

            .virtq_desc      (virtq_desc     [64*(VIRQ_CNT-1)+:64]),
            .virtq_driver    (virtq_driver   [64*(VIRQ_CNT-1)+:64]),
            .virtq_device    (virtq_device   [64*(VIRQ_CNT-1)+:64]),
            .virtq_notify_en (virtq_notify_en[ 1*(VIRQ_CNT-1)+: 1]),
            .virtq_notify    (virtq_notify   [32*(VIRQ_CNT-1)+:32]),
            .virtq_size      (virtq_size     [16*(VIRQ_CNT-1)+:16]),
            .virtq_enable    (virtq_enable   [16*(VIRQ_CNT-1)+:16]),

            .tlp_rq_taddr    (tlp_rq_taddr[ 64*(VIRQ_CNT-1)+: 64]),
            .tlp_rq_tsize    (tlp_rq_tsize[ 16*(VIRQ_CNT-1)+: 16]),
            .tlp_wr_valid    (tlp_wr_valid[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_wr_ready    (tlp_wr_ready[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_wr_tlast    (tlp_wr_tlast[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_wr_tdata    (tlp_wr_tdata[128*(VIRQ_CNT-1)+:128]),
            .tlp_rd_valid    (tlp_rd_valid[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rd_ready    (tlp_rd_ready[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_valid    (tlp_rx_valid[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_ready    (tlp_rx_ready[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_tlast    (tlp_rx_tlast[  1*(VIRQ_CNT-1)+:  1]),
            .tlp_rx_tdata    (tlp_rx_tdata),
            .tlp_rx_tkeep    (tlp_rx_tkeep),
            
            .m_axis_ctl_valid(m_axis_ctl_valid),
            .m_axis_ctl_tdata(m_axis_ctl_tdata),
            .m_axis_ctl_tkeep(m_axis_ctl_tkeep),
            .m_axis_ctl_tlast(m_axis_ctl_tlast)
        );
    /*end
    endgenerate*/
 
    //----------------------------------------------------------------------------
    eth_virtio_cmd_rx # (
        .DEPTH(TX_DEPTH)
    ) eth_virtio_cmd_rx_inst(
        .clk(clk),
        .rst(rst),

        .s_axis_tdata (m_axis_ctl_tdata ),
        .s_axis_tkeep (m_axis_ctl_tkeep ),
        .s_axis_tvalid(m_axis_ctl_valid ),
        .s_axis_tlast (m_axis_ctl_tlast ),

        .m_axis_cmd_en(virtio_ctl_cmd_en),
        .m_axis_class (virtio_ctl_class ),
        .m_axis_cmd   (virtio_ctl_cmd   ),
        
        .m_axis_tvalid(virtio_ctl_tvalid),
        .m_axis_tready(virtio_ctl_tready),
        .m_axis_tdata (virtio_ctl_tdata ),
        .m_axis_tkeep (virtio_ctl_tkeep ),
        .m_axis_tlast (virtio_ctl_tlast )
    );
    
    //----------------------------------------------------------------------------
    reg [15:0] virtio_ctl_pairs;
    always @(posedge clk) begin
        if (rst) begin
            virtio_ctl_pairs <= 16'h1;
        end else
        if (virtio_ctl_cmd_en) begin
            case ({virtio_ctl_class,virtio_ctl_cmd})
                16'h0400: begin
                    if (virtio_ctl_tvalid && virtio_ctl_tready && |virtio_ctl_tkeep[3:0]) begin
                        virtio_ctl_pairs <= virtio_ctl_tdata[16+:16];
                    end
                end
            endcase
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // Rx Demux
    //////////////////////////////////////////////////////////////////////////////
    generate
    if (TXRX_CNT <= 1) begin
        assign s_axis_tready = s_axis_int_tready;
        assign s_axis_int_tdata  = s_axis_tdata ;
        assign s_axis_int_tkeep  = s_axis_tkeep ;
        assign s_axis_int_tlast  = s_axis_tlast ;
        assign s_axis_int_tvalid = s_axis_tvalid;
    end else begin
    //----------------------------------------------------------------------------
    
    reg [$clog2(TXRX_CNT)-1:0] s_axis_int_select;
    always @(posedge clk) begin
        if (rst) begin
            s_axis_int_select <= 8'h0;
        end else
        if (s_axis_tvalid && s_axis_tlast && s_axis_tready) begin
            if (s_axis_int_select + 1'h1 == virtio_ctl_pairs) begin
                s_axis_int_select <= 8'h0;
            end else
            if (s_axis_int_select == TXRX_CNT-1) begin
                s_axis_int_select <= 8'h0;
            end else begin
                s_axis_int_select <= s_axis_int_select + 1'h1;
            end
        end
    end

    axis_demux #(
        .M_COUNT     (TXRX_CNT),
        .DATA_WIDTH  (128),
        .ID_ENABLE   (0),
        .DEST_ENABLE (0),
        .USER_ENABLE (0)
    ) axis_arb_demux_inst(
        .clk(clk),
        .rst(rst),

        .m_axis_tdata (s_axis_int_tdata ),
        .m_axis_tkeep (s_axis_int_tkeep ),
        .m_axis_tlast (s_axis_int_tlast ),
        .m_axis_tready(s_axis_int_tready),
        .m_axis_tvalid(s_axis_int_tvalid),
  
        .s_axis_tdata (s_axis_tdata ),
        .s_axis_tkeep (s_axis_tkeep ),
        .s_axis_tlast (s_axis_tlast ),
        .s_axis_tready(s_axis_tready),
        .s_axis_tvalid(s_axis_tvalid),
                                                                                           
        .drop         (1'b0             ),                                                                                      
        .enable       (1'b1             ),                                                                                      
        .select       (s_axis_int_select)   
    );

    //----------------------------------------------------------------------------
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////
    // Tx Mux
    //////////////////////////////////////////////////////////////////////////////
    generate
    if (TXRX_CNT <= 1) begin
        assign m_axis_int_tready = m_axis_tready;
        assign m_axis_tdata  = m_axis_int_tdata ;
        assign m_axis_tkeep  = m_axis_int_tkeep ;
        assign m_axis_tlast  = m_axis_int_tlast ;
        assign m_axis_tvalid = m_axis_int_tvalid;
    end else begin
    //----------------------------------------------------------------------------
    axis_arb_mux#(
        .S_COUNT     (TXRX_CNT),
        .DATA_WIDTH  (128),
        .ID_ENABLE   (0),
        .DEST_ENABLE (0),
        .USER_ENABLE (0)/*,
        .ARB_TYPE_ROUND_ROBIN(1),
        .ARB_LSB_HIGH_PRIORITY(1)*/
    ) axis_arb_mux_inst(
        .clk(clk),
        .rst(rst),
 
        .s_axis_tdata (m_axis_int_tdata ),
        .s_axis_tkeep (m_axis_int_tkeep ),
        .s_axis_tlast (m_axis_int_tlast ),
        .s_axis_tready(m_axis_int_tready),
        .s_axis_tvalid(m_axis_int_tvalid),

        .m_axis_tdata (m_axis_tdata     ),
        .m_axis_tkeep (m_axis_tkeep     ),
        .m_axis_tlast (m_axis_tlast     ),
        .m_axis_tready(m_axis_tready    ),
        .m_axis_tvalid(m_axis_tvalid    )
    );
    //----------------------------------------------------------------------------
    end
    endgenerate

endmodule

