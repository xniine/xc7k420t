`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2023 06:09:08 PM
// Design Name: 
// Module Name: clock_mon
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


module clock_mon (
    input  wire        rst0_in,
    input  wire        clk0_in,
    input  wire [31:0] frq0_in,
    
    input  wire        rst1_in,
    input  wire        clk1_in,
    output reg  [31:0] frq1_out
    );
    
    reg [31:0] clk_cnt0;
    reg        clk_tick;
    
    always @(posedge clk0_in) begin
        if (rst0_in) begin
            clk_tick <= 1'h0;
            clk_cnt0 <= 'h0;
        end else
        if (clk_cnt0 == frq0_in) begin
            clk_tick <= !clk_tick;
            clk_cnt0 <= 'h0;
        end else begin
            clk_cnt0 <= clk_cnt0 + 1'h1;
        end
    end
    
    wire clk_tock;
    xpm_cdc_single xpm_cdc_single_inst (
      .dest_out(clk_tock),
      .dest_clk(clk1_in ),
      .src_clk (clk0_in ),
      .src_in  (clk_tick)
    ); 
    
    reg [31:0] clk_cnt1;
    reg        clk_trig;
    
    always @(posedge clk1_in) begin
        if (rst1_in) begin
            clk_trig <= 1'h0;
            clk_cnt1 <=  'h0;
            frq1_out <=  'h0;
        end else
        if (clk_trig != clk_tock) begin
            clk_trig <= clk_tock;
            clk_cnt1 <= 'h0;
            frq1_out <= clk_cnt1;
        end else begin
            clk_cnt1 <= clk_cnt1 + 1'h1;
        end
    end
    
endmodule
