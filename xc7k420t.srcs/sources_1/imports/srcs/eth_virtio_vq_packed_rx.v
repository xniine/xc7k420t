`timescale 1ns / 1ps

module eth_virtio_vq_packed_rx (
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

    output reg  [  4:0] s_axis_pkt_tmove,
    input  wire         s_axis_pkt_valid,
    input  wire [127:0] s_axis_pkt_tdata,
    input  wire [ 15:0] s_axis_pkt_tkeep,
    input  wire         s_axis_pkt_tlast
    );

    wire [127:0] vio_msix_tab = virtio_msix_tab;
    reg    vio_msix_pba;
    assign virtio_msix_pba = vio_msix_pba;

    //////////////////////////////////////////////////////////////////////////////
    // Rx Virtq
    //////////////////////////////////////////////////////////////////////////////

    localparam VIRQ_PTR_LENGTH = $clog2(256);

    function [4:0] vio_tkeep2n(input [15:0] tkeep);
        case (tkeep)
            16'h0000: vio_tkeep2n = 5'h00;
            16'h0001: vio_tkeep2n = 5'h01;
            16'h0003: vio_tkeep2n = 5'h02;
            16'h0007: vio_tkeep2n = 5'h03;
            16'h000F: vio_tkeep2n = 5'h04;
            16'h001F: vio_tkeep2n = 5'h05;
            16'h003F: vio_tkeep2n = 5'h06;
            16'h007F: vio_tkeep2n = 5'h07;
            16'h00FF: vio_tkeep2n = 5'h08;
            16'h01FF: vio_tkeep2n = 5'h09;
            16'h03FF: vio_tkeep2n = 5'h0A;
            16'h07FF: vio_tkeep2n = 5'h0B;
            16'h0FFF: vio_tkeep2n = 5'h0C;
            16'h1FFF: vio_tkeep2n = 5'h0D;
            16'h3FFF: vio_tkeep2n = 5'h0E;
            16'h7FFF: vio_tkeep2n = 5'h0F;
            16'hFFFF: vio_tkeep2n = 5'h10;
            default: begin
                vio_tkeep2n = 5'h10;
            end
        endcase
    endfunction

    //----------------------------------------------------------------------------
    localparam VIRQ_CHECK_VIRQ = 8'h0;
    localparam VIRQ_CHECK_DESC = 8'h1;
    localparam VIRQ_WRITE_INIT = 8'h2;
    localparam VIRQ_WRITE_DATA = 8'h3;
    localparam VIRQ_WRITE_SKIP = 8'h4;
    localparam VIRQ_WRITE_DROP = 8'h5;
    localparam VIRQ_WRITE_NEXT = 8'h6;
    localparam VIRQ_FETCH_DESC = 8'h7;
    localparam VIRQ_WRITE_USED = 8'h8;
    localparam VIRQ_WRITE_HEAD = 8'h9;
    localparam VIRQ_CHECK_TAIL = 8'hB;
    localparam VIRQ_FETCH_TAIL = 8'hC;
    localparam VIRQ_WRITE_INTR = 8'hD;

    reg  [  7:0] vio_int_stat;
    
    //----------------------------------------------------------------------------
    reg  [  4:0] s_axis_pkt_tmove_q; // -> packet pointer to shift with n x bytes
    wire [  4:0] s_axis_pkt_tkeep2n = s_axis_pkt_valid ? vio_tkeep2n(s_axis_pkt_tkeep) : 5'h0;
    
    //----------------------------------------------------------------------------
    reg  [ 63:0] vio_int_addr;
    reg  [ 31:0] vio_int_size;
    reg  [ 15:0] vio_int_indx;
    reg  [ 15:0] vio_int_flag;

    reg  [ 63:0] vio_int_desc;
    reg  [ 63:0] vio_int_evnt [1:0];
    reg  [ 15:0] vio_int_qlen; // Queue length
    reg  [ 15:0] vio_int_curr;
    reg  [ 15:0] vio_int_read;
    reg  [ 15:0] vio_int_head;
    reg          vio_int_notf;
    
    reg          vio_int_h_wp;
    reg  [ 15:0] vio_int_h_fl; // Header Flags
    reg  [ 15:0] vio_int_h_id;

    reg          vio_int_wrap;
    reg  [ 15:0] vio_int_hint;
    reg  [ 15:0] vio_int_next;
    
    reg  [ 31:0] vio_int_totl;
    reg  [ 31:0] vio_int_sent;
    reg  [ 15:0] vio_int_expt; // -> expected total tlp length
    reg          vio_int_cont;
    reg  [ 31:0] vio_int_rest;

    reg  [127:0] vio_int_msix;

    //----------------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            s_axis_pkt_tmove = 5'h10;
        end else begin
            s_axis_pkt_tmove = 5'h0;
            case (vio_int_stat)
                VIRQ_WRITE_INIT: begin
                    if (s_axis_pkt_valid) begin
                        if (vio_int_size >> 4) begin // rxq_size >= 16 
                            s_axis_pkt_tmove = 5'h10;
                        end else begin
                            s_axis_pkt_tmove = {vio_int_size[3:2],2'h0};
                        end
                    end
                end
                VIRQ_WRITE_DATA: begin
                    if (!tlp_wr_valid || tlp_wr_ready) begin
                        if (s_axis_pkt_valid && vio_int_sent[15:4] == vio_int_expt[15:4]) begin // packet has been sent
                            s_axis_pkt_tmove = vio_int_expt[3:2] ? {vio_int_expt[3:2],2'h0} : 5'h10;
                        end else
                        if (s_axis_pkt_valid) begin
                            s_axis_pkt_tmove = 5'h10;
                        end
                    end
                end
                VIRQ_WRITE_DROP: begin
                    s_axis_pkt_tmove = 5'h10;
                end
            endcase
        end
    end

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
            vio_int_qlen    <=  16'h0;
            vio_int_curr    <=  16'h0;
            vio_int_read    <=  16'h0;
            vio_int_head    <=  16'h0;
            vio_int_notf    <=   1'h0;
            
            vio_int_h_wp    <=   1'h0;
            vio_int_h_fl    <=  16'h0;
            vio_int_h_id    <=  16'h0;
            
            vio_int_wrap    <=   1'h1;
            vio_int_hint    <=  16'h0;
            vio_int_next    <=  16'h0;

            vio_int_totl    <=  32'h0;
            vio_int_sent    <=  32'h0;
            vio_int_expt    <=  16'h0;
            vio_int_cont    <=  16'h0;
            vio_int_rest    <=  32'h0;

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
                8'h1: begin // VIRQ_CHECK_DESC
                    if (tlp_rx_valid && tlp_rx_ready) begin
                        vio_int_msix <= virtio_msix_tab;
                        vio_int_addr <= tlp_rx_tdata[  0+:64];
                        vio_int_size <= tlp_rx_tdata[ 64+:32];
                        vio_int_indx <= tlp_rx_tdata[ 96+:16];
                        vio_int_flag <= tlp_rx_tdata[112+:16];
                        vio_int_rest <= tlp_rx_tdata[ 64+:32];
                        
                        if (tlp_rx_tdata[119+:1] != vio_int_wrap) begin // VIRTQ_DESC_F_AVAIL == False
                            if (vio_int_curr != vio_int_read) begin
                                vio_int_curr <= vio_int_read;
                                vio_int_stat <= VIRQ_WRITE_INTR;
                            end else begin
                                vio_int_stat <= VIRQ_CHECK_DESC;
                                tlp_rd_valid <= 1'h1;
                                tlp_rq_taddr <= virtq_desc + {vio_int_read,4'h0};
                                tlp_rq_tsize <= 16'h10;
                            end
                        end else begin
                            // VIRTQ_DESC_F_AVAIL == True
                            if (tlp_rx_tdata[113+:1]) begin // VIRTQ_DESC_F_WRITE == True
                                vio_int_stat <= VIRQ_WRITE_INIT;
                            end else begin
                                vio_int_stat <= VIRQ_WRITE_NEXT;
                            end
    
                            if (vio_int_head == vio_int_read) begin
                                vio_int_h_wp <= vio_int_wrap;
                                vio_int_h_fl <= tlp_rx_tdata[112+:16];
                                vio_int_h_id <= tlp_rx_tdata[ 96+:16];
                            end
                            //------------------------------------------------------
                            vio_int_curr <= vio_int_read;
                            if (vio_int_read + 1'h1 < vio_int_qlen) begin
                                vio_int_read <= vio_int_read + 1'h1;
                            end else begin
                                vio_int_read <= 8'h0;
                            end
                            //------------------------------------------------------
                            vio_int_next <= vio_int_next + 1'h1;
                            if (vio_int_hint <= vio_int_next) begin
                                vio_int_hint <= vio_int_next + 1'h1;
                            end
                        end
                    end
                end
                //----------------------------------------------------------------
                8'h2: begin // VIRQ_WRITE_INIT
                    if (s_axis_pkt_valid) begin
                        vio_int_stat <= vio_int_stat + 1'h1;
                        if (s_axis_pkt_tlast) begin
                            vio_int_stat <= VIRQ_WRITE_SKIP;
                        end

                        tlp_wr_valid <= 1'h1;
                        tlp_wr_tlast <= 1'h0;
                        tlp_wr_tdata <= s_axis_pkt_tdata;
                        tlp_rq_taddr <= vio_int_addr;

                        if ((vio_int_rest + 5'h10) >> VIRQ_PTR_LENGTH) begin
                            tlp_rq_tsize <= {1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10;
                            vio_int_expt <= {1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10;
                            vio_int_cont <= 1'h1;
                        end else begin
                            tlp_rq_tsize <= vio_int_rest;
                            vio_int_expt <= vio_int_rest;
                            vio_int_cont <= 1'h0;
                        end

                        if (vio_int_size == 32'h10 || !(vio_int_size >> 4)) begin
                            tlp_wr_tlast <= 1'h1;

                            if (s_axis_pkt_tlast) begin
                                vio_int_stat <= VIRQ_WRITE_USED;
                            end else
                            if (vio_int_flag[0+:1]) begin // VIRTQ_DESC_F_NEXT == True
                                vio_int_stat <= VIRQ_WRITE_NEXT;
                            end else begin
                                vio_int_stat <= VIRQ_WRITE_DROP;
                            end
                            vio_int_rest <= 32'h0;
                        end else begin
                            vio_int_rest <= vio_int_rest - 5'h10;
                        end

                        vio_int_totl <= vio_int_totl + s_axis_pkt_tkeep2n;
                        vio_int_sent <= 5'h10;
                    end
                end
                8'h3: begin // VIRQ_WRITE_DATA
                    if (!tlp_wr_valid || tlp_wr_ready) begin
                        if (s_axis_pkt_valid) begin
                            vio_int_totl <= vio_int_totl + s_axis_pkt_tkeep2n;
                            vio_int_rest <= vio_int_rest[31:5] ? vio_int_rest - 5'h10 : 32'h0;
                            vio_int_sent <= vio_int_sent + 5'h10;

                            tlp_wr_tdata <= s_axis_pkt_tdata;
                            tlp_wr_valid <= 1'h1;
                            tlp_wr_tlast <= 1'h0;

                            if (vio_int_sent[15:4] + 1'h1 == vio_int_expt[15:4] + |vio_int_expt[3:0]) begin
                                tlp_wr_tlast <= 1'h1;

                                case ({vio_int_flag[0:0],vio_int_cont,s_axis_pkt_tlast})
                                    3'b001, 3'b011, 3'b101, 3'b111: begin
                                        vio_int_stat <= VIRQ_WRITE_USED;
                                    end
                                    3'b100: begin
                                        vio_int_stat <= VIRQ_WRITE_NEXT;
                                    end
                                    3'b000: begin
                                        vio_int_totl <= vio_int_totl + vio_int_expt[3:0];
                                        vio_int_stat <= VIRQ_WRITE_DROP;
                                    end
                                endcase
                            end else
                            if (s_axis_pkt_tlast) begin
                                // packet sent, skip following with blank data
                                vio_int_stat <= VIRQ_WRITE_SKIP;
                            end
                        end else begin
                            tlp_wr_valid <= 1'h0;
                            tlp_wr_tlast <= 1'h0;
                        end
                        
                        if (tlp_wr_valid && tlp_wr_tlast) begin
                            tlp_rq_taddr <= tlp_rq_taddr + vio_int_sent;

                            if ((vio_int_rest + 5'h10) >> VIRQ_PTR_LENGTH) begin
                                tlp_rq_tsize <= {1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10;
                                vio_int_expt <= {1'h1,{VIRQ_PTR_LENGTH{1'h0}}} - 5'h10;
                                vio_int_cont <= 1'h1;
                            end else begin
                                tlp_rq_tsize <= vio_int_rest;
                                vio_int_expt <= vio_int_rest;
                                vio_int_cont <= 1'h0;
                            end
                            vio_int_sent <= 5'h10;
                        end
                    end
                end
                //----------------------------------------------------------------
                // Skip rest of inputs
                //----------------------------------------------------------------
                8'h4: begin // VIRQ_WRITE_SKIP
                    if (tlp_wr_valid && tlp_wr_ready) begin
                        tlp_wr_tdata <= 128'h0;

                        case (vio_int_expt[15:4] + |vio_int_expt[3:0] - vio_int_sent[15:4])
                            default: begin
                                vio_int_sent <= vio_int_sent + 5'h10;
                                tlp_wr_valid <= 1'h1;
                                tlp_wr_tlast <= 1'h0;
                            end
                            12'h1: begin
                                vio_int_sent <= vio_int_sent + 5'h10;
                                tlp_wr_valid <= 1'h1;
                                tlp_wr_tlast <= 1'h1;
                            end
                            12'h0: begin
                                vio_int_stat <= VIRQ_WRITE_USED;
                            end
                        endcase
                    end
                end
                8'h5: begin // VIRQ_WRITE_DROP
                    if (s_axis_pkt_valid && s_axis_pkt_tlast) begin
                        // tlp_wr_valid might be active here, but VIRQ_WRITE_USED will anyway handle this
                        // -> so we skip the tlp_wr_valid check here
                        vio_int_stat <= VIRQ_WRITE_USED;
                    end
                end
                //----------------------------------------------------------------
                // Find next available
                //----------------------------------------------------------------
                8'h6: begin // VIRQ_WRITE_NEXT
                    if (!tlp_wr_valid || tlp_wr_ready) begin
                        vio_int_stat <= vio_int_stat + 1'h1;
                        
                        if (vio_int_curr != vio_int_head) begin
                            tlp_wr_valid <= 1'h1;
                            tlp_wr_tlast <= 1'h1;
                            tlp_wr_tdata <= {vio_int_wrap,vio_int_flag[14:0],vio_int_h_id};
                            tlp_rq_taddr <= vio_int_desc + {vio_int_curr,4'hC};
                            tlp_rq_tsize <= 16'h8;
                        end
                    end
                end
                8'h7: begin // VIRQ_FETCH_DESC
                    if (!tlp_wr_valid || tlp_wr_ready) begin
                        vio_int_stat <= VIRQ_CHECK_DESC;
                        tlp_rd_valid <= 1'h1;
                        tlp_rq_taddr <= vio_int_desc + {vio_int_read,4'h0};
                        tlp_rq_tsize <= 16'h10;
                        //--------------------------------------------------------
                        vio_int_wrap <= vio_int_wrap ^ (vio_int_read < vio_int_curr);
                    end
                end
                //----------------------------------------------------------------
                // Write Used/Head
                //----------------------------------------------------------------
                8'h8: begin // VIRQ_WRITE_USED
                    if (!tlp_wr_valid || tlp_wr_ready) begin
                        if (vio_int_flag[0+:1]) begin // VIRTQ_DESC_F_NEXT == True
                            vio_int_stat <= VIRQ_CHECK_TAIL;
                            tlp_rd_valid <= 1'h1;
                            if (vio_int_qlen <= vio_int_head +  vio_int_hint) begin
                                tlp_rq_taddr <= vio_int_desc + {vio_int_head + vio_int_hint - vio_int_qlen,4'h0};
                                vio_int_read <= vio_int_head +  vio_int_hint - vio_int_qlen;
                            end else begin
                                tlp_rq_taddr <= vio_int_desc + {vio_int_head + vio_int_hint,4'h0};
                                vio_int_read <= vio_int_head +  vio_int_hint;
                            end
                            tlp_rq_tsize <= 16'h10;
                        end else
                        if (vio_int_curr != vio_int_head) begin
                            vio_int_stat <= vio_int_stat + 1'h1;
                            // Write Last Descriptors
                            tlp_wr_valid <= 1'h1;
                            tlp_wr_tlast <= 1'h1;
                            tlp_wr_tdata <= {vio_int_wrap,vio_int_flag[14:0],vio_int_h_id};
                            tlp_rq_taddr <= vio_int_desc + {vio_int_curr,4'hC};
                            tlp_rq_tsize <= 16'h4;
                        end else begin
                            vio_int_stat <= vio_int_stat + 1'h1;
                        end
                    end
                end
                8'h9: begin // VIRQ_WRITE_HEAD
                    if (!tlp_wr_valid || tlp_wr_ready) begin
                        vio_int_stat <= vio_int_stat + 1'h1;
                        // Write Header
                        tlp_wr_valid <= 1'h1;
                        tlp_wr_tlast <= 1'h1;
                        tlp_wr_tdata <= {vio_int_h_wp,vio_int_h_fl[14:0],vio_int_h_id,vio_int_totl};
                        tlp_rq_taddr <= vio_int_desc + {vio_int_head,4'h8};
                        tlp_rq_tsize <= 16'h8;
                    end
                end
                8'hA: begin
                    if (!tlp_wr_valid || tlp_wr_ready) begin
                        if (s_axis_pkt_valid) begin // Next packet available
                            vio_int_stat <= VIRQ_FETCH_DESC;
                        end else begin
                            vio_int_stat <= 8'hF; // VIRQ_WRITE_INTR
                            tlp_rd_valid <= 1'h1;
                            tlp_rq_taddr <= vio_int_desc + {vio_int_head,4'h8};
                            tlp_rq_tsize <= 16'h8;
                            //------------------------------------------------
                            vio_int_wrap <= vio_int_wrap ^ (vio_int_read < vio_int_curr);
                        end
                        //----------------------------------------------------
                        vio_int_head <= vio_int_read;
                        vio_int_next <= 16'h0;
                        //----------------------------------------------------
                        vio_int_totl <= 32'h0;
                        vio_int_sent <= 32'h0;
                        vio_int_expt <= 16'h0;
                        vio_int_cont <=  1'h0;
                    end
                end
                8'hF: begin
                    if (tlp_rx_valid && tlp_rx_ready) begin
                        vio_int_stat <= VIRQ_WRITE_INTR;
                    end
                end
                //----------------------------------------------------------------
                // VIRQ_CHECK_TAIL/VIRQ_FETCH_TAIL
                //----------------------------------------------------------------
                8'hB, 8'hC: begin
                    if (tlp_rx_valid && tlp_rx_ready) begin
                        // When 1) VIRTQ_DESC_F_NEXT == False, or, 2) Buffer ID != Head Buffer ID
                        if (tlp_rx_tdata[112+:1] || tlp_rx_tdata[96+:16] != vio_int_h_id) begin
                            vio_int_stat <= VIRQ_FETCH_TAIL;
                            //----------------------------------------------------
                            tlp_rq_tsize <= 16'h10;
                            tlp_rd_valid <= 1'h1;
                            //----------------------------------------------------
                            vio_int_next <= vio_int_next + 1'h1;
                            if (vio_int_qlen >  vio_int_head + vio_int_next) begin
                                tlp_rq_taddr <= vio_int_desc + {vio_int_head + vio_int_next,4'h0};
                                vio_int_read <= vio_int_head +  vio_int_next + 1'h1;
                                vio_int_next <= vio_int_next + 1'h1;
                            end else begin
                                tlp_rq_taddr <= vio_int_desc;
                                vio_int_read <= vio_int_head + 1'h1 - vio_int_qlen + vio_int_next;
                                vio_int_next <= vio_int_next + 1'h1 - vio_int_qlen;
                            end
                        end else begin
                            // Found the last descriptor in the list
                            vio_int_stat <= VIRQ_WRITE_HEAD;
                            if (vio_int_stat != VIRQ_CHECK_TAIL) begin
                                vio_int_hint <= vio_int_next - 1'h1;
                            end else begin
                                if (vio_int_read + 1'h1 < vio_int_qlen) begin
                                    vio_int_read <= vio_int_read + 1'h1;
                                end else begin
                                    vio_int_read <= vio_int_read + 1'h1 - vio_int_qlen;
                                end
                            end
                        end
                    end
                end
                //----------------------------------------------------------------
                // MSIx Interrput
                //----------------------------------------------------------------
                8'hD: begin // VIRQ_WRITE_INTR
                    if (vio_int_msix[96+:1] || !vio_int_msix[0+:64]) begin
                        // MSIx is not available, skip directly to next state
                        if (vio_int_curr != vio_int_read) begin
                            // Interrupt from VIRQ_WRITE_HEAD, because of no more packets
                            vio_int_stat <= VIRQ_CHECK_DESC;
                            tlp_rd_valid <= 1'h1;
                            tlp_rq_taddr <= vio_int_desc + {vio_int_read,4'h0};
                            tlp_rq_tsize <= 16'h10;
                        end else begin
                            // Interrput from VIRQ_CHECK_DESC, because no more descriptors
                            vio_int_stat <= VIRQ_CHECK_VIRQ;
                        end
                    end else begin
                        vio_int_stat <= vio_int_stat + 1'h1;
                        // MSIx Interrupt to Host side
                        tlp_wr_valid <= 1'h1;
                        tlp_wr_tlast <= 1'h1;
                        tlp_wr_tdata <= vio_int_msix[64+:32];
                        tlp_rq_taddr <= vio_int_msix[ 0+:64];
                        tlp_rq_tsize <= 16'h4;
                        
                        vio_msix_pba <= 1'h1;
                    end
                end
                8'hE: begin
                    if (tlp_wr_valid && tlp_wr_ready && tlp_wr_tlast) begin
                        vio_msix_pba <= 1'h0;
                        
                        if (vio_int_curr != vio_int_read) begin
                            // Interrupt from VIRQ_WRITE_HEAD, because of no more packets
                            vio_int_stat <= VIRQ_CHECK_DESC;
                            tlp_rd_valid <= 1'h1;
                            tlp_rq_taddr <= vio_int_desc + {vio_int_read,4'h0};
                            tlp_rq_tsize <= 16'h10;
                        end else begin
                            // Interrput from VIRQ_CHECK_DESC, because no more descriptors
                            vio_int_stat <= VIRQ_CHECK_VIRQ;
                        end
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
endmodule
 
