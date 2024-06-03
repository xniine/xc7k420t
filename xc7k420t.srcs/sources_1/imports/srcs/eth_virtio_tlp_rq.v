`timescale 1ns / 1ps

module eth_virtio_tlp_rq #(
    parameter MUX_CNT = 4
    ) (
    input  wire clk,
    input  wire rst,

    output reg  [127:0] tlp_rq_data        ,
    output reg          tlp_rq_valid       ,
    output reg          tlp_rq_start_flag  ,
    output reg  [  3:0] tlp_rq_start_offset,
    output reg          tlp_rq_end_flag    ,
    output reg  [  3:0] tlp_rq_end_offset  ,
    input  wire         tlp_rq_ready       ,

    input  wire [  8*MUX_CNT-1:0] virtio_pci_tag,
    input  wire [           15:0] virtio_pci_rid,
 
    input  wire [ 64*MUX_CNT-1:0] tlp_rq_taddr,
    input  wire [ 16*MUX_CNT-1:0] tlp_rq_tsize,

    input  wire [    MUX_CNT-1:0] tlp_rd_valid,
    output reg  [    MUX_CNT-1:0] tlp_rd_ready,

    input  wire [    MUX_CNT-1:0] tlp_wr_valid,
    output reg  [    MUX_CNT-1:0] tlp_wr_ready,
    input  wire [    MUX_CNT-1:0] tlp_wr_tlast,
    input  wire [128*MUX_CNT-1:0] tlp_wr_tdata
    );

    function [127:0] dwd_rev(input [ 31:0] dw);
        dwd_rev = {dw[0+:8],dw[8+:8],dw[16+:8],dw[24+:8]};
    endfunction

    function [127:0] tlp_rev(input [127:0] dw);
        tlp_rev = {
            dw[96+:8],dw[104+:8],dw[112+:8],dw[120+:8],
            dw[64+:8],dw[ 72+:8],dw[ 80+:8],dw[ 88+:8],
            dw[32+:8],dw[ 40+:8],dw[ 48+:8],dw[ 56+:8],
            dw[ 0+:8],dw[  8+:8],dw[ 16+:8],dw[ 24+:8]
        };
    endfunction

    localparam MUX_IDX = $clog2(MUX_CNT);

    //////////////////////////////////////////////////////////////////////////////
    // Read/Write Arbiter
    //////////////////////////////////////////////////////////////////////////////
    reg                tlp_wr_avail, tlp_wr_avail_q;
    reg                tlp_rd_avail, tlp_rd_avail_q;
    reg  [MUX_IDX-1:0] tlp_rq_index, tlp_rq_index_q;
    wire [MUX_CNT-1:0] tlp_wr_compl = tlp_wr_valid & tlp_wr_ready & tlp_wr_tlast;
    wire [MUX_CNT-1:0] tlp_rd_compl = tlp_rd_valid & tlp_rd_ready;

    integer i;
    always @(*) begin
        if (rst) begin
            tlp_rq_index = {MUX_IDX{1'h0}};
            tlp_rd_avail = 1'h0;
            tlp_wr_avail = 1'h0;
        end else
        if (tlp_rd_avail_q || tlp_wr_avail_q) begin
            tlp_rq_index = tlp_rq_index_q;
            tlp_rd_avail = tlp_rd_avail_q;
            tlp_rd_avail = tlp_rd_avail_q;
        end else begin
            tlp_rq_index = {MUX_IDX{1'h0}};
            tlp_rd_avail = 1'h0;
            tlp_wr_avail = 1'h0;
 
            for (i = 0; i < MUX_CNT; i = i + 1) begin
                if (tlp_rd_valid[i]) begin
                    tlp_wr_avail = 1'h0;
                    tlp_rd_avail = 1'h1;
                    tlp_rq_index = i;
                end else
                if (tlp_wr_valid[i]) begin
                    tlp_wr_avail = 1'h1;
                    tlp_rd_avail = 1'h0;
                    tlp_rq_index = i;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst || tlp_wr_compl || tlp_rd_compl) begin
            tlp_rq_index_q <= {MUX_IDX{1'h0}};
            tlp_wr_avail_q <= 1'h0;
            tlp_rd_avail_q <= 1'h0;
        end else begin
            tlp_rq_index_q <= tlp_rq_index;
            tlp_wr_avail_q <= tlp_wr_avail;
            tlp_rd_avail_q <= tlp_rd_avail;
        end
    end
   
    //////////////////////////////////////////////////////////////////////////////
    // Internal (merged) R/W Signals to PCIe Host
    //////////////////////////////////////////////////////////////////////////////
    wire [  7:0] tlp_ext_rd_tag   = virtio_pci_tag[{tlp_rq_index,3'h0}+: 8];
    wire [ 63:0] tlp_ext_rd_taddr = tlp_rq_taddr  [{tlp_rq_index,6'h0}+:64];
    wire [ 15:0] tlp_ext_rd_tsize = tlp_rq_tsize  [{tlp_rq_index,4'h0}+:16];
    wire         tlp_ext_rd_valid = tlp_rd_valid  [ tlp_rq_index      +: 1] && tlp_rd_avail;
    reg          tlp_ext_rd_ready;

    reg  [  7:0] tlp_int_rd_tag  , tlp_tmp_rd_tag  ;
    reg  [ 63:0] tlp_int_rd_taddr, tlp_tmp_rd_taddr;
    reg  [ 15:0] tlp_int_rd_tsize, tlp_tmp_rd_tsize;
    reg          tlp_int_rd_valid, tlp_tmp_rd_valid;
    reg          tlp_int_rd_ready;
   
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            tlp_tmp_rd_tag   <=   8'h0;
            tlp_tmp_rd_taddr <=  64'h0;
            tlp_tmp_rd_tsize <=  16'h0;
            tlp_tmp_rd_valid <=   1'h0;
            tlp_ext_rd_ready <=   1'h0;
        end else
        if (tlp_int_rd_valid != 1'h1 || tlp_int_rd_ready) begin
            if (tlp_tmp_rd_valid && tlp_ext_rd_ready) begin
                tlp_tmp_rd_tag   <= tlp_ext_rd_tag  ;
                tlp_tmp_rd_taddr <= tlp_ext_rd_taddr;
                tlp_tmp_rd_tsize <= tlp_ext_rd_tsize;
                tlp_tmp_rd_valid <= tlp_ext_rd_valid;
                tlp_ext_rd_ready <= 1'h1;
            end else begin
                tlp_tmp_rd_valid <= 1'h0;
                tlp_ext_rd_ready <= 1'h1;
            end
        end else
        if (tlp_ext_rd_ready == 1'h1) begin
            tlp_tmp_rd_tag   <= tlp_ext_rd_tag  ;
            tlp_tmp_rd_taddr <= tlp_ext_rd_taddr;
            tlp_tmp_rd_tsize <= tlp_ext_rd_tsize;
            tlp_tmp_rd_valid <= tlp_ext_rd_valid;
            tlp_ext_rd_ready <= tlp_ext_rd_valid != 1'h1;
       end else
        if (tlp_tmp_rd_valid != 1'h1) begin
            tlp_ext_rd_ready <= 1'h1;
        end else begin
            tlp_ext_rd_ready <= 1'h0;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rd_tag   <=   8'h0;
            tlp_int_rd_taddr <=  64'h0;
            tlp_int_rd_tsize <=  16'h0;
            tlp_int_rd_valid <=   1'h0;
        end else
        if (tlp_int_rd_valid != 1'h1 || tlp_int_rd_ready) begin
            if (tlp_tmp_rd_valid) begin
                tlp_int_rd_tag   <= tlp_tmp_rd_tag  ;
                tlp_int_rd_taddr <= tlp_tmp_rd_taddr;
                tlp_int_rd_tsize <= tlp_tmp_rd_tsize;
                tlp_int_rd_valid <= tlp_tmp_rd_valid;
            end else
            if (tlp_ext_rd_valid) begin
                tlp_int_rd_tag   <= tlp_ext_rd_tag  ;
                tlp_int_rd_taddr <= tlp_ext_rd_taddr;
                tlp_int_rd_tsize <= tlp_ext_rd_tsize;
                tlp_int_rd_valid <= tlp_ext_rd_valid;
            end else begin
                tlp_int_rd_valid <= 1'h0;
            end
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // 1-Clock Buffer
    //////////////////////////////////////////////////////////////////////////////
    wire [  7:0] tlp_ext_wr_tag   = virtio_pci_tag[{tlp_rq_index,3'h0}+:  8];
    wire [ 63:0] tlp_ext_wr_taddr = tlp_rq_taddr  [{tlp_rq_index,6'h0}+: 64];
    wire [ 15:0] tlp_ext_wr_tsize = tlp_rq_tsize  [{tlp_rq_index,4'h0}+: 16];
    wire [127:0] tlp_ext_wr_tdata = tlp_wr_tdata  [{tlp_rq_index,7'h0}+:128];
    wire         tlp_ext_wr_tlast = tlp_wr_tlast  [ tlp_rq_index      +:  1];                  
    wire         tlp_ext_wr_valid = tlp_wr_valid  [ tlp_rq_index      +:  1] && tlp_wr_avail;
    reg          tlp_ext_wr_ready;

    reg  [  7:0] tlp_int_wr_tag  , tlp_tmp_wr_tag  ;
    reg  [ 63:0] tlp_int_wr_taddr, tlp_tmp_wr_taddr;
    reg  [ 15:0] tlp_int_wr_tsize, tlp_tmp_wr_tsize;
    reg  [127:0] tlp_int_wr_tdata, tlp_tmp_wr_tdata;
    reg          tlp_int_wr_valid, tlp_tmp_wr_valid;
    reg          tlp_int_wr_tlast, tlp_tmp_wr_tlast;
    reg          tlp_int_wr_ready;
   
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            tlp_tmp_wr_tag   <=   8'h0;
            tlp_tmp_wr_taddr <=  64'h0;
            tlp_tmp_wr_tsize <=  16'h0;
            tlp_tmp_wr_tdata <= 128'h0;
            tlp_tmp_wr_valid <=   1'h0;
            tlp_tmp_wr_tlast <=   1'h0;
            tlp_ext_wr_ready <=   1'h0;
        end else
        if (tlp_int_wr_valid != 1'h1 || tlp_int_wr_ready) begin
            if (tlp_tmp_wr_valid && tlp_ext_wr_ready) begin
                tlp_tmp_wr_tag   <= tlp_ext_wr_tag  ;
                tlp_tmp_wr_taddr <= tlp_ext_wr_taddr;
                tlp_tmp_wr_tsize <= tlp_ext_wr_tsize;
                tlp_tmp_wr_tdata <= tlp_ext_wr_tdata;
                tlp_tmp_wr_valid <= tlp_ext_wr_valid;
                tlp_tmp_wr_tlast <= tlp_ext_wr_tlast;
                tlp_ext_wr_ready <= 1'h1;
            end else begin
                tlp_tmp_wr_valid <= 1'h0;
                tlp_ext_wr_ready <= 1'h1;
            end
        end else
        if (tlp_ext_wr_ready == 1'h1) begin
            tlp_tmp_wr_tag   <= tlp_ext_wr_tag  ;
            tlp_tmp_wr_tdata <= tlp_ext_wr_tdata;
            tlp_tmp_wr_taddr <= tlp_ext_wr_taddr;
            tlp_tmp_wr_tsize <= tlp_ext_wr_tsize;
            tlp_tmp_wr_valid <= tlp_ext_wr_valid;
            tlp_tmp_wr_tlast <= tlp_ext_wr_tlast;
            tlp_ext_wr_ready <= tlp_ext_wr_valid != 1'h1;
       end else
        if (tlp_tmp_wr_valid != 1'h1) begin
            tlp_ext_wr_ready <= 1'h1;
        end else begin
            tlp_ext_wr_ready <= 1'h0;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            tlp_int_wr_tag   <=   8'h0;
            tlp_int_wr_taddr <=  64'h0;
            tlp_int_wr_tsize <=  16'h0;
            tlp_int_wr_tdata <= 128'h0;
            tlp_int_wr_valid <=   1'h0;
            tlp_int_wr_tlast <=   1'h0;
        end else
        if (tlp_int_wr_valid != 1'h1 || tlp_int_wr_ready) begin
            if (tlp_tmp_wr_valid) begin
                tlp_int_wr_tag   <= tlp_tmp_wr_tag  ;
                tlp_int_wr_tdata <= tlp_tmp_wr_tdata;
                tlp_int_wr_taddr <= tlp_tmp_wr_taddr;
                tlp_int_wr_tsize <= tlp_tmp_wr_tsize;
                tlp_int_wr_valid <= tlp_tmp_wr_valid;
                tlp_int_wr_tlast <= tlp_tmp_wr_tlast;
            end else
            if (tlp_ext_wr_valid) begin
                tlp_int_wr_tag   <= tlp_ext_wr_tag  ;
                tlp_int_wr_tdata <= tlp_ext_wr_tdata;
                tlp_int_wr_taddr <= tlp_ext_wr_taddr;
                tlp_int_wr_tsize <= tlp_ext_wr_tsize;
                tlp_int_wr_valid <= tlp_ext_wr_valid;
                tlp_int_wr_tlast <= tlp_ext_wr_tlast;
            end else begin
                tlp_int_wr_valid <= 1'h0;
            end
        end
    end
    
    //----------------------------------------------------------------------------
    wire [ 15:0] vio_int_rq_rid = virtio_pci_rid;

    genvar n1;
    generate
    for (n1 = 0; n1 < MUX_CNT; n1 = n1 + 1) begin
        always @(*) begin
            if (tlp_rq_index == n1) begin
                tlp_wr_ready[n1] = tlp_ext_wr_ready;
                tlp_rd_ready[n1] = tlp_ext_rd_ready;
            end else begin
                tlp_wr_ready[n1] = 1'h0;
                tlp_rd_ready[n1] = 1'h0;
            end
        end
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////
    // TLP Data align to 4B
    //////////////////////////////////////////////////////////////////////////////
    reg          tlp_shr_wr_start;
    reg  [ 15:0] tlp_shr_wr_tsize, tlp_shr_wr_tsize_q;
    reg  [ 63:0] tlp_shr_wr_taddr, tlp_shr_wr_taddr_q;
    reg  [247:0] tlp_shr_wr_tdata, tlp_shr_wr_tdata_q;
    reg          tlp_shr_wr_valid_q;
    wire         tlp_shr_wr_valid;
    reg          tlp_shr_wr_ready;
 
    //----------------------------------------------------------------------------
    assign tlp_shr_wr_valid = tlp_int_wr_valid;

    always @(*) begin
        if (rst) begin
            tlp_shr_wr_tdata = 248'h0;
        end else begin
            case (tlp_shr_wr_taddr[1:0])
                2'h0: tlp_shr_wr_tdata = {tlp_int_wr_tdata,tlp_shr_wr_tdata_q[128+: 96]};
                2'h1: tlp_shr_wr_tdata = {tlp_int_wr_tdata,tlp_shr_wr_tdata_q[128+:104]};
                2'h2: tlp_shr_wr_tdata = {tlp_int_wr_tdata,tlp_shr_wr_tdata_q[128+:112]};
                2'h3: tlp_shr_wr_tdata = {tlp_int_wr_tdata,tlp_shr_wr_tdata_q[128+:120]};
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            tlp_shr_wr_tdata_q <= 248'h0;
            tlp_shr_wr_valid_q <=   1'h0;
        end else
        if (!tlp_shr_wr_valid || tlp_shr_wr_ready) begin 
            tlp_shr_wr_tdata_q <= tlp_shr_wr_tdata;
            tlp_shr_wr_valid_q <= tlp_shr_wr_valid;
        end
    end

    //----------------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            tlp_shr_wr_taddr = 64'h0;
            tlp_shr_wr_tsize = 16'h0;
        end else
        if (tlp_shr_wr_start) begin
            tlp_shr_wr_taddr = tlp_int_wr_taddr;
            tlp_shr_wr_tsize = tlp_int_wr_tsize;
        end else begin
            tlp_shr_wr_taddr = tlp_shr_wr_taddr_q;
            tlp_shr_wr_tsize = tlp_shr_wr_tsize_q;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            tlp_shr_wr_taddr_q <=  64'h0;
            tlp_shr_wr_tsize_q <=  16'h0;
        end else begin
            tlp_shr_wr_taddr_q <= tlp_shr_wr_taddr;
            tlp_shr_wr_tsize_q <= tlp_shr_wr_tsize;
        end
    end

    //----------------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            tlp_int_wr_ready = 1'h0;
        end else begin
            tlp_int_wr_ready = tlp_shr_wr_ready;
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // TLP RQ Stream (FSM for RQ -> Host)
    //////////////////////////////////////////////////////////////////////////////
    function [7:0] tlp_xbe(input [1:0] addr, input [11:0] len);
        reg [11:0] sum;
        begin
            sum = addr + len;
            if (sum[11:2] && sum[11:0] != 12'h4) begin // sum > 4 (tlp len >= 1 dword)
                case ({len[1:0],addr[1:0]})
                    4'h0: tlp_xbe = 8'b1111_1111; // 0,0
                    4'h1: tlp_xbe = 8'b0001_1110; // 0,1
                    4'h2: tlp_xbe = 8'b0011_1100; // 0,2
                    4'h3: tlp_xbe = 8'b0111_1000; // 0,3

                    4'h4: tlp_xbe = 8'b0001_1111; // 1,0
                    4'h5: tlp_xbe = 8'b0011_1110; // 1,1
                    4'h6: tlp_xbe = 8'b0111_1100; // 1,2
                    4'h7: tlp_xbe = 8'b1111_1000; // 1,3

                    4'h8: tlp_xbe = 8'b0011_1111; // 2,0
                    4'h9: tlp_xbe = 8'b0111_1110; // 2,1
                    4'hA: tlp_xbe = 8'b1111_1100; // 2,2
                    4'hB: tlp_xbe = 8'b0001_1000; // 2,3

                    4'hC: tlp_xbe = 8'b0111_1111; // 3,0
                    4'hD: tlp_xbe = 8'b1111_1110; // 3,1
                    4'hE: tlp_xbe = 8'b0001_1100; // 3,2
                    4'hF: tlp_xbe = 8'b0011_1000; // 3,3
                endcase
            end else begin // tlp len == 1 dword
                case ({len[1:0],addr[1:0]})
                    4'h0: tlp_xbe = 8'b0000_1111;
                    // 4'h1: tlp_xbe = 8'b0001_1110;
                    // 4'h2: tlp_xbe = 8'b0011_1100;
                    // 4'h3: tlp_xbe = 8'b0111_1000;

                    4'h4: tlp_xbe = 8'b0000_0001;
                    4'h5: tlp_xbe = 8'b0000_0010;
                    4'h6: tlp_xbe = 8'b0000_0100;
                    4'h7: tlp_xbe = 8'b0000_1000;

                    4'h8: tlp_xbe = 8'b0000_0011;
                    4'h9: tlp_xbe = 8'b0000_0110;
                    4'hA: tlp_xbe = 8'b0000_1100;
                    // 4'hB: tlp_xbe = 8'b0001_1000;

                    4'hC: tlp_xbe = 8'b0000_0111;
                    4'hD: tlp_xbe = 8'b0000_1110;
                    // 4'hE: tlp_xbe = 8'b0001_1100;
                    // 4'hF: tlp_xbe = 8'b0011_1000;

                    default: tlp_xbe = 8'h0;
                endcase
            end
        end
    endfunction

    function [9:0] tlp_len(input [1:0] addr, input [11:0] len);
        tlp_len = (len + addr + 2'h3) >> 2;
    endfunction

    function [11:0] tlp_efp(input [1:0] addr, input [11:0] len, input h4d, input [2:0] shr); // End-of-Frame Pointer
        if (h4d) begin
            tlp_efp = (len + addr + 4'hF) >> shr;
        end else begin
            tlp_efp = (len + addr + 4'hB) >> shr;
        end
    endfunction

    //////////////////////////////////////////////////////////////////////////////
    reg  [ 7:0] tlp_int_rq_state, tlp_int_rq_state_q;
    reg  [ 7:0] tlp_int_rq_count;

    localparam RQ_STATE_IDLE = 8'h0;
    localparam RQ_STATE_WH64 = 8'h1;
    localparam RQ_STATE_WH32 = 8'h2;
    localparam RQ_STATE_WR64 = 8'h3;
    localparam RQ_STATE_WE64 = 8'h4;
    localparam RQ_STATE_WR32 = 8'h5;
    localparam RQ_STATE_WE32 = 8'h6;
    localparam RQ_STATE_RD64 = 8'h7;
    localparam RQ_STATE_RD32 = 8'h8;

    //----------------------------------------------------------------------------
    task next_tlp (
        input         tlp_rd_valid,
        input  [63:1] tlp_rd_taddr,
        output        tlp_rd_ready,
        
        input         tlp_wr_valid, 
        input  [63:1] tlp_wr_taddr,
        output        tlp_wr_ready,

        output [ 7:0] tlp_rq_state
    ); begin
            tlp_rd_ready = 1'h0;
            tlp_wr_ready = 1'h0;

            if (tlp_rd_valid && tlp_rd_taddr[63:32]) begin // Memory Read (64-bit address)
                tlp_rq_state = RQ_STATE_RD64;
                tlp_rd_ready = 1'h1;
            end else
            if (tlp_wr_valid && tlp_wr_taddr[63:32]) begin // Memory Write (64-bit address)
                tlp_rq_state = RQ_STATE_WH64;
                tlp_wr_ready = 1'h0;
            end else
            if (tlp_rd_valid) begin // Memory Read (32-bit address)
                tlp_rq_state = RQ_STATE_RD32;
                tlp_rd_ready = 1'h1;
            end else
            if (tlp_wr_valid) begin // Memory Write (32-bit address)
                tlp_rq_state = RQ_STATE_WH32;
                tlp_wr_ready = 1'h1;
            end else begin
                tlp_rq_state = RQ_STATE_IDLE;
            end
        end
    endtask

    //----------------------------------------------------------------------------
    wire [11:0] tlp_int_rq_efp32 = tlp_efp(tlp_int_wr_taddr, tlp_int_wr_tsize, 0, 0);
    wire [11:0] tlp_int_rq_efp64 = tlp_efp(tlp_int_wr_taddr, tlp_int_wr_tsize, 1, 0);
    reg  [11:0] tlp_shr_rq_efp32;
    reg  [11:0] tlp_shr_rq_efp64;

    always @(posedge clk) begin
        if (rst) begin
            tlp_shr_rq_efp32 <= 12'h0;
            tlp_shr_rq_efp64 <= 12'h0;
        end else
        if (tlp_shr_wr_start) begin
            tlp_shr_rq_efp32 <= tlp_int_rq_efp32;
            tlp_shr_rq_efp64 <= tlp_int_rq_efp64;
        end
    end

    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        tlp_int_rq_state_q <= tlp_int_rq_state;
        if (rst) begin
            tlp_int_rq_state_q <= RQ_STATE_IDLE;
        end
    end

    always @(*) begin
        if (rst) begin
            tlp_int_rq_state = RQ_STATE_IDLE;
            tlp_shr_wr_ready = 1'h0;
            tlp_int_rd_ready = 1'h0;
            tlp_shr_wr_start = 1'h0;
        end else begin
            tlp_int_rq_state = tlp_int_rq_state_q;
            tlp_shr_wr_ready = 1'h0;
            tlp_int_rd_ready = 1'h0;
            tlp_shr_wr_start = 1'h0;
            
            case (tlp_int_rq_state_q)
                RQ_STATE_RD64, RQ_STATE_RD32: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin
                        tlp_shr_wr_start = 1'h1;
                        next_tlp(
                            tlp_int_rd_valid,
                            tlp_int_rd_taddr,
                            tlp_int_rd_ready,

                            tlp_shr_wr_valid, 
                            tlp_int_wr_taddr, 
                            tlp_shr_wr_ready, 

                            tlp_int_rq_state
                        );
                    end
                end
  
                RQ_STATE_WE32, RQ_STATE_WE64: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin
                        tlp_shr_wr_start = 1'h1;
                        next_tlp(
                            tlp_int_rd_valid,
                            tlp_int_rd_taddr,
                            tlp_int_rd_ready,

                            tlp_shr_wr_valid, 
                            tlp_int_wr_taddr, 
                            tlp_shr_wr_ready, 

                            tlp_int_rq_state
                        );
                    end
                end

                RQ_STATE_IDLE: begin
                    if (!tlp_rq_ready && tlp_rq_valid) begin
                        tlp_int_rq_state = RQ_STATE_IDLE;
                        tlp_int_rd_ready = 1'h0;
                    end else begin
                        tlp_shr_wr_start = 1'h1;
                        next_tlp(
                            tlp_int_rd_valid,
                            tlp_int_rd_taddr,
                            tlp_int_rd_ready,

                            tlp_shr_wr_valid, 
                            tlp_int_wr_taddr, 
                            tlp_shr_wr_ready, 

                            tlp_int_rq_state
                        );
                    end
                end
                 
                RQ_STATE_WH64, RQ_STATE_WR64: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin
                        case (tlp_shr_rq_efp64[11:4] - tlp_int_rq_count - tlp_rq_valid)
                            8'h0: begin
                                if ({tlp_int_rq_count + tlp_rq_valid,2'h0,tlp_shr_wr_taddr[1:0]} > tlp_shr_rq_efp64) begin
                                    tlp_int_rq_state = RQ_STATE_WE64;
                                end else
                                if (tlp_shr_wr_valid) begin
                                    tlp_int_rq_state = RQ_STATE_WE64;
                                    tlp_shr_wr_ready = 1'h1;
                                end
                            end
                            default: begin
                                tlp_int_rq_state = RQ_STATE_WR64;
                                tlp_shr_wr_ready = 1'h1;
                            end
                        endcase
                    end
                end
                 
                RQ_STATE_WH32: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin
                        case (tlp_shr_rq_efp32[11:4])
                            12'h0: begin
                                tlp_shr_wr_start = 1'h1;
                                next_tlp(
                                    tlp_int_rd_valid,
                                    tlp_int_rd_taddr,
                                    tlp_int_rd_ready,
        
                                    tlp_shr_wr_valid, 
                                    tlp_int_wr_taddr, 
                                    tlp_shr_wr_ready, 
        
                                    tlp_int_rq_state
                                );
                            end
                            12'h1: begin
                                if ({3'h7,tlp_shr_wr_taddr[1:0]} > tlp_shr_rq_efp32) begin
                                    tlp_int_rq_state = RQ_STATE_WE32;
                                end else
                                if (tlp_shr_wr_valid) begin
                                    tlp_int_rq_state = RQ_STATE_WE32;
                                    tlp_shr_wr_ready = 1'h1;
                                end
                            end
                            default: begin
                                tlp_int_rq_state = RQ_STATE_WR32;
                                tlp_shr_wr_ready = 1'h1;
                            end
                        endcase
                    end
                end

                RQ_STATE_WR32: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin
                        case (tlp_shr_rq_efp32[11:4] - tlp_int_rq_count - tlp_rq_valid)
                            12'h0: begin
                                if ({tlp_int_rq_count + tlp_rq_valid,2'h3,tlp_shr_wr_taddr[1:0]} > tlp_shr_rq_efp32) begin
                                    tlp_int_rq_state = RQ_STATE_WE32;
                                end else
                                if (tlp_shr_wr_valid) begin
                                    tlp_int_rq_state = RQ_STATE_WE32;
                                    tlp_shr_wr_ready = 1'h1;
                                end
                            end
                            default: begin
                                tlp_int_rq_state = RQ_STATE_WR32;
                                tlp_shr_wr_ready = 1'h1;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rq_count    <=   8'h0;
            tlp_rq_data         <= 128'h0;
            tlp_rq_valid        <=   1'h0;
            tlp_rq_start_flag   <=   1'h0;
            tlp_rq_start_offset <=   4'h0;
            tlp_rq_end_flag     <=   1'h0;
            tlp_rq_end_offset   <=   4'h0;
        end else begin
            case (tlp_int_rq_state)
                RQ_STATE_IDLE: begin
                    tlp_int_rq_count    <=   8'h0;
                    tlp_rq_data         <= 128'h0;
                    tlp_rq_valid        <=   1'h0;
                    tlp_rq_start_flag   <=   1'h0;
                    tlp_rq_start_offset <=   4'h0;
                    tlp_rq_end_flag     <=   1'h0;
                    tlp_rq_end_offset   <=   4'h0;
                end

                RQ_STATE_WH64: begin // Memory Write (64-bit address)
                    tlp_int_rq_count    <= 8'h0;

                    tlp_rq_data <= {
                        tlp_int_wr_taddr[31: 2], 2'h0,                                               // DW-3
                        tlp_int_wr_taddr[63:32],                                                     // DW-2
                        vio_int_rq_rid, tlp_int_wr_tag, tlp_xbe(tlp_int_wr_taddr, tlp_int_wr_tsize), // DW-1
                        16'h6000, 6'h00, tlp_len(tlp_int_wr_taddr, tlp_int_wr_tsize)                 // DW-0
                    };
                   
                    tlp_rq_valid        <= 1'h1;
                    tlp_rq_start_flag   <= 1'h1;
                    tlp_rq_start_offset <= 4'h0;
                    tlp_rq_end_flag     <= 1'h0;
                    tlp_rq_end_offset   <= 4'h0;

                    if (!tlp_int_rq_efp64[11:4]) begin
                        tlp_rq_end_flag   <= 1'h1;
                        tlp_rq_end_offset <= tlp_shr_rq_efp64;
                    end
                end
                
                RQ_STATE_RD64: begin // Memory Read (64-bit address)
                    tlp_int_rq_count    <= 8'h0;
                    
                    tlp_rq_valid        <= 1'h1;
                    tlp_rq_start_offset <= 4'h0;
                    tlp_rq_start_flag   <= 1'h1;
                    tlp_rq_end_flag     <= 1'h1;
                    tlp_rq_end_offset   <= 4'hF;

                    tlp_rq_data <= {
                       tlp_int_rd_taddr[31: 2], 2'h0,                                               // DW-3
                       tlp_int_rd_taddr[63:32],                                                     // DW-2
                       vio_int_rq_rid, tlp_int_rd_tag, tlp_xbe(tlp_int_rd_taddr, tlp_int_rd_tsize), // DW-1
                       16'h2000, 6'h0, tlp_len(tlp_int_rd_taddr, tlp_int_rd_tsize)                  // DW-0
                    };
                end
                
                RQ_STATE_WH32: begin // Memory Write (32-bit address)
                    if (!tlp_rq_valid || tlp_rq_ready) begin // Memory Write (Payload with 64-bit address)
                        tlp_int_rq_count <= 8'h0;

                        tlp_rq_data <= {
                            dwd_rev(tlp_shr_wr_tdata[96+:32]),

                            tlp_int_wr_taddr[31: 2], 2'h0,                                               // DW-2
                            vio_int_rq_rid, tlp_int_wr_tag, tlp_xbe(tlp_int_wr_taddr, tlp_int_wr_tsize), // DW-1
                            16'h4000, 6'h00, tlp_len(tlp_int_wr_taddr, tlp_int_wr_tsize)                 // DW-0
                        };

                        tlp_rq_valid        <= tlp_shr_wr_valid;
                        tlp_rq_start_flag   <= 1'h1;
                        tlp_rq_start_offset <= 4'h0;
                        tlp_rq_end_flag     <= 1'h0;
                        tlp_rq_end_offset   <= 4'h0;

                        if (!tlp_int_rq_efp32[11:4]) begin
                            tlp_rq_end_flag   <= 1'h1;
                            tlp_rq_end_offset <= tlp_shr_rq_efp32;
                        end
                    end
                end
                
                RQ_STATE_RD32: begin // Memory Read (32-bit address)
                    tlp_int_rq_count    <= 8'h0;
                    
                    tlp_rq_valid        <= 1'h1;
                    tlp_rq_start_offset <= 4'h0;
                    tlp_rq_start_flag   <= 1'h1;
                    tlp_rq_end_flag     <= 1'h1;
                    tlp_rq_end_offset   <= 4'hB;

                    tlp_rq_data <= {
                        tlp_int_rd_taddr[31: 2], 2'h0,                                               // DW-2
                        vio_int_rq_rid, tlp_int_rd_tag, tlp_xbe(tlp_int_rd_taddr, tlp_int_rd_tsize), // DW-1
                        16'h0000, 6'h00, tlp_len(tlp_int_rd_taddr, tlp_int_rd_tsize)                 // DW-0
                    };
                end

                RQ_STATE_WR64: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin // Memory Write (Payload with 64-bit address)
                        tlp_int_rq_count    <= tlp_int_rq_count + tlp_rq_valid;
                        tlp_rq_data         <= tlp_rev(tlp_shr_wr_tdata[96+:128]);
                        tlp_rq_valid        <= tlp_shr_wr_valid;
                        tlp_rq_start_offset <= 4'h0;
                        tlp_rq_start_flag   <= 1'h0;
                        tlp_rq_end_flag     <= 1'h0;
                        tlp_rq_end_offset   <= 4'h0;
                    end
                end
                
                RQ_STATE_WE64: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin // Memory Write (Payload with 64-bit address)
                        tlp_rq_data         <= tlp_rev(tlp_shr_wr_tdata[96+:128]);
                        tlp_rq_valid        <= 1'h1;
                        tlp_rq_start_offset <= 4'h0;
                        tlp_rq_start_flag   <= 1'h0;
                        tlp_rq_end_flag     <= 1'h1;
                        tlp_rq_end_offset   <= tlp_shr_rq_efp64;
                    end
                end

                RQ_STATE_WR32: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin // Memory Write (Payload with 32-bit address)
                        tlp_int_rq_count    <= tlp_int_rq_count + tlp_rq_valid;
                        tlp_rq_data         <= tlp_rev(tlp_shr_wr_tdata[0+:128]);
                        tlp_rq_valid        <= tlp_shr_wr_valid;
                        tlp_rq_start_flag   <= 1'h0;
                        tlp_rq_start_offset <= 4'h0;
                        tlp_rq_end_flag     <= 1'h0;
                        tlp_rq_end_offset   <= 4'h0;
                    end
                end
                
                RQ_STATE_WE32: begin
                    if (!tlp_rq_valid || tlp_rq_ready) begin // Memory Write (Payload with 32-bit address)
                        tlp_rq_data         <= tlp_rev(tlp_shr_wr_tdata[0+:128]);
                        tlp_rq_valid        <= 1'h1;
                        tlp_rq_start_flag   <= 1'h0;
                        tlp_rq_start_offset <= 4'h0;
                        tlp_rq_end_flag     <= 1'h1;
                        tlp_rq_end_offset   <= tlp_shr_rq_efp32;
                    end
                end
            endcase
        end
    end
endmodule
 
