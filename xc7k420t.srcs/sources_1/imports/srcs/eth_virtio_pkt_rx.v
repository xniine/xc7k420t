`timescale 1ns / 1ps

module eth_virtio_pkt_rx #(
    parameter FRAME_FIFO = 1,
    parameter DEPTH = 1024 
    ) (
    input  wire clk,
    input  wire rst,
    
    input  wire [127:0] s_axis_tdata ,
    input  wire [ 15:0] s_axis_tkeep ,
    input  wire         s_axis_tvalid,
    output reg          s_axis_tready,
    input  wire         s_axis_tlast ,
    
    output reg  [127:0] m_axis_tdata ,
    output reg  [ 15:0] m_axis_tkeep ,
    output reg          m_axis_tvalid,
    input  wire [  4:0] m_axis_tmove ,
    output reg          m_axis_tlast
    );

    //////////////////////////////////////////////////////////////////////////////
    wire [127:0] m_axis_int_tdata;
    wire [ 15:0] m_axis_int_tkeep;
    wire         m_axis_int_valid;
    wire         m_axis_int_tlast;
    reg          m_axis_int_ready, m_axis_int_ready_q;

    //----------------------------------------------------------------------------
    reg       m_axis_int_extra_q, m_axis_int_extra;
    reg       m_axis_int_start_q;
    reg [4:0] m_axis_int_shift_q;
    reg [4:0] m_axis_int_shift;

    always @(*) begin
        if (rst) begin
            m_axis_int_shift = 5'h0;
            m_axis_int_ready = 1'h1;
        end else
        if (m_axis_int_start_q && m_axis_int_valid) begin
            m_axis_int_shift = m_axis_tmove;
            m_axis_int_ready = m_axis_tmove != 5'h0;
        end else
        if (m_axis_int_start_q) begin
            m_axis_int_shift = 5'h0;
            m_axis_int_ready = 1'h1;
        end else
        if (m_axis_tmove == 5'h0) begin
            m_axis_int_shift = m_axis_int_shift_q;
            m_axis_int_ready = 1'h0;
        end else
        if (m_axis_int_extra_q) begin
            m_axis_int_shift = m_axis_int_shift_q[3:0] + m_axis_tmove;
            m_axis_int_ready = 1'h0;
        end else
        if (m_axis_int_valid) begin
            m_axis_int_shift = m_axis_int_shift_q[3:0] + m_axis_tmove;
            m_axis_int_ready = m_axis_int_shift[4:4];
        end else begin
            m_axis_int_shift = m_axis_int_shift_q;
            m_axis_int_ready = m_axis_int_ready_q;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            m_axis_int_ready_q <= 1'h1;
            m_axis_int_shift_q <= 5'h0;
        end else begin
            m_axis_int_ready_q <= m_axis_int_ready;
            case (m_axis_int_shift)
                default: m_axis_int_shift_q <= m_axis_int_shift[3:0];
                5'h10  : m_axis_int_shift_q <= 5'h10;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Data cache for AXI-S byte shift
    //------------------------------------------------------------------------
    reg [127:0] m_axis_int_cache_q;
    reg [ 15:0] m_axis_int_tkeep_q;

    always @(posedge clk) begin
        if (rst) begin
            m_axis_int_cache_q <= 128'h0;
            m_axis_int_tkeep_q <=  16'h0;
        end else
        if (m_axis_int_valid && m_axis_int_ready) begin
            m_axis_int_cache_q <= m_axis_int_tdata;
            m_axis_int_tkeep_q <= m_axis_int_tkeep;
        end
    end

    always @(*) begin
        if (rst) begin
            m_axis_tvalid =   1'h0;
            m_axis_tdata  = 128'h0;
            m_axis_tkeep  =  16'h0;
        end else
        if (m_axis_int_extra_q) begin
            m_axis_tvalid = 1'h1;
            m_axis_tdata  = m_axis_int_cache_q >> {m_axis_int_shift_q[3:0],3'h0};
            m_axis_tkeep  = m_axis_int_tkeep_q >>  m_axis_int_shift_q[3:0];
        end else
        if (m_axis_int_valid && m_axis_int_start_q) begin // frame head
            m_axis_tvalid = 1'h1;
            m_axis_tdata  = m_axis_int_tdata;
            m_axis_tkeep  = m_axis_int_tkeep;
        end else
        if (m_axis_int_valid) begin // frame data
            m_axis_tvalid = 1'h1;
            m_axis_tdata  = {m_axis_int_tdata,m_axis_int_cache_q} >> {m_axis_int_shift_q[3:0],3'h0};
            m_axis_tkeep  = {m_axis_int_tkeep,m_axis_int_tkeep_q} >>  m_axis_int_shift_q[3:0];
        end else begin
            m_axis_tvalid =   1'h0;
            m_axis_tdata  = 128'h0;
            m_axis_tkeep  =  16'h0;
        end
    end
        
    //----------------------------------------------------------------------------
    reg m_axis_tlast_q;

    always @(posedge clk) begin
        if (rst) begin
            m_axis_tlast_q <= 1'h0;
        end else begin
            m_axis_tlast_q <= m_axis_tlast;
        end
    end

    always @(*) begin
        if (rst) begin
            m_axis_tlast = 1'h0;
        end else
        if (m_axis_int_valid && m_axis_int_tlast && m_axis_int_ready && !m_axis_int_extra) begin
            m_axis_tlast = 1'h1;
        end else
        if (m_axis_int_extra_q) begin
            m_axis_tlast = !(m_axis_int_tkeep_q >> m_axis_int_shift);
        end else begin
            m_axis_tlast = 1'h0;
        end
    end
    
    //----------------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            m_axis_int_extra = 1'h0;
        end else
        if (m_axis_int_ready && m_axis_int_valid && m_axis_int_tlast) begin
            if (m_axis_int_tkeep >> m_axis_int_shift[3:0]) begin
                m_axis_int_extra = 1'h1;
            end else begin
                m_axis_int_extra = 1'h0;
            end
        end else begin
            m_axis_int_extra = m_axis_int_extra_q;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            m_axis_int_extra_q <= 1'h0;
            m_axis_int_start_q <= 1'h1;
        end else
        if (m_axis_int_extra_q) begin
            if (m_axis_int_tkeep_q >> m_axis_int_shift) begin
                m_axis_int_extra_q <= 1'h1;
                m_axis_int_start_q <= 1'h0;
            end else
            if (s_axis_tready) begin
                m_axis_int_extra_q <= 1'h0;
                m_axis_int_start_q <= 1'h1;
            end
        end else begin
            if (m_axis_int_valid && m_axis_int_tlast && m_axis_int_ready) begin
                m_axis_int_start_q <= !(m_axis_int_tkeep >> m_axis_int_shift[3:0]);
            end else
            if (m_axis_int_valid && m_axis_int_ready) begin
                m_axis_int_start_q <= 1'h0;
            end
            m_axis_int_extra_q <= m_axis_int_extra;
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    reg  [127:0] s_axis_int_tdata;
    reg  [ 15:0] s_axis_int_tkeep;
    reg          s_axis_int_valid;
    reg          s_axis_int_tlast;
    wire         s_axis_int_ready;
  
    axis_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(128),
        .KEEP_ENABLE(1),
        .LAST_ENABLE(1),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .FRAME_FIFO(FRAME_FIFO)
    )
    axis_fifo_inst (
        .clk(clk),
        .rst(rst),

        .s_axis_tdata (s_axis_int_tdata),
        .s_axis_tkeep (s_axis_int_tkeep),
        .s_axis_tvalid(s_axis_int_valid),
        .s_axis_tready(s_axis_int_ready),
        .s_axis_tlast (s_axis_int_tlast),

        .m_axis_tdata (m_axis_int_tdata),
        .m_axis_tkeep (m_axis_int_tkeep),
        .m_axis_tvalid(m_axis_int_valid),
        .m_axis_tready(m_axis_int_ready),
        .m_axis_tlast (m_axis_int_tlast)
    );

    //////////////////////////////////////////////////////////////////////////////

    localparam S_AXIS_IDLE = 8'h0;
    localparam S_AXIS_RECV = 8'h1;
    localparam S_AXIS_EXTR = 8'h2;
    localparam S_AXIS_DONE = 8'h3;

    reg [  7:0] s_axis_state_q;
    reg [127:0] s_axis_cache_q;
    reg [ 15:0] s_axis_bmask_q;

    always @(posedge clk) begin
        if (rst) begin
            s_axis_int_tdata <= 128'h0;
            s_axis_int_tkeep <=  16'h0;
            s_axis_int_valid <=   1'h0;
            s_axis_int_tlast <=   1'h0;
            s_axis_cache_q   <= 128'h0;
            s_axis_bmask_q   <=  16'h0;
            s_axis_state_q   <= S_AXIS_IDLE;
        end else begin
            case (s_axis_state_q)
                S_AXIS_IDLE: begin
                    if (s_axis_tvalid) begin
                        s_axis_int_tdata <= {s_axis_tdata[31:0],96'h0};
                        s_axis_int_tkeep <= {16{1'h1}};
                        s_axis_int_valid <= 1'h1;
                        s_axis_int_tlast <= 1'h0;
                        s_axis_cache_q   <= s_axis_tdata;
                        s_axis_state_q   <= S_AXIS_RECV;
                        s_axis_bmask_q   <= s_axis_tkeep;

                        if (s_axis_tlast && !s_axis_tkeep[15:4]) begin
                            s_axis_int_tkeep <= {s_axis_tkeep[3:0],{12{1'h1}}};
                            s_axis_int_tlast <= 1'h1;
                            s_axis_state_q   <= S_AXIS_DONE;
                        end else
                        if (s_axis_tlast) begin
                            s_axis_state_q   <= S_AXIS_EXTR;
                        end
                    end
                end
                S_AXIS_RECV: begin
                    if (!s_axis_int_valid || s_axis_int_ready) begin
                        if (s_axis_int_valid && s_axis_int_tlast && s_axis_int_ready) begin
                            s_axis_int_valid <= 1'h0;
                            s_axis_state_q   <= S_AXIS_IDLE;
                        end else
                        if (s_axis_tvalid) begin
                            s_axis_int_tdata <= {s_axis_tdata[31:0],s_axis_cache_q[127:32]};
                            s_axis_int_tkeep <= {16{1'h1}};
                            s_axis_int_valid <= 1'h1;
                            s_axis_int_tlast <= 1'h0;
                            s_axis_cache_q   <= s_axis_tdata;
                            s_axis_bmask_q   <= s_axis_tkeep;

                            if (s_axis_tlast && !s_axis_tkeep[15:4]) begin
                                s_axis_int_tkeep <= {s_axis_tkeep[3:0],{12{1'h1}}};
                                s_axis_int_tlast <= 1'h1;
                                s_axis_state_q   <= S_AXIS_DONE;
                            end else
                            if (s_axis_tlast) begin
                                s_axis_state_q   <= S_AXIS_EXTR;
                            end
                        end else begin
                            s_axis_int_valid <= 1'h0;
                            s_axis_int_tlast <= 1'h0;
                        end
                    end
                end
                S_AXIS_EXTR: begin
                    if (!s_axis_int_valid || s_axis_int_ready) begin
                        s_axis_int_tdata <= s_axis_cache_q[127:32];
                        s_axis_int_tkeep <= s_axis_bmask_q[ 15: 4];
                        s_axis_int_valid <= 1'h1;
                        s_axis_int_tlast <= 1'h1;
                        s_axis_state_q   <= S_AXIS_DONE;
                    end
                end
                S_AXIS_DONE: begin
                    if (!s_axis_int_valid || s_axis_int_ready) begin
                        s_axis_int_valid <= 1'h0;
                        s_axis_state_q   <= S_AXIS_IDLE;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        if (rst) begin
            s_axis_tready = 1'h0;
        end else begin
            case (s_axis_state_q)
                S_AXIS_IDLE: s_axis_tready = 1'h1;
                S_AXIS_RECV: s_axis_tready = s_axis_int_ready;
                default: begin
                    s_axis_tready = 1'h0;
                end
            endcase
        end
    end

endmodule
 
