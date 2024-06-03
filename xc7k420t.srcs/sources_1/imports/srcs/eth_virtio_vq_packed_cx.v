`timescale 1ns / 1ps

module eth_virtio_vq_packed_cx (
    input  wire         clk,
    input  wire         rst,

    output wire         virtio_msix_pba,
    input  wire [127:0] virtio_msix_tab,

    input  wire [ 63:0] virtq_desc     ,
    input  wire [ 63:0] virtq_driver   ,
    input  wire [ 63:0] virtq_device   ,
    input  wire         virtq_notify_en,
    input  wire [ 31:0] virtq_notify   ,
    input  wire [ 15:0] virtq_size     ,
    input  wire [ 15:0] virtq_enable   ,

    output reg  [ 63:0] tlp_rq_taddr,
    output reg  [ 15:0] tlp_rq_tsize,

    output reg          tlp_wr_valid,
    input  wire         tlp_wr_ready,
    output reg          tlp_wr_tlast,
    output reg  [127:0] tlp_wr_tdata,

    output reg          tlp_rd_valid,
    input  wire         tlp_rd_ready,

    input  wire         tlp_rx_valid,
    output reg          tlp_rx_ready,
    input  wire         tlp_rx_tlast,
    input  wire [127:0] tlp_rx_tdata,
    input  wire [ 15:0] tlp_rx_tkeep,
    
    output reg          m_axis_ctl_valid,
    output wire [127:0] m_axis_ctl_tdata,
    output wire [ 15:0] m_axis_ctl_tkeep,
    output reg          m_axis_ctl_tlast
    );
 
    wire [127:0] vio_msix_tab = virtio_msix_tab;
    reg    vio_msix_pba;
    assign virtio_msix_pba = vio_msix_pba;

    //////////////////////////////////////////////////////////////////////////////
    // Cx Virtq
    //////////////////////////////////////////////////////////////////////////////

    localparam VIRQ_PTR_LENGTH = $clog2(256);

    //----------------------------------------------------------------------------
    localparam VIRQ_CHECK_VIRQ = 8'h0;
    localparam VIRQ_CHECK_DESC = 8'h1;
    localparam VIRQ_CHECK_DATA = 8'h2;
    localparam VIRQ_WRITE_STAT = 8'h3;
    localparam VIRQ_CHECK_AVAL = 8'h4;
    localparam VIRQ_WRITE_USED = 8'h5;
    localparam VIRQ_WRITE_HEAD = 8'h7;
    localparam VIRQ_WRITE_INTR = 8'h8;

    reg  [  7:0] vio_int_stat;

    //----------------------------------------------------------------------------
    reg  [ 63:0] vio_int_addr;
    reg  [ 31:0] vio_int_size;
    reg  [ 15:0] vio_int_indx;
    reg  [ 15:0] vio_int_flag;

    reg  [ 63:0] vio_int_desc;
    reg  [ 63:0] vio_int_evnt [1:0];
    reg  [ 15:0] vio_int_qlen; // Queue length

    reg          vio_int_wrap;
    reg          vio_int_h_wp;
    reg  [ 15:0] vio_int_h_fl; // Header Flags
    reg  [ 15:0] vio_int_h_id;
    reg  [ 15:0] vio_int_curr;
    reg  [ 15:0] vio_int_read;
    reg  [ 15:0] vio_int_head;

    reg          vio_int_notf;
    reg  [ 31:0] vio_int_totl;
    reg  [ 31:0] vio_int_sent;

    reg  [127:0] vio_int_msix;

    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            vio_int_stat    <=   8'h0;

            tlp_rd_valid    <=   1'h0;
            tlp_rx_ready    <=   1'h1;
            tlp_wr_valid    <=   1'h0;
            tlp_wr_tdata    <= 128'h0;
            tlp_wr_tlast    <=   1'h0;
            tlp_rq_taddr    <=  32'h0;
            tlp_rq_tsize    <=  16'h1;

            vio_int_addr    <=  64'h0;
            vio_int_size    <=  32'h0;
            vio_int_indx    <=  16'h0;
            vio_int_flag    <=  16'h0;

            vio_int_desc    <=  64'h0;
            vio_int_evnt[0] <=  64'h0;
            vio_int_evnt[1] <=  64'h0;
            vio_int_wrap    <=   1'h1;
            vio_int_h_wp    <=   1'h0;
            vio_int_h_fl    <=  16'h0;
            vio_int_h_id    <=  16'h0;

            vio_int_qlen    <=  16'h0;
            vio_int_curr    <=  16'h0;
            vio_int_read    <=  16'h0;
            vio_int_head    <=  16'h0;
            vio_int_notf    <=   1'h0;
            vio_int_totl    <=  32'h0;
            vio_int_sent    <=  32'h0;

            vio_msix_pba    <=   1'h0;
            vio_int_msix    <= 128'h0;
        end else begin
            tlp_rx_ready    <=   1'h1;

            if (tlp_wr_valid && tlp_wr_ready && tlp_wr_tlast) begin
                tlp_wr_valid <= 1'h0;
                tlp_wr_tlast <= 1'h0;
            end
            
            if (tlp_rd_valid && tlp_rd_ready) begin
                tlp_rd_valid <= 1'h0;
            end

            if (virtq_notify_en) begin
                vio_int_notf <= 1'h1;
            end

            case (vio_int_stat)
                //----------------------------------------------------------------
                // Read Virtq
                //----------------------------------------------------------------
                8'h0: begin
                    vio_int_evnt[0] <= 64'h0;
                    vio_int_evnt[1] <= 64'h0;

                    if (vio_int_notf) begin
                        vio_int_notf <= 1'h0;

                        vio_int_evnt[0] <= virtq_driver;
                        vio_int_evnt[1] <= virtq_device;
                        vio_int_desc    <= virtq_desc  ;
                        vio_int_qlen    <= virtq_size  ;

                        vio_int_stat <= VIRQ_CHECK_DESC;
                        tlp_rd_valid <= 1'h1;
                        tlp_rq_taddr <= virtq_desc + {vio_int_read,4'h0};
                        tlp_rq_tsize <= 16'h10;
                    end
                end
                //----------------------------------------------------------------
                // Check Descriptors
                //----------------------------------------------------------------
                8'h1: begin
                    if (tlp_rx_valid && tlp_rx_ready) begin
                        vio_int_addr <= tlp_rx_tdata[  0+:64];
                        vio_int_size <= tlp_rx_tdata[ 64+:32];
                        vio_int_indx <= tlp_rx_tdata[ 96+:16];
                        vio_int_flag <= tlp_rx_tdata[112+:16];
                        vio_int_msix <= virtio_msix_tab;

                        if (tlp_rx_tdata[119+:1] != vio_int_wrap) begin // VIRTQ_DESC_F_AVAIL == False
                            if (vio_int_curr != vio_int_read) begin
                                vio_int_stat <= VIRQ_WRITE_INTR;
                                vio_int_curr <= vio_int_read;
                            end else begin
                                vio_int_stat <= VIRQ_CHECK_VIRQ;
                            end
                        end else begin
                            // VIRTQ_DESC_F_AVAIL == True
                            if (tlp_rx_tdata[113+:1]) begin // VIRTQ_DESC_F_WRITE == True
                                vio_int_stat <= VIRQ_WRITE_STAT;
                                
                                tlp_wr_valid <= 1'h1;
                                tlp_wr_tlast <= 1'h1;
                                tlp_wr_tdata <= 64'h0;
                                tlp_rq_taddr <= tlp_rx_tdata[63:0];
                                tlp_rq_tsize <= 16'h1;
                            end else
                            if ((tlp_rx_tdata[64+:32] + 5'h10) >> VIRQ_PTR_LENGTH) begin
                                vio_int_stat <= VIRQ_CHECK_DATA;
                                
                                tlp_rd_valid <= 1'h1;
                                tlp_rq_taddr <= tlp_rx_tdata[ 0+:64];
                                tlp_rq_tsize <= {1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10;
                                vio_int_sent <= {1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10;
                            end else begin
                                vio_int_stat <= VIRQ_CHECK_DATA;
                                
                                tlp_rd_valid <= 1'h1;
                                tlp_rq_taddr <= tlp_rx_tdata[ 0+:64];
                                tlp_rq_tsize <= tlp_rx_tdata[64+:32];
                                vio_int_sent <= tlp_rx_tdata[64+:32];
                            end
    
                            if (vio_int_head == vio_int_read) begin
                                vio_int_h_wp <= vio_int_wrap;
                                vio_int_h_fl <= tlp_rx_tdata[112+:16];
                                vio_int_h_id <= tlp_rx_tdata[ 96+:16];
                            end
                            
                            vio_int_curr <= vio_int_read;
                            if (vio_int_read + 1'h1 != vio_int_qlen) begin
                                vio_int_read <= vio_int_read + 1'h1;
                            end else begin
                                vio_int_read <= 8'h0;
                            end
                        end
                    end
                end
                //----------------------------------------------------------------
                8'h2: begin // VIRQ_CHECK_DATA
                    if (tlp_rx_valid && tlp_rx_ready && tlp_rx_tlast) begin
                        if (vio_int_sent != vio_int_size) begin
                            tlp_rd_valid <= 1'h1;
                            tlp_rq_taddr <= vio_int_addr + vio_int_sent;
                            
                            if ((vio_int_size - vio_int_sent + 5'h10) >> VIRQ_PTR_LENGTH) begin
                                tlp_rq_tsize <= {1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10;
                                vio_int_sent <= vio_int_sent + ({1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10);
                            end else begin
                                tlp_rq_tsize <= vio_int_size - vio_int_sent;
                                vio_int_sent <= vio_int_size;
                            end
                        end else
                        if (vio_int_flag[0+:1] && vio_int_curr == vio_int_head) begin
                            // 1) VIRTQ_DESC_F_NEXT == True, 2) First Block in Group
                            vio_int_stat <= VIRQ_CHECK_AVAL;
                        end else begin
                            vio_int_stat <= VIRQ_WRITE_USED;
                        end
                    end
                end
                //----------------------------------------------------------------
                // Write State
                //----------------------------------------------------------------
                8'h3: begin // VIRQ_WRITE_STAT
                    if (tlp_wr_valid && tlp_wr_ready && tlp_wr_tlast) begin
                        vio_int_stat <= VIRQ_WRITE_USED;
                    end
                end
                //----------------------------------------------------------------
                // Find next available
                //----------------------------------------------------------------
                8'h4: begin // VIRQ_CHECK_AVAL
                    vio_int_stat <= VIRQ_CHECK_DESC;
                    tlp_rd_valid <= 1'h1;
                    tlp_rq_taddr <= vio_int_desc + {vio_int_read,4'h0};
                    tlp_rq_tsize <= 16'h10;
                    
                    if (!vio_int_read) begin
                        vio_int_wrap <= !vio_int_wrap;
                    end
                end
                //----------------------------------------------------------------
                // Write Head/Used
                //----------------------------------------------------------------
                8'h5: begin // VIRQ_WRITE_USED
                    vio_int_stat <= vio_int_stat + 1'h1;
                        
                    tlp_wr_valid <= 1'h1;
                    tlp_wr_tlast <= 1'h1;
                    tlp_wr_tdata <= {vio_int_wrap,vio_int_flag[14:0],vio_int_indx};
                    tlp_rq_taddr <= vio_int_desc + {vio_int_curr,4'hC};
                    tlp_rq_tsize <= 16'h4;
                end
                8'h6: begin
                    if (tlp_wr_valid && tlp_wr_ready && tlp_wr_tlast) begin
                        if (vio_int_flag[0+:1]) begin // VIRTQ_DESC_F_NEXT = True
                            vio_int_stat <= VIRQ_CHECK_AVAL;
                        end else
                        if (vio_int_curr == vio_int_head) begin
                            // 1) VIRTQ_DESC_F_NEXT == False, 2) First Block in Group
                            vio_int_stat <= VIRQ_CHECK_AVAL;
                            vio_int_head <= vio_int_read;
                        end else begin
                            vio_int_stat <= VIRQ_WRITE_HEAD;
                            
                            tlp_wr_valid <= 1'h1;
                            tlp_wr_tlast <= 1'h1;
                            tlp_wr_tdata <= {vio_int_h_wp,vio_int_h_fl[14:0],vio_int_h_id};
                            tlp_rq_taddr <= vio_int_desc + {vio_int_head,4'hC};
                            tlp_rq_tsize <= 16'h4;
                        end
                    end
                end
                //----------------------------------------------------------------
                8'h7: begin // VIRQ_WRITE_HEAD
                    if (tlp_wr_valid && tlp_wr_ready && tlp_wr_tlast) begin
                        vio_int_stat <= VIRQ_CHECK_AVAL;
                        vio_int_head <= vio_int_read;
                    end
                end
                //----------------------------------------------------------------
                // MSIx Interrput
                //----------------------------------------------------------------
                8'h8: begin // VIRQ_WRITE_INTR
                    if (vio_int_msix[96+:1] || !vio_int_msix[0+:64]) begin
                        vio_int_stat <= VIRQ_CHECK_VIRQ;
                    end else begin
                        vio_int_stat <= vio_int_stat + 1'h1;
                        // MSIx Interrupt to Host side
                        tlp_wr_valid <= 1'h1;
                        tlp_wr_tlast <= 1'h1;
                        tlp_wr_tdata <= vio_int_msix[64+:32];
                        tlp_rq_taddr <= vio_int_msix[ 0+:64];
                        tlp_rq_tsize <= 16'h4;
                    end
                end
                8'h9: begin
                    if (tlp_wr_valid && tlp_wr_ready && tlp_wr_tlast) begin
                        vio_msix_pba <= 1'h0;
                        vio_int_stat <= VIRQ_CHECK_VIRQ;
                    end
                end
                //----------------------------------------------------------------
                default: begin
                    if (!tlp_rd_valid || !tlp_wr_valid) begin
                        vio_int_stat <= VIRQ_CHECK_VIRQ;
                    end
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // Cx FIFO
    //////////////////////////////////////////////////////////////////////////////
    assign m_axis_ctl_tdata = vio_int_stat != VIRQ_WRITE_STAT ? tlp_rx_tdata : 128'h0;
    assign m_axis_ctl_tkeep = vio_int_stat != VIRQ_WRITE_STAT ? tlp_rx_tkeep :  16'h1;

    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst || vio_int_stat != VIRQ_CHECK_DESC) begin
            m_axis_ctl_tlast <= 1'h0;
        end else
        if (tlp_rx_valid && tlp_rx_ready && tlp_rx_tkeep[0+:16] == 16'hFFFF) begin
            m_axis_ctl_tlast <= tlp_rx_tdata[113+:1]; // VIRTQ_DESC_F_WRITE == True
        end else begin
            m_axis_ctl_tlast <= 1'h0;
        end
    end
    
    always @(*) begin
        if (rst) begin
            m_axis_ctl_valid = 1'h0;
        end else begin
            case (vio_int_stat)
                VIRQ_CHECK_DATA: m_axis_ctl_valid = tlp_rx_valid;
                VIRQ_WRITE_STAT: m_axis_ctl_valid = m_axis_ctl_tlast;
                default: m_axis_ctl_valid = 1'h0;
            endcase
        end
    end

endmodule

