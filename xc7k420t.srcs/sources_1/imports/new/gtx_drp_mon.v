`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2021 09:45:42 AM
// Design Name: 
// Module Name: gtx_drp_mon
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


module gtx_drp_mon #(
    parameter N = 4
    ) (
    input   wire [   N-1:0] rst           ,
    input   wire [   N-1:0] rx_block_lock ,
  
    input   wire [   N-1:0] gtx_drpclk    ,
    output  reg  [ 9*N-1:0] gtx_drpaddr   ,
    output  reg  [16*N-1:0] gtx_drpdi     ,
    output  reg  [   N-1:0] gtx_drpen     ,
    output  reg  [   N-1:0] gtx_drpwe     ,
    input   wire [   N-1:0] gtx_drprdy    ,
  
    input   wire [   N-1:0] gtx_reset_done,
    output  wire [   N-1:0] gtx_reset_out
    );

    localparam STATE_GTX_START_UP_1 = 4'h0;
    localparam STATE_GTX_INIT_DELAY = 4'h1;
    localparam STATE_GTX_INIT_CFG_1 = 4'h2;
    localparam STATE_GTX_INIT_CFG_2 = 4'h3;
    localparam STATE_GTX_INIT_END_1 = 4'h4;
    localparam STATE_GTX_LOCK_DELAY = 4'h5;
    localparam STATE_GTX_LOCK_CFG_1 = 4'h6;
    localparam STATE_GTX_LOCK_CFG_2 = 4'h7;
    localparam STATE_GTX_LOCK_CHK_1 = 4'h8;
    
    reg  [N-1:0] gtx_cfg_ready;
    reg  [  3:0] gtx_cfg_state [N-1:0];
    reg  [ 11:0] gtx_cfg_delay [N-1:0];
    reg  [  8:0] gtx_drp_delay [N-1:0];
    
    generate
    genvar n;
    for (n = 0; n < N; n = n + 1) begin
        always @(posedge gtx_drpclk[n]) begin
            gtx_cfg_ready[n] <= 1'b0;
            gtx_drpwe    [n] <= 1'b0;
            gtx_drpen    [n] <= 1'b0;
            
            case ({gtx_cfg_state[n]})
                STATE_GTX_START_UP_1: begin
                    if (gtx_reset_done[n]) begin
                        gtx_cfg_state[n] <= STATE_GTX_INIT_DELAY;
                        gtx_cfg_delay[n] <= 'h0;
                    end
                end
                STATE_GTX_INIT_DELAY: begin
                    if (&gtx_cfg_delay[n]) begin
                        gtx_cfg_state[n] <= STATE_GTX_INIT_CFG_1;
                        gtx_cfg_delay[n] <= 'h0;
                    end else begin
                        gtx_cfg_delay[n] <= gtx_cfg_delay[n] + 1'b1;
                    end
                end
                STATE_GTX_INIT_CFG_1: begin
                    gtx_drpaddr [ 9*n+: 9] <= 9'hAB;
                    gtx_drpdi   [16*n+:16] <= 16'h8000;
                    gtx_drpwe          [n] <=  1'b1;
                    gtx_drpen          [n] <=  1'b1;
                    gtx_cfg_state      [n] <= STATE_GTX_INIT_CFG_2;
                end
                STATE_GTX_INIT_CFG_2: begin
                    if (gtx_drprdy[n]) begin
                        gtx_drpaddr [ 9*n+: 9] <=  9'hA9;
                        gtx_drpdi   [16*n+:16] <= 16'h1040;
                        gtx_drpwe          [n] <=  1'b1;
                        gtx_drpen          [n] <=  1'b1;
                        gtx_cfg_state      [n] <= STATE_GTX_INIT_END_1;
                        gtx_drp_delay      [n] <=  1'b0;
                    end else
                    if (&gtx_drp_delay[n]) begin
                        gtx_cfg_state[n] <= STATE_GTX_START_UP_1;
                        gtx_drp_delay[n] <= 1'b0;
                    end else begin
                        gtx_drp_delay[n] <= gtx_drp_delay[n] + 1'b1;
                    end
                end
                STATE_GTX_INIT_END_1: begin
                    if (gtx_drprdy[n]) begin
                        gtx_cfg_ready[n] <= 1'b1;
                        gtx_cfg_delay[n] <=  'h0;
                        gtx_cfg_state[n] <= STATE_GTX_LOCK_CFG_1;
                        gtx_drp_delay[n] <= 1'b0;
                    end else
                    if (&gtx_drp_delay[n]) begin
                        gtx_cfg_state[n] <= STATE_GTX_START_UP_1;
                        gtx_drp_delay[n] <= 1'b0;
                    end else begin
                        gtx_drp_delay[n] <= gtx_drp_delay[n] + 1'b1;
                    end
                end
                STATE_GTX_LOCK_CFG_1: begin
                    if (rx_block_lock[n]) begin
                        gtx_drpaddr [ 9*n+: 9] <=  9'hA9;
                        gtx_drpdi   [16*n+:16] <= 16'h1020;
                        gtx_drpwe          [n] <=  1'b1;
                        gtx_drpen          [n] <=  1'b1;
                        gtx_cfg_state      [n] <= STATE_GTX_LOCK_CFG_2;
                    end
                end
                STATE_GTX_LOCK_CFG_2: begin
                    if (gtx_drprdy[n]) begin
                        gtx_cfg_ready[n] <= 1'b1;
                        gtx_cfg_state[n] <= STATE_GTX_LOCK_DELAY;
                        gtx_drp_delay[n] <= 1'b0;
                    end else
                    if (&gtx_drp_delay[n]) begin
                        gtx_cfg_state[n] <= STATE_GTX_START_UP_1;
                        gtx_drp_delay[n] <= 1'b0;
                    end else begin
                        gtx_drp_delay[n] <= gtx_drp_delay[n] + 1'b1;
                    end
                end
                STATE_GTX_LOCK_DELAY: begin
                    if (&gtx_cfg_delay[n]) begin
                        gtx_cfg_state[n] <= STATE_GTX_LOCK_CHK_1;
                        gtx_cfg_delay[n] <= 'h0;
                    end else begin
                        gtx_cfg_delay[n] <= gtx_cfg_delay[n] + 1'b1;
                    end
                end
                STATE_GTX_LOCK_CHK_1: begin
                    if (!rx_block_lock[n]) begin
                        gtx_drpaddr  [ 9*n+: 9] <=  9'hA9;
                        gtx_drpdi    [16*n+:16] <= 16'h1040;
                        gtx_drpwe           [n] <=  1'b1;
                        gtx_drpen           [n] <=  1'b1;
                        gtx_cfg_state       [n] <= STATE_GTX_INIT_END_1;
                    end
                end
            endcase
            
            if (rst[n]) begin
                gtx_cfg_state[n] <= STATE_GTX_START_UP_1;
                gtx_cfg_delay[n] <= 'h0;
                gtx_drp_delay[n] <= 'h0;
            end
        end
        assign gtx_reset_out[n] = gtx_cfg_ready[n];
    end
    endgenerate
    
endmodule
