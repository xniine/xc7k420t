`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2022 08:21:27 PM
// Design Name: 
// Module Name: ila_cache
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

module ila_cache #(
    parameter DEPTH = 256,
    parameter WIDTH = 32,
    parameter INDEX = $clog2(DEPTH+1)
    ) (
    input  wire             clock,
    input  wire             reset,
    
    output reg  [INDEX-1:0] total,
    input  wire             valid,
    input  wire [WIDTH-1:0] probe,
    
    output reg              error,
    input  wire             flush,
    output reg  [INDEX-1:0] index,
    output reg  [WIDTH-1:0] value
    );
    
    reg  [WIDTH-1:0] cache [DEPTH-1:0];
    reg  [INDEX-1:0] c_max;
    reg  [INDEX-1:0] c_min;
    reg              c_out;
    reg  [INDEX-1:0] c_idx;
    
    always @(posedge clock) begin
        if (valid) begin
            cache[c_max] <= probe;
            
            if (c_max + 1'h1 == c_min || !c_min && c_max == DEPTH-1) begin
                c_max <= c_min;
                
                if (c_min == DEPTH-1) begin
                    c_min <= {INDEX{1'h0}};
                end else begin
                    c_min <= c_min + 1'h1;
                end
                error <= 1'h1;
            end else begin
                total <= total + 1'h1;
                
                if (c_max == DEPTH-1) begin
                    c_max <= {INDEX{1'h0}};
                end else begin
                    c_max <= c_max + 1'h1;
                end
            end
        end 
        
        if (flush && c_min != c_max) begin
            c_idx <= c_min;
            c_out <=  1'h1;
            error <=  1'h0;
        end else
        if (c_out) begin
            if (c_idx + 1'h1 == c_max || !c_max && c_idx == DEPTH-1) begin
                c_idx <= {INDEX{1'h0}};
                total <= {INDEX{1'h0}};
                c_max <= {INDEX{1'h0}};
                c_min <= {INDEX{1'h0}};
                c_out <= 1'h0;
            end else begin
                c_idx <= c_idx + 1'h1;
                if (c_idx == DEPTH-1) begin
                    c_idx <= {INDEX{1'h0}};
                end
            end
        end
        
        if (reset) begin
            c_idx <= {INDEX{1'h0}};
            total <= {INDEX{1'h0}};
            c_max <= {INDEX{1'h0}};
            c_min <= {INDEX{1'h0}};
            c_out <= 1'h0;
            error <= 1'h0;
        end
    end
    
    always @(posedge clock) begin
        if (!reset && c_out) begin
            value <= cache[c_idx];
            index <= c_idx;
        end else begin
            value <= {WIDTH{1'h0}};
            index <= {INDEX{1'h0}};
        end
    end
    
endmodule
