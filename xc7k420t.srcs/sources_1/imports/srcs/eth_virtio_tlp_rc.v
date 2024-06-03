`timescale 1ns / 1ps

module eth_virtio_tlp_rc #(
    parameter MUX_CNT = 4
    ) (
    input  wire clk,
    input  wire rst,

    input  wire [127:0] tlp_rc_data        ,
    input  wire         tlp_rc_valid       ,
    input  wire         tlp_rc_start_flag  ,
    input  wire [  3:0] tlp_rc_start_offset,
    input  wire         tlp_rc_end_flag    ,
    input  wire [  3:0] tlp_rc_end_offset  ,
    output wire         tlp_rc_ready       ,

    input  wire [ 8*MUX_CNT-1:0] virtio_pci_tag,

    output reg  [   MUX_CNT-1:0] tlp_rx_valid,
    input  wire [   MUX_CNT-1:0] tlp_rx_ready,
    output reg  [   MUX_CNT-1:0] tlp_rx_tlast,

    output reg  [         127:0] tlp_rx_tdata,
    output reg  [          15:0] tlp_rx_tkeep
    );

    function [127:0] tlp_rev(input [127:0] dw);
        tlp_rev = {
            dw[96+:8],dw[104+:8],dw[112+:8],dw[120+:8],
            dw[64+:8],dw[ 72+:8],dw[ 80+:8],dw[ 88+:8],
            dw[32+:8],dw[ 40+:8],dw[ 48+:8],dw[ 56+:8],
            dw[ 0+:8],dw[  8+:8],dw[ 16+:8],dw[ 24+:8]
        };
    endfunction

    //////////////////////////////////////////////////////////////////////////////
    // 1-cycle buffer for TLP RC stream
    //////////////////////////////////////////////////////////////////////////////
    reg  [127:0] tlp_int_rc_tdata;
    reg          tlp_int_rc_valid;
    wire         tlp_int_rc_ready;
    reg          tlp_int_rc_tlast;
    reg  [ 15:0] tlp_int_rc_count;

    assign tlp_rc_ready = tlp_int_rc_ready || !tlp_int_rc_valid;
    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_valid <=   1'h0;
            tlp_int_rc_tdata <= 128'h0;
            tlp_int_rc_tlast <=   1'h0;
        end else
        if (tlp_int_rc_ready || !tlp_int_rc_valid) begin
            if (tlp_rc_valid) begin
                tlp_int_rc_valid <= 1'h1;
                tlp_int_rc_tdata <= tlp_rc_data;
                tlp_int_rc_tlast <= tlp_rc_end_flag;
            end else begin
                tlp_int_rc_valid <=   1'h0;
                tlp_int_rc_tdata <= 128'h0;
                tlp_int_rc_tlast <=   1'h0;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_count <= 16'h0;
        end else
        if (tlp_int_rc_valid && tlp_int_rc_ready && tlp_int_rc_tlast) begin
            if (tlp_rc_valid && tlp_rc_end_flag) begin
                tlp_int_rc_count <= {1'h0,tlp_rc_end_offset} + 1'h1;
            end else
            if (tlp_rc_valid) begin
                tlp_int_rc_count <= 16'h10;
            end else begin
                tlp_int_rc_count <= 16'h00;
            end
        end else
        if (tlp_int_rc_valid && tlp_int_rc_ready || !tlp_int_rc_valid) begin
            if (tlp_rc_valid && tlp_rc_end_flag) begin
                tlp_int_rc_count <= tlp_int_rc_count + {1'h0,tlp_rc_end_offset} + 1'h1;
            end else
            if (tlp_rc_valid) begin
                tlp_int_rc_count <= tlp_int_rc_count + 16'h10;
            end
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // TLP RC Header Fields (with virtq selection)
    //////////////////////////////////////////////////////////////////////////////
    reg        tlp_int_rc_frg;
    reg        tlp_int_rc_hdr;

    reg [ 9:0] tlp_int_rc_len;
    reg [ 6:0] tlp_int_rc_fmt;
    reg [11:0] tlp_int_rc_bcn;
    reg [ 2:0] tlp_int_rc_sta;
    reg [ 7:0] tlp_int_rc_tag;
    reg [15:0] tlp_int_rc_cid;
    reg [ 6:0] tlp_int_rc_lwa;
    reg [15:0] tlp_int_rc_rid;

    reg        tlp_int_rc_ign;
    reg  [7:0] tlp_int_rc_sel;

    integer j;
    always @(posedge clk) begin
        if (tlp_int_rc_valid && tlp_int_rc_ready || !tlp_int_rc_valid) begin
            if (tlp_rc_valid && tlp_int_rc_hdr) begin
                tlp_int_rc_frg <= ({1'h0,tlp_rc_data[0+:10],2'h0} - tlp_rc_data[32+:12] - tlp_rc_data[64+:2]) >> 12;
                tlp_int_rc_len <= tlp_rc_data[ 0+:10];
                tlp_int_rc_fmt <= tlp_rc_data[24+: 7];
                tlp_int_rc_bcn <= tlp_rc_data[32+:12];
                tlp_int_rc_sta <= tlp_rc_data[44+: 3];
                tlp_int_rc_cid <= tlp_rc_data[48+:16];
                tlp_int_rc_lwa <= tlp_rc_data[64+: 7];
                tlp_int_rc_tag <= tlp_rc_data[72+: 8];
                tlp_int_rc_cid <= tlp_rc_data[80+:16];

                tlp_int_rc_ign <= 1'h1;
                for (j = 0; j < MUX_CNT; j = j + 1) begin
                    if (tlp_rc_data[72+:8] == virtio_pci_tag[8*j+:8]) begin
                        tlp_int_rc_ign <= 1'h0;
                        tlp_int_rc_sel <= j;
                    end
                end
                tlp_int_rc_hdr <= 1'h0;
            end
        end

        if (tlp_rc_valid && tlp_rc_ready && tlp_rc_end_flag) begin
            tlp_int_rc_ign <=  1'h1;
            tlp_int_rc_hdr <=  1'h1;
        end

        if (rst) begin
            tlp_int_rc_sel <=  8'h0;
            tlp_int_rc_ign <=  1'h1;
            tlp_int_rc_hdr <=  1'h1;
            tlp_int_rc_frg <=  1'h0;
            tlp_int_rc_len <= 10'h0;
            tlp_int_rc_fmt <=  7'h0;
            tlp_int_rc_bcn <= 12'h0;
            tlp_int_rc_sta <=  3'h0;
            tlp_int_rc_cid <= 16'h0;
            tlp_int_rc_tag <=  8'h0;
            tlp_int_rc_lwa <=  7'h0;
            tlp_int_rc_rid <= 16'h0;
        end
    end

    //----------------------------------------------------------------------------
    wire [127:0] tlp_int_rc_tdata_rev = tlp_rev(tlp_int_rc_tdata);

    //////////////////////////////////////////////////////////////////////////////
    // TLP RC Payload Handling
    //////////////////////////////////////////////////////////////////////////////
    localparam RC_STATE_IDLE = 8'h0;
    localparam RC_STATE_HFRG = 8'h1;
    localparam RC_STATE_HEND = 8'h2;
    localparam RC_STATE_HOUT = 8'h3;
    localparam RC_STATE_HEAD = 8'h4;
    localparam RC_STATE_DATA = 8'h5;

    localparam RC_STATE_EOT1 = 8'h6; // Enf-of-Transmission/TLP (EoT)
    localparam RC_STATE_EOT2 = 8'h7; // EoT with extra +1 cycle to output
    localparam RC_STATE_EOT3 = 8'h8; // Extra +1 cycle to the EoT

    localparam RC_STATE_EOP1 = 8'h9; // End-of-packet (EoP)
    localparam RC_STATE_EOP2 = 8'hA; // EoT with extra +1 cycle to output
    localparam RC_STATE_EOP3 = 8'hB; // Extra +1 cycle to the EoP

    reg  [7:0] tlp_int_rc_state, tlp_int_rc_state_q;
    reg  [4:0] tlp_int_rc_shift, tlp_int_rc_shift_q;
    reg        tlp_int_rc_ext1c;
    reg        tlp_int_rc_forwd, tlp_int_rc_forwd_q;

    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_state_q <= 8'h0;
            tlp_int_rc_forwd_q <= 1'h0;
        end else
        if (tlp_int_rc_ready || !tlp_int_rc_valid || !tlp_int_rc_forwd) begin
            tlp_int_rc_state_q <= tlp_int_rc_state;
            tlp_int_rc_forwd_q <= tlp_int_rc_forwd;
        end
    end

    //----------------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            tlp_int_rc_state = RC_STATE_IDLE;
            tlp_int_rc_forwd = 1'h0;
        end else begin
            tlp_int_rc_state = tlp_int_rc_state_q;
            tlp_int_rc_forwd = tlp_int_rc_forwd_q;
            
            case (tlp_int_rc_state_q)
                RC_STATE_HEND, RC_STATE_HFRG,
                RC_STATE_EOT1, RC_STATE_EOP1,
                RC_STATE_EOT3, RC_STATE_EOP3,
                RC_STATE_IDLE: begin
                    if (tlp_int_rc_valid && tlp_int_rc_tlast) begin
                        case ({tlp_int_rc_frg,tlp_int_rc_ext1c})
                            2'b00: tlp_int_rc_state = RC_STATE_HEND;
                            2'b01: tlp_int_rc_state = RC_STATE_EOP2;
                            2'b10: tlp_int_rc_state = RC_STATE_HFRG;
                            2'b11: tlp_int_rc_state = RC_STATE_EOT2;
                        endcase
                        tlp_int_rc_forwd = 1'h1;
                    end else
                    if (tlp_int_rc_valid && tlp_int_rc_shift[4:2] == 3'h3) begin
                        tlp_int_rc_state = RC_STATE_HOUT;
                        tlp_int_rc_forwd = 1'h1;
                    end else
                    if (tlp_int_rc_valid) begin
                        tlp_int_rc_state = RC_STATE_HEAD;
                        tlp_int_rc_forwd = 1'h1;
                    end else begin
                        tlp_int_rc_state = RC_STATE_IDLE;
                        tlp_int_rc_forwd = 1'h0;
                    end
                end
                RC_STATE_HOUT, RC_STATE_HEAD, RC_STATE_DATA: begin
                    if (tlp_int_rc_valid && tlp_int_rc_tlast) begin
                        case ({tlp_int_rc_frg,tlp_int_rc_ext1c})
                            2'b00: tlp_int_rc_state = RC_STATE_EOP1;
                            2'b01: tlp_int_rc_state = RC_STATE_EOP2;
                            2'b10: tlp_int_rc_state = RC_STATE_EOT1;
                            2'b11: tlp_int_rc_state = RC_STATE_EOT2;
                        endcase
                    end else
                    if (tlp_int_rc_valid) begin
                        tlp_int_rc_state = RC_STATE_DATA;
                    end
                end
                
                RC_STATE_EOT2: begin
                    tlp_int_rc_state = RC_STATE_EOT3;
                    tlp_int_rc_forwd = 1'h0;
                end
                RC_STATE_EOP2: begin
                    tlp_int_rc_state = RC_STATE_EOP3;
                    tlp_int_rc_forwd = 1'h0;
                end
                
                default: begin
                    tlp_int_rc_state = RC_STATE_IDLE;
                    tlp_int_rc_forwd = 1'h0;
                end
            endcase
        end
    end

    //----------------------------------------------------------------------------
    // Control flags (shift/extra) for TLP data sync
    //----------------------------------------------------------------------------
    reg  [        4:0] tlp_int_rc_start[MUX_CNT-1:0];
    reg  [MUX_CNT-1:0] tlp_int_rc_check;
    reg  [        4:0] tlp_int_rc_shdwd;

    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_check <= {MUX_CNT{1'h0}};
        end else
        if (tlp_int_rc_ready && tlp_int_rc_valid && tlp_int_rc_tlast) begin
            case ({tlp_int_rc_frg})
                1'b1: tlp_int_rc_start[tlp_int_rc_sel] <= 5'hF & (tlp_int_rc_shift[4:0] + {tlp_int_rc_len[1:0],2'h0});
                1'b0: tlp_int_rc_start[tlp_int_rc_sel] <= 5'hF & (tlp_int_rc_shift[3:0] +  tlp_int_rc_bcn[3:0]);
            endcase
            tlp_int_rc_check[tlp_int_rc_sel] <= tlp_int_rc_frg;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_shift_q <= 5'h0;
        end else
        if (tlp_int_rc_ready && tlp_int_rc_valid && tlp_int_rc_tlast) begin
            tlp_int_rc_shift_q <= tlp_int_rc_shift;
        end
    end
    always @(*) begin
        if (rst) begin
            tlp_int_rc_shift = 5'h0;
        end else
        if (tlp_int_rc_check[tlp_int_rc_sel]) begin
            tlp_int_rc_shift = tlp_int_rc_start[tlp_int_rc_sel];
        end else begin
            tlp_int_rc_shift = 5'h0 - tlp_int_rc_lwa[1:0];
        end
    end

    always @(*) begin
        if (!rst && tlp_int_rc_check[tlp_int_rc_sel]) begin
            if (tlp_int_rc_shift[1:0]) begin
                tlp_int_rc_shdwd = {1'h0,tlp_int_rc_shift[3:2],2'h0} + 3'h4;
            end else begin
                tlp_int_rc_shdwd = {1'h0,tlp_int_rc_shift[3:2],2'h0};
            end
        end else begin
            tlp_int_rc_shdwd = 5'h0;
        end
    end

    //----------------------------------------------------------------------------
    wire [3:0] tlp_int_rc_taila = tlp_int_rc_frg ? tlp_int_rc_count[3:0] - 4'hD : tlp_int_rc_bcn[3:0] + tlp_int_rc_lwa[1:0] - 1'h1;
    wire [3:0] tlp_int_rc_tailb = tlp_int_rc_frg ? tlp_int_rc_count[3:0] - 4'h1 : tlp_int_rc_bcn[3:0] + tlp_int_rc_lwa[1:0] + 4'hB;
    reg  [4:0] tlp_int_rc_tailp;

    reg tlp_int_rc_ext_q;
    always @(posedge clk) begin
        if (rst || tlp_int_rc_valid && tlp_int_rc_tlast) begin
            tlp_int_rc_ext_q <= tlp_int_rc_ext1c;
        end
    end

    always @(*) begin
        if (rst || !tlp_int_rc_valid) begin
            tlp_int_rc_tailp = 5'h0;
            tlp_int_rc_ext1c = 1'h0;
        end else begin
            case (tlp_int_rc_count[3:2] - !tlp_int_rc_count[1:0]) // equals to: (tlp_int_rc_count - 1) >> 2
                // count mod 16 == 13~15 or 0, DW-3 has data
                2'b11: begin
                     // using taila to count for actual payload length
                    if (!tlp_int_rc_shift[4:4] && tlp_int_rc_shift[3:2] == 2'b11) begin
                        // shift >= 12, tlp start from 1st cycle
                        tlp_int_rc_tailp = {1'h0,tlp_int_rc_taila} + tlp_int_rc_shift[4:0];
                    end else
                    if (tlp_int_rc_count >> 5 || tlp_int_rc_count[4:4] && tlp_int_rc_count[3:0]) begin
                        // shift < 12 and count > 16, start from 2nd cycle, tlp_len + 16
                        tlp_int_rc_tailp = {1'h1,tlp_int_rc_taila} + tlp_int_rc_shift[4:0];
                    end else begin
                        // shift < 12 and count == 13~16, tlp early completed in same cycle of tlast
                        tlp_int_rc_tailp = {1'h0,tlp_int_rc_taila} + tlp_int_rc_shift[4:0];
                    end
                end
                default: begin
                    // using tailb to count from where payload ends
                    if (!tlp_int_rc_shift[4:4] && tlp_int_rc_shift[3:2] == 2'b11) begin
                        // shift >= 12, cached data shift into 1st cycle (3xDW)
                        tlp_int_rc_tailp = {1'h0,tlp_int_rc_tailb} + (tlp_int_rc_shift[4:0] - 4'hC);
                    end else begin
                        // shift <= 11, no enough data for 1st cycle, tlp_len + shift + (1x DW from 1st cycle)
                        tlp_int_rc_tailp = {1'h0,tlp_int_rc_tailb} + (tlp_int_rc_shift[4:0] + 4'h4);
                    end
                end
            endcase

            if (tlp_int_rc_tlast) begin
                tlp_int_rc_ext1c = tlp_int_rc_tailp[4:4];
            end else begin
                tlp_int_rc_ext1c = tlp_int_rc_ext_q;
            end
        end
    end

    //----------------------------------------------------------------------------
    // Values saved for shifted (TLP RC) packet content
    //----------------------------------------------------------------------------
    reg [      255:0] tlp_int_rc_value, tlp_int_rc_value_q;
    reg [      127:0] tlp_int_rc_cache[MUX_CNT-1:0];
    reg [MUX_CNT-1:0] tlp_int_rc_carry;

    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_value_q <= 255'h0;
        end else
        if (tlp_int_rc_valid && tlp_int_rc_ready) begin
            tlp_int_rc_value_q <= tlp_int_rc_value;
        end
    end

    always @(*) begin
        if (rst) begin
            tlp_int_rc_value = 255'h0;
        end else
        if (tlp_int_rc_valid) begin
            case (tlp_int_rc_state_q)
                RC_STATE_HEND, RC_STATE_HFRG,                                                                                  
                RC_STATE_EOT1, RC_STATE_EOP1,                                                                                  
                RC_STATE_EOT3, RC_STATE_EOP3, 
                RC_STATE_IDLE: begin
                    tlp_int_rc_value = {tlp_int_rc_tdata_rev[96+:32],224'h0};
                    case (tlp_int_rc_shdwd[4:2])
                        3'h1: tlp_int_rc_value[223-: 32] = tlp_int_rc_cache[tlp_int_rc_sel][0+: 32];
                        3'h2: tlp_int_rc_value[223-: 64] = tlp_int_rc_cache[tlp_int_rc_sel][0+: 64];
                        3'h3: tlp_int_rc_value[223-: 96] = tlp_int_rc_cache[tlp_int_rc_sel][0+: 96];
                        3'h4: tlp_int_rc_value[223-:128] = tlp_int_rc_cache[tlp_int_rc_sel][0+:128];
                    endcase
                end
                default: begin
                    if (tlp_int_rc_valid) begin
                        tlp_int_rc_value = {tlp_int_rc_tdata_rev,tlp_int_rc_value_q[128+:128]};
                    end else begin
                        tlp_int_rc_value =  tlp_int_rc_value_q;
                    end
                end
            endcase
        end
    end

    //----------------------------------------------------------------------------
    reg [127:0] tlp_int_rc_saved, tlp_int_rc_saved_q;

    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_carry <= {MUX_CNT{1'h0}};
        end else begin
            case (tlp_int_rc_state)
                RC_STATE_HOUT, RC_STATE_HEAD,
                RC_STATE_HEND, RC_STATE_HFRG: begin
                    case (tlp_int_rc_shdwd[3:2])
                        2'b00: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-: 32];
                        2'b01: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-: 64];
                        2'b10: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-: 96];
                        2'b11: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-:128];
                    endcase
                    if (tlp_int_rc_state == RC_STATE_HEND) begin
                        tlp_int_rc_carry[tlp_int_rc_sel] <= 1'h0;
                    end else begin
                        tlp_int_rc_carry[tlp_int_rc_sel] <= 1'h1;
                    end
                end
                RC_STATE_EOT2, RC_STATE_EOP2,
                RC_STATE_DATA: begin
                    case (tlp_int_rc_shdwd[3:2])
                        2'b00: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-: 32];
                        2'b01: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-: 64];
                        2'b10: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-: 96];
                        2'b11: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[255-:128];
                    endcase
                    tlp_int_rc_carry[tlp_int_rc_sel] <= 1'h1;
                end
                RC_STATE_EOT1: begin
                    case (tlp_int_rc_shdwd[3:2])
                        2'b00: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[ 96+:128];
                        2'b01: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[ 64+:128];
                        2'b10: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[ 32+:128];
                        2'b11: tlp_int_rc_cache[tlp_int_rc_sel] <= tlp_int_rc_value[128+:128];
                    endcase
                end
                RC_STATE_EOP1, RC_STATE_EOP3: begin
                    tlp_int_rc_cache[tlp_int_rc_sel] <= 128'h0;
                    tlp_int_rc_carry[tlp_int_rc_sel] <=   1'h0;
                end
            endcase
        end
    end

    always @(posedge clk) tlp_int_rc_saved_q <= tlp_int_rc_saved;
    always @(*) begin
        if (rst) begin
            tlp_int_rc_saved = 128'h0;
        end else begin
            case (tlp_int_rc_state_q)
                default: begin
                    tlp_int_rc_saved = 128'h0;
                    if (tlp_int_rc_carry[tlp_int_rc_sel]) begin
                        tlp_int_rc_saved = tlp_int_rc_cache[tlp_int_rc_sel];
                    end
                end
                RC_STATE_IDLE: begin
                    tlp_int_rc_saved = tlp_int_rc_saved_q;
                end
            endcase
        end
    end

    //----------------------------------------------------------------------------
    reg [15:0] tlp_int_rc_msk, tlp_int_rc_msk_q;

    always @(posedge clk) begin
        if (rst) begin
            tlp_int_rc_msk_q <= 16'h0;
        end else begin
            case (tlp_int_rc_state)
                RC_STATE_EOP2: begin
                    case (tlp_int_rc_tailp[3:0])
                        4'h0: tlp_int_rc_msk_q <= { 1{1'h1}};
                        4'h1: tlp_int_rc_msk_q <= { 2{1'h1}};
                        4'h2: tlp_int_rc_msk_q <= { 3{1'h1}};
                        4'h3: tlp_int_rc_msk_q <= { 4{1'h1}};

                        4'h4: tlp_int_rc_msk_q <= { 5{1'h1}};
                        4'h5: tlp_int_rc_msk_q <= { 6{1'h1}};
                        4'h6: tlp_int_rc_msk_q <= { 7{1'h1}};
                        4'h7: tlp_int_rc_msk_q <= { 8{1'h1}};

                        4'h8: tlp_int_rc_msk_q <= { 9{1'h1}};
                        4'h9: tlp_int_rc_msk_q <= {10{1'h1}};
                        4'hA: tlp_int_rc_msk_q <= {11{1'h1}};
                        4'hB: tlp_int_rc_msk_q <= {12{1'h1}};

                        4'hC: tlp_int_rc_msk_q <= {13{1'h1}};
                        4'hD: tlp_int_rc_msk_q <= {14{1'h1}};
                        4'hE: tlp_int_rc_msk_q <= {15{1'h1}};
                        4'hF: tlp_int_rc_msk_q <= {16{1'h1}};
                    endcase
                end
                default: begin
                    tlp_int_rc_msk_q <= tlp_int_rc_msk;
                end
            endcase
        end
    end
    always @(*) begin
        if (rst) begin
            tlp_int_rc_msk = 16'h0;
        end else begin
            case (tlp_int_rc_state)
                RC_STATE_HEND, RC_STATE_EOP1: begin
                    case (tlp_int_rc_tailp[3:0])
                        4'h0: tlp_int_rc_msk = { 1{1'h1}};
                        4'h1: tlp_int_rc_msk = { 2{1'h1}};
                        4'h2: tlp_int_rc_msk = { 3{1'h1}};
                        4'h3: tlp_int_rc_msk = { 4{1'h1}};

                        4'h4: tlp_int_rc_msk = { 5{1'h1}};
                        4'h5: tlp_int_rc_msk = { 6{1'h1}};
                        4'h6: tlp_int_rc_msk = { 7{1'h1}};
                        4'h7: tlp_int_rc_msk = { 8{1'h1}};

                        4'h8: tlp_int_rc_msk = { 9{1'h1}};
                        4'h9: tlp_int_rc_msk = {10{1'h1}};
                        4'hA: tlp_int_rc_msk = {11{1'h1}};
                        4'hB: tlp_int_rc_msk = {12{1'h1}};

                        4'hC: tlp_int_rc_msk = {13{1'h1}};
                        4'hD: tlp_int_rc_msk = {14{1'h1}};
                        4'hE: tlp_int_rc_msk = {15{1'h1}};
                        4'hF: tlp_int_rc_msk = {16{1'h1}};
                    endcase
                end
                RC_STATE_EOP3: begin
                    tlp_int_rc_msk = tlp_int_rc_msk_q;
                end
                default: begin
                    tlp_int_rc_msk = {16{1'h1}};
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    reg  tlp_int_rc_x1c; // Extra +1 cycle

    always @(posedge clk) begin
        if (rst || tlp_int_rc_frg) begin
            tlp_int_rc_x1c <= 1'h0;
        end else
        if (!tlp_int_rc_valid || tlp_int_rc_valid && tlp_int_rc_ready) begin
            case (tlp_int_rc_state)
                default: tlp_int_rc_x1c <= 1'h0;
                RC_STATE_EOP2: begin
                    tlp_int_rc_x1c <= 1'h1;
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // TLP RC Payload Rx to Virtq
    //////////////////////////////////////////////////////////////////////////////
    function [127:0] tlp_int_rx_val(input [127:0] a, input [127:0] b, input [4:0] n) ;
        case (n)
            5'h00: tlp_int_rx_val = a;
            
            5'h01, 5'h11: tlp_int_rx_val = {a,b[31 :24]};
            5'h02, 5'h12: tlp_int_rx_val = {a,b[31 :16]};
            5'h03, 5'h13: tlp_int_rx_val = {a,b[31 : 8]};
                                       
            5'h04, 5'h14: tlp_int_rx_val = {a,b[31 : 0]};
            5'h05, 5'h15: tlp_int_rx_val = {a,b[63 :24]};
            5'h06, 5'h16: tlp_int_rx_val = {a,b[63 :16]};
            5'h07, 5'h17: tlp_int_rx_val = {a,b[63 : 8]};
                                       
            5'h08, 5'h18: tlp_int_rx_val = {a,b[63 : 0]};
            5'h09, 5'h19: tlp_int_rx_val = {a,b[95 :24]};
            5'h0A, 5'h1A: tlp_int_rx_val = {a,b[95 :16]};
            5'h0B, 5'h1B: tlp_int_rx_val = {a,b[95 : 8]};
                                       
            5'h0C, 5'h1C: tlp_int_rx_val = {a,b[95 : 0]};
            5'h0D, 5'h1D: tlp_int_rx_val = {a,b[127:24]};
            5'h0E, 5'h1E: tlp_int_rx_val = {a,b[127:16]};
            5'h0F, 5'h1F: tlp_int_rx_val = {a,b[127: 8]};

            5'h10: tlp_int_rx_val = a;
        endcase
    endfunction

    //----------------------------------------------------------------------------
    wire [MUX_CNT-1:0] tlp_int_rx_ready;
    reg                tlp_int_rx_valid;
    reg                tlp_int_rx_tlast;
    reg  [      127:0] tlp_int_rx_tdata;
    reg  [       15:0] tlp_int_rx_tkeep;
    
    //----------------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            tlp_int_rx_tdata = 128'h0;
        end else begin
            case (tlp_int_rc_state)
                RC_STATE_HOUT, RC_STATE_HEND: begin
                    case ({tlp_int_rc_shift[4:4],tlp_int_rc_shift[1:0]})
                        default: begin // tlp_int_rc_shift >= 0
                            tlp_int_rx_tdata = tlp_int_rx_val(tlp_int_rc_value[224+:32], tlp_int_rc_saved, tlp_int_rc_shift);
                        end
                        // tlp_int_rc_shift < 0: start of packet, this will convert dword align to offset align 
                        3'b100: tlp_int_rx_tdata = tlp_int_rc_value[255-:32];
                        3'b101: tlp_int_rx_tdata = tlp_int_rc_value[255-: 8]; // tlp_int_rc_shift == -3
                        3'b110: tlp_int_rx_tdata = tlp_int_rc_value[255-:16]; // tlp_int_rc_shift == -2
                        3'b111: tlp_int_rx_tdata = tlp_int_rc_value[255-:24]; // tlp_int_rc_shift == -1
                    endcase
                end
                RC_STATE_EOT2, RC_STATE_EOP2,
                RC_STATE_EOT1, RC_STATE_EOP1,
                RC_STATE_DATA: begin
                    tlp_int_rx_tdata = tlp_int_rx_val(tlp_int_rc_value[128+:128], tlp_int_rc_saved, 5'h4 + tlp_int_rc_shift  );
                end
                RC_STATE_EOP3: begin
                    tlp_int_rx_tdata = tlp_int_rx_val(tlp_int_rc_value[128+:128], tlp_int_rc_saved, 5'h4 + tlp_int_rc_shift_q);
                end
                default: begin
                    tlp_int_rx_tdata = 128'h0;
                end
            endcase
        end
    end  
            
    always @(*) begin
        if (rst) begin
            tlp_int_rx_tkeep = 16'h0;
            tlp_int_rx_valid =  1'h0;
            tlp_int_rx_tlast =  1'h0;
        end else begin
            case (tlp_int_rc_state)
                default: begin
                    tlp_int_rx_tkeep = 16'h0;
                    tlp_int_rx_tlast =  1'h0;
                    tlp_int_rx_valid =  1'h0;
                end
                RC_STATE_HOUT, RC_STATE_DATA, RC_STATE_EOT2, RC_STATE_EOP2: begin
                    tlp_int_rx_tkeep = {16{1'h1}};
                    tlp_int_rx_tlast = 1'h0;
                    tlp_int_rx_valid = 1'h1;
                end
                RC_STATE_EOT2, RC_STATE_EOP2: begin
                    tlp_int_rx_tkeep = {16{1'h1}};
                    tlp_int_rx_tlast = 1'h0;
                    tlp_int_rx_valid = 1'h1;
                end
                RC_STATE_EOT1: begin
                    tlp_int_rx_tkeep = {16{1'h1}};
                    tlp_int_rx_tlast = 1'h0;

                    if (tlp_int_rc_tailp[3:0] == 4'hF) begin
                        tlp_int_rx_valid = 1'h1;
                    end else begin
                        tlp_int_rx_valid = 1'h0;
                    end
                end
                RC_STATE_EOT3: begin
                    tlp_int_rx_tkeep = {16{1'h1}};
                    tlp_int_rx_tlast = 1'h0;
                    tlp_int_rx_valid = 1'h0;
                end
                RC_STATE_HEND, RC_STATE_EOP1, RC_STATE_EOP3: begin
                    tlp_int_rx_tkeep = tlp_int_rc_msk;
                    tlp_int_rx_tlast = 1'h1;
                    tlp_int_rx_valid = 1'h1;
                end
            endcase
        end
    end

    //----------------------------------------------------------------------------
    reg [7:0] tlp_int_rx_sel, tlp_int_rx_sel_q;
    
    always @(posedge clk) begin
        tlp_int_rx_sel_q <= tlp_int_rx_sel;
    end
    
    always @(*) begin
        if (rst) begin
            tlp_int_rx_sel = 8'h0;
        end else
        if (tlp_int_rc_forwd) begin
            tlp_int_rx_sel = tlp_int_rc_sel;
        end else begin
            tlp_int_rx_sel = tlp_int_rx_sel_q;
        end
    end
    
    //----------------------------------------------------------------------------
    genvar n2;
    generate
    for (n2 = 0; n2 < MUX_CNT; n2 = n2 + 1) begin
        assign tlp_int_rx_ready[n2] = tlp_rx_ready[n2] || !tlp_rx_valid[n2];
        always @(posedge clk) begin
            if (rst || tlp_int_rx_sel != n2) begin
                tlp_rx_valid[n2] <= 1'h0;
                tlp_rx_tlast[n2] <= 1'h0;
            end else
            if (tlp_rx_valid[n2] && tlp_rx_ready[n2] || !tlp_rx_valid[n2]) begin
                tlp_rx_valid[n2] <= tlp_int_rx_valid;
                tlp_rx_tlast[n2] <= tlp_int_rx_tlast;
            end
        end
    end
    endgenerate

    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            tlp_rx_tdata <= 128'h0;
            tlp_rx_tkeep <=  16'h0;
        end else begin
            tlp_rx_tdata <= tlp_int_rx_tdata;
            tlp_rx_tkeep <= tlp_int_rx_tkeep;
        end
    end
    
    //----------------------------------------------------------------------------
    assign tlp_int_rc_ready = (tlp_int_rc_ign || tlp_int_rx_ready[tlp_int_rc_sel]) && tlp_int_rc_forwd;

endmodule

