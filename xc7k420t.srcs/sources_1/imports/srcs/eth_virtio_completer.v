`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09/14/2022 11:40:25 PM
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


module eth_virtio_completer #(
    parameter VQ_SPLIT = 1,
    parameter TXRX_CNT = 1,
    parameter VIRQ_CNT = 3,
    parameter MSIX_CNT = 4,
    parameter MSIX_TAB = 4 * 128
    ) (
    input  wire clk,
    input  wire rst,
    // Virtio MSIx Table
    output wire [MSIX_TAB-1:0] virtio_msix_tab,
    input  wire [MSIX_CNT-1:0] virtio_msix_pba,
    // Virtio ISR Status
    input  wire [ 31:0] virtio_isr_status,
    output reg          virtio_isr_reset,
    input  wire         virtio_interrupt,
    // Virtio Network Specific
    input  wire [ 15:0] virtio_net_status,
    input  wire [ 47:0] virtio_net_mac,
    input  wire [ 15:0] virtio_net_mtu,
    // Virtio Virtq Specific
    output wire [64*VIRQ_CNT-1:0] virtq_desc       ,
    output wire [64*VIRQ_CNT-1:0] virtq_driver     ,
    output wire [64*VIRQ_CNT-1:0] virtq_device     ,
    output wire [ 1*VIRQ_CNT-1:0] virtq_notify_en  ,
    output wire [32*VIRQ_CNT-1:0] virtq_notify     ,
    output wire [16*VIRQ_CNT-1:0] virtq_size       ,
    output wire [16*VIRQ_CNT-1:0] virtq_msix_vector,
    output wire [16*VIRQ_CNT-1:0] virtq_enable     ,
    // Virtio Reset Output
    output reg          virtio_reset ,
    // AXI
    input  wire [  7:0] s_axi_awid   ,
    input  wire [ 31:0] s_axi_awaddr ,
    input  wire [  7:0] s_axi_awlen  ,
    input  wire [  2:0] s_axi_awsize ,
    input  wire [  1:0] s_axi_awburst,
    input  wire         s_axi_awlock ,
    input  wire [  3:0] s_axi_awcache,
    input  wire [  2:0] s_axi_awprot ,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,// Fixed to 1

    input  wire [127:0] s_axi_wdata  ,
    input  wire [ 15:0] s_axi_wstrb  ,
    input  wire         s_axi_wlast  ,
    input  wire         s_axi_wvalid ,
    output wire         s_axi_wready ,

    output wire [  7:0] s_axi_bid    ,
    output wire [  1:0] s_axi_bresp  ,
    output wire         s_axi_bvalid ,
    input  wire         s_axi_bready ,

    input  wire [  7:0] s_axi_arid   ,
    input  wire [ 31:0] s_axi_araddr ,
    input  wire [  7:0] s_axi_arlen  ,
    input  wire [  2:0] s_axi_arsize ,
    input  wire [  1:0] s_axi_arburst,
    input  wire         s_axi_arlock ,
    input  wire [  3:0] s_axi_arcache,
    input  wire [  2:0] s_axi_arprot ,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,// Fixed to 1

    output reg  [  7:0] s_axi_rid    ,
    output reg  [127:0] s_axi_rdata  ,
    output reg  [  1:0] s_axi_rresp  ,
    output reg          s_axi_rlast  ,
    output reg          s_axi_rvalid ,
    input  wire         s_axi_rready
    );

    localparam PCI_BASE_ADDR_LENGTH = 14; // PCIe BAR Size = 2^14 = 16K

    assign s_axi_arready = 1'h1;
    assign s_axi_awready = 1'h1;
    assign s_axi_wready  = 1'h1;

    wire vio_rst = rst || virtio_reset;

    //============================================================================
    // AXI Address
    //============================================================================
    reg  [31:0] axi_int_araddr, axi_int_araddr_q;
    reg  [ 2:0] axi_int_arsize, axi_int_arsize_q;
    reg  [ 7:0] axi_int_arlen , axi_int_arlen_q ;
    wire        axi_int_aren;

    reg  [31:0] axi_int_awaddr, axi_int_awaddr_q;
    reg  [ 2:0] axi_int_awsize, axi_int_awsize_q;
    reg  [ 7:0] axi_int_awlen , axi_int_awlen_q ;
    wire        axi_int_awen;
    
    //----------------------------------------------------------------------------
    assign axi_int_aren = s_axi_arvalid && s_axi_arready || axi_int_arlen;

    always @(posedge clk) begin
        if (s_axi_rvalid && s_axi_rready) begin
            case (axi_int_arsize)
                3'h0: axi_int_araddr_q <= axi_int_araddr + 8'h01;
                3'h1: axi_int_araddr_q <= axi_int_araddr + 8'h02;
                3'h2: axi_int_araddr_q <= axi_int_araddr + 8'h04;
                3'h3: axi_int_araddr_q <= axi_int_araddr + 8'h08;
                3'h4: axi_int_araddr_q <= axi_int_araddr + 8'h10;
                3'h5: axi_int_araddr_q <= axi_int_araddr + 8'h20;
                3'h6: axi_int_araddr_q <= axi_int_araddr + 8'h40;
                3'h7: axi_int_araddr_q <= axi_int_araddr + 8'h80;
            endcase
            axi_int_arlen_q  <= axi_int_arlen ;
        end else begin
            axi_int_araddr_q <= axi_int_araddr;
            axi_int_arsize_q <= axi_int_arsize;
            axi_int_arlen_q  <= axi_int_arlen ;
        end
    end

    always @(*) begin
        if (vio_rst) begin
            axi_int_araddr = 32'h0;
            axi_int_arsize =  3'h0;
            axi_int_arlen  =  8'h0;
        end else
        if (s_axi_arvalid && s_axi_arready) begin
            axi_int_araddr = s_axi_araddr;
            axi_int_arsize = s_axi_arsize;
            axi_int_arlen  = s_axi_arlen ;
        end else begin
            axi_int_araddr = axi_int_araddr_q;
            axi_int_arsize = axi_int_arsize_q;
            axi_int_arlen  = axi_int_arlen_q ;

            if (axi_int_arlen_q) begin
                axi_int_arlen = axi_int_arlen_q - (s_axi_rvalid && s_axi_rready);
            end
        end
    end

    //----------------------------------------------------------------------------
    assign axi_int_awen = s_axi_awvalid && s_axi_awready || axi_int_awlen;

    always @(posedge clk) begin
        if (s_axi_wvalid && s_axi_wready) begin
            case (axi_int_awsize)
                3'h0: axi_int_awaddr_q <= axi_int_awaddr + 8'h01;
                3'h1: axi_int_awaddr_q <= axi_int_awaddr + 8'h02;
                3'h2: axi_int_awaddr_q <= axi_int_awaddr + 8'h04;
                3'h3: axi_int_awaddr_q <= axi_int_awaddr + 8'h08;
                3'h4: axi_int_awaddr_q <= axi_int_awaddr + 8'h10;
                3'h5: axi_int_awaddr_q <= axi_int_awaddr + 8'h20;
                3'h6: axi_int_awaddr_q <= axi_int_awaddr + 8'h40;
                3'h7: axi_int_awaddr_q <= axi_int_awaddr + 8'h80;
            endcase
            axi_int_awlen_q  <= axi_int_awlen ;
        end else begin
            axi_int_awaddr_q <= axi_int_awaddr;
            axi_int_awsize_q <= axi_int_awsize;
            axi_int_awlen_q  <= axi_int_awlen ;
        end
    end

    always @(*) begin
        if (vio_rst) begin
            axi_int_awaddr = 32'h0;
            axi_int_awsize =  3'h0;
            axi_int_awlen  =  8'h0;
        end else
        if (s_axi_awvalid && s_axi_awready) begin
            axi_int_awaddr = s_axi_awaddr;
            axi_int_awsize = s_axi_awsize;
            axi_int_awlen  = s_axi_awlen ;
        end else begin
            axi_int_awaddr = axi_int_awaddr_q;
            axi_int_awsize = axi_int_awsize_q;
            axi_int_awlen  = axi_int_awlen_q ;

            if (axi_int_awlen_q) begin
                axi_int_awlen = axi_int_awlen_q - (s_axi_wvalid && s_axi_wready);
            end
        end
    end

    //============================================================================
    // AXI Read/Resp Mux
    //============================================================================
    localparam MUX_TOTAL = 4;
    localparam MUX_WIDTH = $clog2(MUX_TOTAL);

    reg [MUX_TOTAL-1:0] axi_int_rvalid;
    reg [MUX_TOTAL-1:0] axi_int_rready;
    reg [        127:0] axi_int_rdata [MUX_TOTAL-1:0];

    integer i;
    always @(*) begin
        if (vio_rst || !axi_int_rvalid) begin
            s_axi_rvalid =   1'h0;
            s_axi_rdata  = 128'h0;
            s_axi_rlast  =   1'h0;
        end else begin
            s_axi_rvalid =   1'h0;
            s_axi_rlast  =   1'h0;
            s_axi_rdata  = 128'h0;
            for (i = 0; i < MUX_TOTAL; i = i + 1) begin
                if (axi_int_rvalid[i+:1]) begin
                    s_axi_rvalid = 1'h1;
                    s_axi_rdata  = axi_int_rdata[i];
                    axi_int_rready[i] = s_axi_rready;
                end
            end
            if (!axi_int_arlen) begin
                s_axi_rlast = 1'h1;
            end
        end
    end

    reg [MUX_TOTAL-1:0] axi_int_bvalid;
    assign s_axi_bvalid = |axi_int_bvalid;

    //////////////////////////////////////////////////////////////////////////////
    function match_addr(input [31:0] address, input integer index);
        match_addr = (address[12+:3] == index);
    endfunction
    
    //----------------------------------------------------------------------------
    function [31:0] axi_align_address(input [31:0] address, input [2:0] size);
        case (size)
            3'h0: axi_align_address =  address;
            3'h1: axi_align_address = {address[31:1],1'h0};
            3'h2: axi_align_address = {address[31:2],2'h0};
            3'h3: axi_align_address = {address[31:3],3'h0};
            3'h4: axi_align_address = {address[31:4],4'h0};
            3'h5: axi_align_address = {address[31:5],5'h0};
            3'h6: axi_align_address = {address[31:6],6'h0};
            3'h7: axi_align_address = {address[31:7],7'h0};
        endcase
    endfunction
    
    wire [31:0] vio_int_awaddr = axi_align_address(axi_int_awaddr, axi_int_awsize);
    
    //////////////////////////////////////////////////////////////////////////////
    localparam VIRQ_IDX = $clog2(VIRQ_CNT);
    localparam MSIX_IDX = $clog2(MSIX_CNT);
    
    //============================================================================
    // Data Streams (Common)
    //============================================================================
    localparam VIRQ_CFG = 0;

    reg  [31:0] vio_device_feature_select;
    wire [31:0] vio_device_feature [1:0];
    reg  [31:0] vio_driver_feature_select;
    reg  [31:0] vio_driver_feature [1:0];
    reg  [15:0] vio_msix_config;
    wire [15:0] vio_num_queues;
    reg  [ 7:0] vio_device_status;
    reg  [ 7:0] vio_config_generation;

    reg  [15:0] vio_queue_select;
    reg  [15:0] vio_queue_size       [VIRQ_CNT-1:0];
    reg  [15:0] vio_queue_msix_vector[VIRQ_CNT-1:0];
    reg  [15:0] vio_queue_enable     [VIRQ_CNT-1:0];
    wire [15:0] vio_queue_notify_off [VIRQ_CNT-1:0];
    reg  [63:0] vio_queue_desc       [VIRQ_CNT-1:0];
    reg  [63:0] vio_queue_driver     [VIRQ_CNT-1:0];
    reg  [63:0] vio_queue_device     [VIRQ_CNT-1:0];
    
    genvar n1;
    generate
    // VIRTIO_NET_F_MQ     (22)
    // VIRTIO_NET_F_CTRL_RX(18)
    // VIRTIO_NET_F_CTRL_VQ(17)
    // VIRTIO_NET_F_STATUS (16)
    // VIRTIO_NET_F_MAC    ( 5)
    // VIRTIO_NET_F_MTU    ( 3)
    assign vio_device_feature[0] = 32'h0047_0028;
    // VIRTIO_F_NOTIFICATION_DATA(38)
    // VIRTIO_F_RING_PACKED(34)
    // VIRTIO_F_ACCESS_PLATFORM(33)/VIRTIO_F_IOMMU_PLATFORM(33)
    // VIRTIO_F_VERSION_1(32)
    if (VQ_SPLIT) begin
        assign vio_device_feature[1] = 32'h0000_0043;
    end else begin
        assign vio_device_feature[1] = 32'h0000_0047;
    end
    
    for (n1 = 0; n1 < VIRQ_CNT; n1 = n1 + 1) begin
        assign vio_queue_notify_off[n1] = n1;
    end
    
    assign vio_num_queues = VIRQ_CNT;
    endgenerate
    
    //----------------------------------------------------------------------------
    // TLP Memory Read/Write (Common Configuration)
    //----------------------------------------------------------------------------
    wire [639:0] vio_cfg = {
        vio_queue_device     [vio_queue_select],            // 0x30
        vio_queue_driver     [vio_queue_select],            // 0x28
        vio_queue_desc       [vio_queue_select],            // 0x20
        vio_queue_notify_off [vio_queue_select],            // 0x1E
        vio_queue_enable     [vio_queue_select],            // 0x1C
        vio_queue_msix_vector[vio_queue_select],            // 0x1A
        vio_queue_size       [vio_queue_select],            // 0x18
        vio_queue_select,                                   // 0x16
        vio_config_generation,                              // 0x15
        vio_device_status,                                  // 0x14
        vio_num_queues,                                     // 0x12
        vio_msix_config,                                    // 0x10
        vio_driver_feature[vio_driver_feature_select[0:0]], // 0x0C
        vio_driver_feature_select,                          // 0x08
        vio_device_feature[vio_device_feature_select[0:0]], // 0x04
        vio_device_feature_select                           // 0x00
    };
    
    always @(posedge clk) begin
        if (vio_rst || !axi_int_aren) begin
            axi_int_rdata [VIRQ_CFG] <= 128'h0;
            axi_int_rvalid[VIRQ_CFG] <=   1'h0;
        end else
        if (match_addr(axi_int_araddr, VIRQ_CFG)) begin
            axi_int_rvalid[VIRQ_CFG] <= 1'h1;
            if (axi_int_araddr[11:7]) begin
                axi_int_rdata [VIRQ_CFG] <= 128'h0;
            end else begin
                case (axi_int_araddr[6:4])
                    3'h0, 3'h1, 3'h2, 3'h3, 3'h4: begin
                        axi_int_rdata[VIRQ_CFG] <= vio_cfg[{axi_int_araddr[7:4],7'h0}+:128];
                    end
                    default: begin
                        axi_int_rdata[VIRQ_CFG] <= 128'h0;
                    end
                endcase
            end
        end
    end
    
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (vio_rst) begin
            virtio_reset <= 1'h0;

            axi_int_bvalid[VIRQ_CFG]   <=  1'h0;

            vio_device_feature_select  <= 32'h0;
            vio_driver_feature_select  <= 32'h0;
            vio_msix_config            <= 16'h0;
            vio_device_status          <=  8'h0;
            vio_config_generation      <=  8'h0;
            vio_queue_select           <= 16'h0;
            
            vio_queue_size[VIRQ_CNT-1] <= 16'h4;
            for (i = 0; i < VIRQ_CNT-1; i = i + 1) begin
                vio_queue_size[i] <= 16'h40;
            end

            for (i = 0; i < VIRQ_CNT; i = i + 1) begin
                vio_driver_feature   [i] <= 32'h0;
                vio_queue_msix_vector[i] <= 16'h0;
                vio_queue_enable     [i] <= 16'h0;
                vio_queue_desc       [i] <= 64'h0;
                vio_queue_driver     [i] <= 64'h0;
                vio_queue_device     [i] <= 64'h0;
                vio_queue_size       [i] <= 16'h40;
            end
        end else
        if (s_axi_wvalid && match_addr(axi_int_awaddr, VIRQ_CFG)) begin
            axi_int_bvalid[VIRQ_CFG] <= 1'h1;
            
            for (i = 0; i < 16; i = i + 4) begin
                case ({vio_int_awaddr[11:2],2'h0} + i) // TLP Read/Write should be dword algined
                    12'h00: begin
                        if (s_axi_wstrb[i  ]) vio_device_feature_select[ 0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_device_feature_select[ 8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_device_feature_select[16+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_device_feature_select[24+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    // device_feature is ready-only
                    12'h08: begin
                        if (s_axi_wstrb[i  ]) vio_driver_feature_select[ 0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_driver_feature_select[ 8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_driver_feature_select[16+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_driver_feature_select[24+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h0C: begin
                        if (s_axi_wstrb[i  ]) vio_driver_feature[vio_device_feature_select][ 0+:8] <= s_axi_wdata[i   +:8];
                        if (s_axi_wstrb[i+1]) vio_driver_feature[vio_device_feature_select][ 8+:8] <= s_axi_wdata[i+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_driver_feature[vio_device_feature_select][16+:8] <= s_axi_wdata[i+16+:8];
                        if (s_axi_wstrb[i+3]) vio_driver_feature[vio_device_feature_select][24+:8] <= s_axi_wdata[i+24+:8];
                    end
                    12'h10: begin
                        if (s_axi_wstrb[i  ]) vio_msix_config[0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_msix_config[8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        // num_queues is ready-only
                    end
                    12'h14: begin
                        if (s_axi_wstrb[i]) begin
                            vio_device_status <= s_axi_wdata[i*8+:8];
                            if (s_axi_wdata[i*8+:8] == 8'h0) begin
                                virtio_reset <= 1'h1;
                            end
                        end
                        if (s_axi_wstrb[i+1]) vio_config_generation  <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_select[0+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_select[8+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h18: begin
                        if (s_axi_wstrb[i  ]) vio_queue_size       [vio_queue_select][0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_size       [vio_queue_select][8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_msix_vector[vio_queue_select][0+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_msix_vector[vio_queue_select][8+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h1C: begin
                        if (s_axi_wstrb[i  ]) vio_queue_enable[vio_queue_select][0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_enable[vio_queue_select][8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        // vio_queue_notify_off is read-only
                    end
                    12'h20: begin
                        if (s_axi_wstrb[i  ]) vio_queue_desc  [vio_queue_select][ 0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_desc  [vio_queue_select][ 8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_desc  [vio_queue_select][16+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_desc  [vio_queue_select][24+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h24: begin
                        if (s_axi_wstrb[i  ]) vio_queue_desc  [vio_queue_select][32+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_desc  [vio_queue_select][40+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_desc  [vio_queue_select][48+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_desc  [vio_queue_select][56+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h28: begin
                        if (s_axi_wstrb[i  ]) vio_queue_driver[vio_queue_select][ 0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_driver[vio_queue_select][ 8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_driver[vio_queue_select][16+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_driver[vio_queue_select][24+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h2C: begin
                        if (s_axi_wstrb[i  ]) vio_queue_driver[vio_queue_select][32+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_driver[vio_queue_select][40+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_driver[vio_queue_select][48+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_driver[vio_queue_select][56+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h30: begin
                        if (s_axi_wstrb[i  ]) vio_queue_device[vio_queue_select][ 0+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_device[vio_queue_select][ 8+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_device[vio_queue_select][16+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_device[vio_queue_select][24+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                    12'h34: begin
                        if (s_axi_wstrb[i  ]) vio_queue_device[vio_queue_select][32+:8] <= s_axi_wdata[i*8   +:8];
                        if (s_axi_wstrb[i+1]) vio_queue_device[vio_queue_select][40+:8] <= s_axi_wdata[i*8+ 8+:8];
                        if (s_axi_wstrb[i+2]) vio_queue_device[vio_queue_select][48+:8] <= s_axi_wdata[i*8+16+:8];
                        if (s_axi_wstrb[i+3]) vio_queue_device[vio_queue_select][56+:8] <= s_axi_wdata[i*8+24+:8];
                    end
                endcase
            end
        end else
        if (s_axi_bvalid && s_axi_bready) begin
            axi_int_bvalid[VIRQ_CFG] <= 1'h0;
        end
    end

    //============================================================================
    // Data Streams (ISR Status + MSIx Table)
    //============================================================================
    localparam VIRQ_ISR = 1;

    reg [ 31:0] vio_isr_status;
    
    function msix_tab_en(input [11:0] address);
        msix_tab_en = address[10+:2] == 2'b10 && !address[9:MSIX_IDX+4];
    endfunction
    
    function msix_pba_en(input [11:0] address);
        msix_pba_en = address[10+:2] == 2'b11 && !address[9:MSIX_IDX+4];
    endfunction
    
    function [11:0] msix_tab_idx(input [11:0] address);
        if (MSIX_CNT > 1) begin
            msix_tab_idx = address[MSIX_IDX+3:4];
        end else begin
            msix_tab_idx = 12'h0;
        end
    endfunction
    
    function [11:0] msix_pba_idx(input [11:0] address);
        if (MSIX_CNT > 1) begin
            msix_pba_idx = address[MSIX_IDX+4:4];
        end else begin
            msix_pba_idx = 12'h0;
        end
    endfunction
    
    //----------------------------------------------------------------------------
    reg [127:0] vio_msix_pba [(MSIX_CNT+127)/128-1:0];
    reg [127:0] vio_msix_tab [ MSIX_CNT-1:0];
    
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            vio_isr_status <= 32'h0;
        end else
        if (axi_int_aren && match_addr(axi_int_araddr, VIRQ_ISR)) begin
            if (axi_int_araddr[11:4] == 'h0) begin
                vio_isr_status <= 32'h0;
            end
        end else
        if (virtio_interrupt) begin
            vio_isr_status <= virtio_isr_status;
        end
    end
    
    //----------------------------------------------------------------------------
    genvar n2;
    generate
        for (n2 = 0; n2 < MSIX_CNT; n2 = n2 + 1) begin
            assign virtio_msix_tab[n2*128+:128] = vio_msix_tab[n2];
        end
    endgenerate
    
    //----------------------------------------------------------------------------
    // TLP Memory Read/Write
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        virtio_isr_reset <= 1'h0;
        if (rst || !axi_int_aren) begin
            axi_int_rvalid[VIRQ_ISR] <=   1'h0;
            axi_int_rdata [VIRQ_ISR] <= 128'h0;
        end else
        if (match_addr(axi_int_araddr, VIRQ_ISR)) begin
            axi_int_rvalid[VIRQ_ISR] <= 1'h1;
            if (msix_tab_en(axi_int_araddr)) begin
                axi_int_rdata[VIRQ_ISR] <= vio_msix_tab[msix_tab_idx(axi_int_araddr)];
            end else
            if (msix_pba_en(axi_int_araddr)) begin
                axi_int_rdata[VIRQ_ISR] <= vio_msix_pba[msix_pba_idx(axi_int_araddr)];
            end else
            if (axi_int_araddr[11:4]) begin
                axi_int_rdata[VIRQ_ISR] <= 128'h0;
            end else begin
                axi_int_rdata[VIRQ_ISR] <= vio_isr_status;
                virtio_isr_reset <= 1'h1;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            axi_int_bvalid[VIRQ_ISR] <= 1'h0;
        end else
        if (s_axi_wvalid && match_addr(axi_int_araddr, VIRQ_ISR)) begin
            axi_int_bvalid[VIRQ_ISR] <= 1'h1;
            if (msix_tab_en(axi_int_awaddr)) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (s_axi_wstrb[i]) vio_msix_tab[msix_tab_idx(axi_int_awaddr)][i*8+:8] <= s_axi_wdata[i*8+:8];
                end
            end
        end else
        if (s_axi_bvalid && s_axi_bready) begin
            axi_int_bvalid[VIRQ_ISR] <= 1'h0;
        end
    end

    //============================================================================
    // Data Streams (Virtio Device Specific Configurtion)
    //============================================================================
    localparam VIRQ_NET = 2;
    
    //----------------------------------------------------------------------------
    // Virtio Sepcific Logics
    //----------------------------------------------------------------------------
    function [47:0] mac_rev(input [47:0] mac);
        mac_rev = {mac[0+:8],mac[8+:8],mac[16+:8],mac[24+:8],mac[32+:8],mac[40+:8]};
    endfunction

    wire [47:0] vio_net_mac = mac_rev(virtio_net_mac);
    wire [15:0] vio_net_status = virtio_net_status;
    wire [15:0] vio_net_max_virtqueue_pairs = TXRX_CNT;
    wire [15:0] vio_net_mtu = virtio_net_mtu;

    //----------------------------------------------------------------------------
    // TLP Memory Read/Write
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (vio_rst || !axi_int_aren) begin
            axi_int_rvalid[VIRQ_NET] <= 1'h0;
            axi_int_rdata [VIRQ_NET] <= 128'h0;
        end else
        if (match_addr(axi_int_araddr, VIRQ_NET)) begin
            axi_int_rvalid[VIRQ_NET] <= 1'h1;
            if (s_axi_araddr[11:4]) begin
                axi_int_rdata[VIRQ_NET] <= 128'h0;
            end else begin
                axi_int_rdata[VIRQ_NET] <= {vio_net_mtu,vio_net_max_virtqueue_pairs,vio_net_status,vio_net_mac};
            end
        end
    end
    
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (vio_rst) begin
            axi_int_bvalid[VIRQ_NET] <= 1'h0;
        end else
        if (s_axi_wvalid && match_addr(axi_int_awaddr, VIRQ_NET)) begin
            axi_int_bvalid[VIRQ_NET] <= 1'h1;
        end else
        if (s_axi_bvalid && s_axi_bready) begin
            axi_int_bvalid[VIRQ_NET] <= 1'h0;
        end
    end
    
    //============================================================================
    // Data Streams (Notification)
    //============================================================================
    localparam VIRQ_NTF = 3;
    
    reg  [VIRQ_CNT+3:0] vio_notify_en;
    reg  [        31:0] vio_notify [VIRQ_CNT+3:0];
    
    wire [VIRQ_IDX-1:0] vio_notify_ra [3:0];
    
    assign vio_notify_ra[0] = axi_int_araddr[11:2];
    assign vio_notify_ra[1] = axi_int_araddr[11:2] + 2'h1;
    assign vio_notify_ra[2] = axi_int_araddr[11:2] + 2'h2;
    assign vio_notify_ra[3] = axi_int_araddr[11:2] + 2'h3;
    
    wire [VIRQ_IDX-1:0] vio_notify_wa [3:0];
    
    assign vio_notify_wa[0] = vio_int_awaddr[11:2];
    assign vio_notify_wa[1] = vio_int_awaddr[11:2] + 2'h1;
    assign vio_notify_wa[2] = vio_int_awaddr[11:2] + 2'h2;
    assign vio_notify_wa[3] = vio_int_awaddr[11:2] + 2'h3;
    
    wire [VIRQ_IDX-1:0] vio_notify_ma = VIRQ_CNT;
    
    //----------------------------------------------------------------------------
    // TLP Memory Read/Write
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst || !axi_int_aren) begin
            axi_int_rvalid[VIRQ_NTF] <=   1'h0;
            axi_int_rdata [VIRQ_NTF] <= 128'h0;
        end else
        if (match_addr(axi_int_araddr, VIRQ_NTF)) begin
            axi_int_rvalid[VIRQ_NTF] <= 1'h1;
            if (axi_int_araddr[11:2]) begin
                axi_int_rdata[VIRQ_NTF] <= 128'h0;
            end else begin
                axi_int_rdata[VIRQ_NTF] <= {
                    vio_notify[vio_notify_ra[0]],
                    vio_notify[vio_notify_ra[1]],
                    vio_notify[vio_notify_ra[2]],
                    vio_notify[vio_notify_ra[3]]
                };
            end
        end
    end
    
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        vio_notify_en <= {VIRQ_CNT{1'h0}};
        if (rst) begin
            axi_int_bvalid[VIRQ_NTF] <= 1'h0;
            for (i = 0; i < 4; i = i + 1) begin
                vio_notify[i] <= 32'h0;
            end
        end else
        if (s_axi_wvalid && match_addr(axi_int_awaddr, VIRQ_NTF)) begin
            axi_int_bvalid[VIRQ_NTF] <= 1'h1;
            
            if (vio_notify_wa[0] < vio_notify_ma) begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (s_axi_wstrb[  i*4]) vio_notify[vio_notify_wa[i]][0+:8] <= s_axi_wdata[   i*32+:8];
                    if (s_axi_wstrb[1+i*4]) vio_notify[vio_notify_wa[i]][0+:8] <= s_axi_wdata[ 8+i*32+:8];
                    if (s_axi_wstrb[2+i*4]) vio_notify[vio_notify_wa[i]][0+:8] <= s_axi_wdata[16+i*32+:8];
                    if (s_axi_wstrb[3+i*4]) vio_notify[vio_notify_wa[i]][0+:8] <= s_axi_wdata[24+i*32+:8];
                    vio_notify_en[vio_notify_wa[i]] <= |s_axi_wstrb[i*4+:4];
                end
            end
        end else
        if (s_axi_bvalid && s_axi_bready) begin
            axi_int_bvalid[VIRQ_NTF] <= 1'h0;
        end
    end
    
    //============================================================================
    // External Ports
    //============================================================================
    assign virtq_notify_en = vio_notify_en;
    
    //----------------------------------------------------------------------------
    genvar n3;
    generate
        for (n3 = 0; n3 < VIRQ_CNT; n3 = n3 + 1) begin
            assign virtq_desc       [n3*64+:64] = vio_queue_desc       [n3];
            assign virtq_driver     [n3*64+:64] = vio_queue_driver     [n3];
            assign virtq_device     [n3*64+:64] = vio_queue_device     [n3];
            assign virtq_notify     [n3*32+:32] = vio_notify           [n3];
            assign virtq_size       [n3*16+:16] = vio_queue_size       [n3];
            assign virtq_msix_vector[n3*16+:16] = vio_queue_msix_vector[n3];
            assign virtq_enable     [n3*16+:16] = vio_queue_enable     [n3];
        end                               
    endgenerate
    
endmodule
