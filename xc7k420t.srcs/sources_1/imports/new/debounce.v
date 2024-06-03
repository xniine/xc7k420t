`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2022 08:43:10 PM
// Design Name: 
// Module Name: debounce
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


module debounce #(
    parameter T = 4096,
    parameter N = 1
    ) (
    input  wire clk,
    input  wire [N-1:0] switch_in,
    output reg  [N-1:0] switch_out,
    output reg  [N-1:0] switch_fall,
    output reg  [N-1:0] switch_raise
    );
    localparam W = $clog2(T);
    
    genvar n1;
    generate
    for (n1 = 0; n1 < N; n1 = n1 + 1) begin
    
    reg [W-1:0] count;
    reg         saved;
    always @(posedge clk) begin
        saved <= switch_in;
    end
    
    always @(posedge clk) begin
        if (count) begin
            count           <= count - 1'h1;
            switch_raise[n1] <= 1'h0;
            switch_fall [n1] <= 1'h0;
        end else begin
            switch_raise[n1] <= !saved &&  switch_in[n1];
            switch_fall [n1] <=  saved && !switch_in[n1];
            switch_out  [n1] <=  switch_in;
        
            if (switch_in[n1] != saved) begin
                count <= T-1;
            end
        end
    end
    
    end
    endgenerate

    
endmodule
