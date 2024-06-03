`timescale 1ns / 1ps

module eth_virtio_cmd_rx #(
    parameter DEPTH = 1024 
    ) (
    input  wire clk,
    input  wire rst,
    
    input  wire [127:0] s_axis_tdata ,
    input  wire [ 15:0] s_axis_tkeep ,
    input  wire         s_axis_tvalid,
    output reg          s_axis_tready,
    input  wire         s_axis_tlast ,
    
    output reg          m_axis_cmd_en,
    output reg  [  7:0] m_axis_class ,
    output reg  [  7:0] m_axis_cmd   ,

    output reg  [127:0] m_axis_tdata ,
    output reg  [ 15:0] m_axis_tkeep ,
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready,
    output reg          m_axis_tlast
    );
 
    function [4:0] cmd_tkeep2n(input [15:0] tkeep);
        case (tkeep)
            16'h0000: cmd_tkeep2n = 5'h00;
            16'h0001: cmd_tkeep2n = 5'h01;
            16'h0003: cmd_tkeep2n = 5'h02;
            16'h0007: cmd_tkeep2n = 5'h03;
            16'h000F: cmd_tkeep2n = 5'h04;
            16'h001F: cmd_tkeep2n = 5'h05;
            16'h003F: cmd_tkeep2n = 5'h06;
            16'h007F: cmd_tkeep2n = 5'h07;
            16'h00FF: cmd_tkeep2n = 5'h08;
            16'h01FF: cmd_tkeep2n = 5'h09;
            16'h03FF: cmd_tkeep2n = 5'h0A;
            16'h07FF: cmd_tkeep2n = 5'h0B;
            16'h0FFF: cmd_tkeep2n = 5'h0C;
            16'h1FFF: cmd_tkeep2n = 5'h0D;
            16'h3FFF: cmd_tkeep2n = 5'h0E;
            16'h7FFF: cmd_tkeep2n = 5'h0F;
            16'hFFFF: cmd_tkeep2n = 5'h10;
            default: begin
                cmd_tkeep2n = 5'h10;
            end
        endcase
    endfunction
  
    function [255:0] cmd_value(input [127:0] a, input [127:0] b, input [15:0] k, input [4:0] c);
        reg [127:0] v;
        begin
            case (k)
                16'h0001: v = { 1{8'hFF}} & a; 
                16'h0003: v = { 2{8'hFF}} & a; 
                16'h0007: v = { 3{8'hFF}} & a; 
                16'h000F: v = { 4{8'hFF}} & a; 
                16'h001F: v = { 5{8'hFF}} & a; 
                16'h003F: v = { 6{8'hFF}} & a; 
                16'h007F: v = { 7{8'hFF}} & a; 
                16'h00FF: v = { 8{8'hFF}} & a; 
                16'h01FF: v = { 9{8'hFF}} & a; 
                16'h03FF: v = {10{8'hFF}} & a; 
                16'h07FF: v = {11{8'hFF}} & a; 
                16'h0FFF: v = {12{8'hFF}} & a; 
                16'h1FFF: v = {13{8'hFF}} & a; 
                16'h3FFF: v = {14{8'hFF}} & a; 
                16'h7FFF: v = {15{8'hFF}} & a; 
                16'hFFFF: v = {16{8'hFF}} & a; 
                default: begin
                    v = a;
                end
            endcase

            case (c)
                5'h00: cmd_value =  v;
                5'h01: cmd_value = {v,b[0+:  8]};
                5'h02: cmd_value = {v,b[0+: 16]};
                5'h03: cmd_value = {v,b[0+: 24]};
                5'h04: cmd_value = {v,b[0+: 32]};
                5'h05: cmd_value = {v,b[0+: 40]};
                5'h06: cmd_value = {v,b[0+: 48]};
                5'h07: cmd_value = {v,b[0+: 56]};
                5'h08: cmd_value = {v,b[0+: 64]};
                5'h09: cmd_value = {v,b[0+: 72]};
                5'h0A: cmd_value = {v,b[0+: 80]};
                5'h0B: cmd_value = {v,b[0+: 88]};
                5'h0C: cmd_value = {v,b[0+: 96]};
                5'h0D: cmd_value = {v,b[0+:104]};
                5'h0E: cmd_value = {v,b[0+:112]};
                5'h0F: cmd_value = {v,b[0+:120]};
                default: begin
                    cmd_value = {v,b};
                end
            endcase
        end
    endfunction

    function [15:0] cmd_tkeep(input [4:0] cnt);
        case (cnt)
            5'h0: cmd_tkeep = 16'hFFFF;
            5'h1: cmd_tkeep = 16'h0001;
            5'h2: cmd_tkeep = 16'h0003;
            5'h3: cmd_tkeep = 16'h0007;
            5'h4: cmd_tkeep = 16'h000F;
            5'h5: cmd_tkeep = 16'h001F;
            5'h6: cmd_tkeep = 16'h003F;
            5'h7: cmd_tkeep = 16'h007F;
            5'h8: cmd_tkeep = 16'h00FF;
            5'h9: cmd_tkeep = 16'h01FF;
            5'hA: cmd_tkeep = 16'h03FF;
            5'hB: cmd_tkeep = 16'h07FF;
            5'hC: cmd_tkeep = 16'h0FFF;
            5'hD: cmd_tkeep = 16'h1FFF;
            5'hE: cmd_tkeep = 16'h3FFF;
            5'hF: cmd_tkeep = 16'h7FFF;
            default: begin
                cmd_tkeep = 16'hFFFF;
            end
        endcase
    endfunction

    ///////////////////////////////////////////////////////////////////////////
    reg  [127:0] s_axis_int_tdata ;
    reg  [ 15:0] s_axis_int_tkeep ;
    wire         s_axis_int_tvalid;
    wire         s_axis_int_tready;
    reg          s_axis_int_tlast ;
 
    reg  [127:0] s_axis_val;
    reg  [  4:0] s_axis_cnt;
    reg          s_axis_x1c;
    reg          s_axis_eof;

    wire        s_axis_int_update = s_axis_int_tvalid && s_axis_int_tready;
    wire        s_axis_update     = s_axis_tvalid && s_axis_tready;
    wire [ 4:0] s_axis_tkeep2n    = s_axis_tvalid ? cmd_tkeep2n(s_axis_tkeep) : 5'h0;
    wire [ 5:0] s_axis_next_cnt   = {1'h0,s_axis_tkeep2n} + s_axis_cnt;

    always @(posedge clk) begin
        if (rst) begin
            s_axis_int_tdata <= 128'h0;
            s_axis_int_tkeep <=  16'h0;
            s_axis_int_tlast <=   1'h0;

            s_axis_val <= 128'h0;
            s_axis_cnt <=   5'h0;
            s_axis_x1c <=   1'h0;
            s_axis_eof <=   1'h0;
        end else
        if (s_axis_x1c && s_axis_int_tready) begin
            s_axis_int_tdata <= s_axis_val;
            s_axis_int_tkeep <= {16{1'h1}} >> (5'h10 - s_axis_cnt[3:0]);
            s_axis_int_tlast <= 1'h1;

            s_axis_val <= 128'h0;
            s_axis_cnt <= 5'h0;
            s_axis_x1c <= 1'h0;
        end else
        if (s_axis_eof && s_axis_int_tready) begin
            s_axis_int_tdata <= 128'h0;
            s_axis_int_tkeep <=  16'h0;
            s_axis_int_tlast <=   1'h0;

            s_axis_val <= 128'h0;
            s_axis_cnt <=   5'h0;
            s_axis_x1c <=   1'h0;
            s_axis_eof <=   1'h0;
        end else begin
            case ({s_axis_update,s_axis_int_update})
                2'b11: begin
                    {s_axis_val,s_axis_int_tdata} <= cmd_value(s_axis_tdata, s_axis_val, s_axis_tkeep, s_axis_cnt - 5'h10);

                    if (s_axis_tlast && !(s_axis_next_cnt[5:5] && s_axis_next_cnt[4:0])) begin
                        // tlast with next_cnt - 16 <= 16, transmission done
                        s_axis_cnt       <= 5'h0;
                        s_axis_x1c       <= 1'h0;
                        s_axis_eof       <= 1'h1;

                        s_axis_int_tkeep <= s_axis_next_cnt[3:0] ? {16{1'h1}} >> (5'h10 - s_axis_next_cnt[3:0]) : {16{1'h1}};
                        s_axis_int_tlast <= 1'h1;
                    end else 
                    if (s_axis_tlast) begin
                        // tlast with 1x extra cycle, s_axis_x1c <= 1
                        s_axis_cnt       <= s_axis_next_cnt - 5'h10;
                        s_axis_x1c       <= 1'h1;
                        s_axis_eof       <= 1'h1;

                        s_axis_int_tkeep <= {16{1'h1}};
                        s_axis_int_tlast <= 1'h0;
                    end else begin
                        // normal payload
                        s_axis_cnt       <= s_axis_cnt - 5'h10 + s_axis_tkeep2n;
                        s_axis_x1c       <= 1'h0;
                        s_axis_eof       <= 1'h0;

                        s_axis_int_tkeep <= {16{1'h1}};
                        s_axis_int_tlast <= 1'h0;
                    end
                end
                2'b10: begin
                    if (!s_axis_int_tvalid) begin
                        {s_axis_val,s_axis_int_tdata} <= cmd_value(s_axis_tdata, s_axis_int_tdata, s_axis_tkeep, s_axis_cnt);

                        // switch case with tlast (input side) and next_cnt == 5'h10
                        case ({s_axis_tvalid && s_axis_tlast,s_axis_next_cnt[4:4] && !s_axis_next_cnt[3:0]})
                            2'b11: begin
                                s_axis_int_tkeep <= cmd_tkeep(s_axis_next_cnt[4:0]);
                                s_axis_int_tlast <= 1'h1;
                            end 
                            2'b01, 2'b00: begin
                                s_axis_int_tkeep <= {16{1'h1}};
                                s_axis_int_tlast <= 1'h0;
                            end
                            2'b10: begin
                                s_axis_int_tkeep <= cmd_tkeep(s_axis_next_cnt[4:0]);
                                s_axis_int_tlast <= !s_axis_next_cnt[4:4] || s_axis_next_cnt[4:0] == 5'h10;
                            end
                        endcase
                        s_axis_cnt <= s_axis_tkeep2n + s_axis_cnt;
                    end else begin
                        s_axis_val <= cmd_value(s_axis_tdata, s_axis_val, s_axis_tkeep, s_axis_cnt - 5'h10);
                        s_axis_cnt <= s_axis_tkeep2n + s_axis_cnt;
                    end

                    if (s_axis_tvalid && s_axis_tlast) begin
                        s_axis_x1c <= s_axis_next_cnt[4:4] && s_axis_next_cnt[3:0];
                        s_axis_eof <= 1'h1;
                    end
                end
                2'b01: begin
                    if (s_axis_cnt[4:4] && !s_axis_cnt[3:0]) begin // cnt == 16
                        s_axis_int_tdata <= s_axis_val;
                        s_axis_int_tkeep <= s_axis_cnt[3:0] ? {16{1'h1}} >> (5'h10 - s_axis_cnt[3:0]) : {16{1'h1}};
                        s_axis_int_tlast <= s_axis_eof;

                        s_axis_cnt       <= 5'h0;
                        s_axis_eof       <= 1'h0;
                    end else begin
                        s_axis_int_tdata <= s_axis_val;
                        s_axis_int_tkeep <= {16{1'h1}};
                        s_axis_int_tlast <= 1'h0;
                        s_axis_val       <= 128'h0;
                        s_axis_cnt       <= s_axis_cnt - 5'h10;
                    end
                end
            endcase
        end
    end

    assign s_axis_int_tvalid = s_axis_cnt[4:4] || s_axis_eof;

    always @(*) begin
        if (rst || s_axis_eof) begin
            s_axis_tready = 1'h0;
        end else
        if (s_axis_tvalid && !s_axis_int_update) begin
            if (s_axis_next_cnt[5:5]) begin
                s_axis_tready = 1'h0;
            end else begin
                s_axis_tready = 1'h1;
            end
        end else begin
            s_axis_tready = 1'h1;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    wire [127:0] m_axis_int_tdata ;
    wire [ 15:0] m_axis_int_tkeep ;
    wire         m_axis_int_tvalid;
    reg          m_axis_int_tready;
    wire         m_axis_int_tlast ;
    
    axis_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(128),
        .KEEP_ENABLE(1),
        .LAST_ENABLE(1),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .FRAME_FIFO(0)
    )
    axis_fifo_inst (
        .clk(clk),
        .rst(rst),
        
        .s_axis_tdata (s_axis_int_tdata ),
        .s_axis_tkeep (s_axis_int_tkeep ),
        .s_axis_tvalid(s_axis_int_tvalid),
        .s_axis_tready(s_axis_int_tready),
        .s_axis_tlast (s_axis_int_tlast ),
        
        .m_axis_tdata (m_axis_int_tdata ),
        .m_axis_tkeep (m_axis_int_tkeep ),
        .m_axis_tvalid(m_axis_int_tvalid),
        .m_axis_tready(m_axis_int_tready),
        .m_axis_tlast (m_axis_int_tlast )
    );
    
    ///////////////////////////////////////////////////////////////////////////
    reg [  7:0] m_axis_state;

    always @(*) begin
        if (rst || m_axis_tvalid && !m_axis_tready) begin
            m_axis_int_tready = 1'h0;
        end else begin
            m_axis_int_tready = 1'h1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            m_axis_cmd_en <=   1'h0;
            m_axis_tdata  <= 128'h0;
            m_axis_tkeep  <=  16'h0;
            m_axis_tvalid <=   1'h0;
            m_axis_tlast  <=   1'h0;
            m_axis_state  <=   8'h0;
        end else
        if (!m_axis_tvalid || m_axis_tready) begin
            case (m_axis_state)
                8'h0: begin
                    m_axis_class  <= m_axis_int_tdata[0+:8];
                    m_axis_cmd    <= m_axis_int_tdata[8+:8];
                    m_axis_cmd_en <= m_axis_int_tvalid;

                    m_axis_tdata  <= m_axis_int_tdata;
                    m_axis_tkeep  <= m_axis_int_tkeep;
                    m_axis_tvalid <= m_axis_int_tvalid;
                    m_axis_tlast  <= m_axis_int_tlast;
                    
                    if (m_axis_int_tvalid && m_axis_int_tlast != 1'h1) begin
                        m_axis_state <= 8'h1;
                    end
                end
                8'h1: begin
                    m_axis_cmd_en     <= 1'h0;
                    
                    m_axis_tdata      <= m_axis_int_tdata;
                    m_axis_tkeep      <= m_axis_int_tkeep;
                    m_axis_tvalid     <= m_axis_int_tvalid;
                    m_axis_tlast      <= 1'h0;
                    
                    if (m_axis_int_tlast) begin
                        m_axis_tlast  <= 1'h1;
                        m_axis_state  <= 8'h0;
                    end
                end
            endcase
        end
    end

endmodule

