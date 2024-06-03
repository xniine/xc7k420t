`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/27/2022 06:33:37 PM
// Design Name:
// Module Name: pcie_config_space
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

module pcie_config_space #(
    parameter PCI_DATA_WIDTH = 128,
    parameter DATA_IDX_WIDTH = $clog2(PCI_DATA_WIDTH/8)
    ) (
    input                       clk,
    input                       rst,

    input  [PCI_DATA_WIDTH-1:0] rx_cfg_data        ,
    input                       rx_cfg_valid       ,
    input                       rx_cfg_start_flag  ,
    input  [DATA_IDX_WIDTH-1:0] rx_cfg_start_offset,
    input                       rx_cfg_end_flag    ,
    input  [DATA_IDX_WIDTH-1:0] rx_cfg_end_offset  ,
    output                      rx_cfg_ready       ,

    input                       tx_cfg_ready       ,
    output [PCI_DATA_WIDTH-1:0] tx_cfg_data        ,
    output                      tx_cfg_valid       ,
    output                      tx_cfg_start_flag  ,
    output [DATA_IDX_WIDTH-1:0] tx_cfg_start_offset,
    output                      tx_cfg_end_flag    ,
    output [DATA_IDX_WIDTH-1:0] tx_cfg_end_offset
    );

    //============================================================================
    // Shift to align Rx data
    //============================================================================
    reg [DATA_IDX_WIDTH-1:0] rx_shr_offset;
    reg                      rx_shr_valid ;
    reg [PCI_DATA_WIDTH-1:0] rx_shr_data  ;
    reg                      rx_shr_last  ;

    wire                     rx_int_ready ;
    reg                      rx_int_valid ;
    reg [PCI_DATA_WIDTH-1:0] rx_int_data  ;
    reg                      rx_int_last  ;

    always @(posedge clk) begin
        if (rst) begin
            rx_shr_offset <= 0;
            rx_shr_data   <= 0;
            rx_shr_last   <= 0;
            rx_shr_valid  <= 0;
        end else
        if (rx_cfg_valid && rx_cfg_ready) begin
            if (rx_cfg_start_flag && rx_cfg_start_offset) begin
                rx_shr_offset <= rx_cfg_start_offset;
                rx_shr_data   <= rx_cfg_data >> {rx_cfg_start_offset,3'h0};
                rx_shr_last   <= rx_cfg_end_flag;
                rx_shr_valid  <= 1'h1;
            end else begin
                rx_shr_data   <= rx_cfg_data >> rx_shr_offset;
                rx_shr_last   <= rx_cfg_end_flag;
                rx_shr_valid  <= 1'h1;
            end
        end else
        if (rx_int_valid && rx_int_ready && rx_int_last) begin
            rx_shr_offset <= 0;
            rx_shr_data   <= 0;
            rx_shr_last   <= 0;
            rx_shr_valid  <= 0;
        end
    end

    //----------------------------------------------------------------------------
    always @(*) begin
        if (rst) begin
            rx_int_data  = {PCI_DATA_WIDTH{1'h0}};
            rx_int_last  = 1'h0;
            rx_int_valid = 1'h0;
        end else
        if (rx_shr_valid && rx_shr_offset) begin
            if (rx_shr_last) begin
                rx_int_data  = rx_shr_data;
                rx_int_last  = 1'h1;
                rx_int_valid = 1'h1;
            end else
            if (rx_cfg_valid) begin
                rx_int_data  = rx_shr_data | (rx_cfg_data << {rx_shr_offset,3'h0});
                rx_int_last  = rx_shr_last;
                rx_int_valid = rx_cfg_valid;
            end else begin
                rx_int_data  = {PCI_DATA_WIDTH{1'h0}};
                rx_int_last  = 1'h0;
                rx_int_valid = 1'h0;
            end
        end else
        if (rx_cfg_valid) begin
            if (rx_cfg_start_flag && rx_cfg_start_offset) begin
                rx_int_data  = {PCI_DATA_WIDTH{1'h0}};
                rx_int_last  = 1'h0;
                rx_int_valid = 1'h0;
            end else begin
                rx_int_data  = rx_cfg_data;
                rx_int_last  = rx_cfg_end_flag;
                rx_int_valid = 1'h1;
            end
        end else begin
            rx_int_data  = {PCI_DATA_WIDTH{1'h0}};
            rx_int_last  = 1'h0;
            rx_int_valid = 1'h0;
        end
    end

    //============================================================================
    // Input Request
    //============================================================================

    function [31:0] req_value(input [DATA_IDX_WIDTH-1:0] Index);
        req_value = rx_int_data[{Index,5'h0}+:32];
    endfunction

    reg [ 9:0] req_r10   ;
    reg [ 3:0] req_r4    ;
    reg [ 1:0] req_r2    ;
    reg [ 0:0] req_r1    ;

    reg [ 9:0] req_length;
    reg [ 2:0] req_tc    ;
    reg [ 4:0] req_type  ;
    reg [ 1:0] req_fmt   ;
    reg [ 7:0] req_be    ;
    reg [ 7:0] req_tag   ;
    reg [15:0] req_req_id;
    reg [ 9:0] req_reg_nr;
    reg [ 2:0] req_fun_nr;
    reg [ 4:0] req_dev_nr;
    reg [ 7:0] req_bus_nr;

    reg [ 9:0] req_indx;
    reg        req_done;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            req_r10    <= 10'h0;
            req_r4     <=  4'h0;
            req_r2     <=  2'h0;
            req_r1     <=  1'h0;

            req_done   <=  1'h0;
            req_indx   <= 10'h0;

            req_length <= 10'h0;
            req_tc     <=  3'h0;
            req_type   <=  5'h0;
            req_fmt    <=  2'h0;
            req_be     <=  8'h0;
            req_tag    <=  8'h0;
            req_req_id <= 16'h0;
            req_reg_nr <= 10'h0;
            req_fun_nr <=  3'h0;
            req_dev_nr <=  5'h0;
            req_bus_nr <=  8'h0;
        end else
        if (rx_int_valid && rx_int_ready) begin
            req_done   <= 1'h0;

            for (i = 0; i < PCI_DATA_WIDTH/32; i = i + 1) begin
                if (req_indx + i ==  0) {req_fmt,req_type,req_r1,req_tc,req_r10,req_length        } <= req_value(req_indx + i);
                if (req_indx + i ==  1) {req_req_id,req_tag,req_be                                } <= req_value(req_indx + i);
                if (req_indx + i ==  2) {req_bus_nr,req_dev_nr,req_fun_nr,req_r4,req_reg_nr,req_r2} <= req_value(req_indx + i);
            end

            if (rx_int_last) begin
                req_indx <= 10'h0;
                req_done <=  1'h1;
            end else begin
                req_indx <= req_indx + PCI_DATA_WIDTH/32;
            end
        end else begin
            req_done <= 1'h0;
        end
    end

    //----------------------------------------------------------------------------
    function [31:0] rsp_value(input [9:0] reg_nr, input [9:0] index);
        case(reg_nr + index)
            default: rsp_value = reg_nr + index; // 32'h0;
            
            10'h02a: rsp_value = 32'h09_B8_10_01; // Cap 1: Vendor Specific @ 0xA8 (VIRTIO_PCI_CAP_COMMON_CFG)
            10'h02b: rsp_value = 32'h00_00_00_00; //        bar    = 0x00
            10'h02c: rsp_value = 32'h00_00_00_00; //        offset = 0x00000000
            10'h02d: rsp_value = 32'h00_10_00_00; //        length = 0x00001000 (4K)
            10'h02e: rsp_value = 32'h09_C8_10_03; // Cap 2: Vendor Specific @ 0xB8 (VIRTIO_PCI_CAP_ISR_CFG)
            10'h02f: rsp_value = 32'h00_00_00_00; //        bar    = 0x00
            10'h030: rsp_value = 32'h00_10_00_00; //        offset = 0x00001000 (4K)
            10'h031: rsp_value = 32'h00_08_00_00; //        length = 0x00000800 (2K)
            /*
            10'h031: rsp_value = 32'h00_10_00_00; //        length = 0x00001000 (4K)
            */
            10'h032: rsp_value = 32'h09_D8_10_04; // Cap 3: Vendor Specific @ 0XC8 (VIRTIO_PCI_CAP_DEVICE_CFG)
            10'h033: rsp_value = 32'h00_00_00_00; //        bar    = 0x00
            10'h034: rsp_value = 32'h00_20_00_00; //        offset = 0x00002000 (8K)
            10'h035: rsp_value = 32'h00_10_00_00; //        length = 0x00001000 (4K)
            10'h036: rsp_value = 32'h09_00_14_02; // Cap 4: Vendor Specific @ 0xD8 (VIRTIO_PCI_CAP_NOTIFY_CFG)
            10'h037: rsp_value = 32'h00_00_00_00; //        bar    = 0x00
            10'h038: rsp_value = 32'h00_30_00_00; //        offset = 0x00001000 (12K)
            10'h039: rsp_value = 32'h00_10_00_00; //        length = 0x00001000 (4K)
            10'h03a: rsp_value = 32'h04_00_00_00; //        notify_off_multiplier = 4
            10'h03b: rsp_value = 32'h09_00_14_05; // Cap -: Vendor Specific @ 0xEC (VRITIO_PCI_CAP_PCI_CFG)
            10'h03c: rsp_value = 32'h00_00_00_00; //        bar    = 0x00
            10'h03d: rsp_value = 32'h00_00_00_00; //        offset = 0x00
            10'h03e: rsp_value = 32'h00_00_00_00; //        length = 0x00
            10'h03f: rsp_value = 32'h00_00_00_00; //        pci_cfg_data = 0x00
        endcase
    endfunction
    
    //============================================================================
    // Response
    //============================================================================
    reg  [PCI_DATA_WIDTH-1:0] rsp_data;
    reg  [               9:0] rsp_indx;
    reg  [               9:0] rsp_last, rsp_last_q;
    reg                       rsp_wait;
    
    wire [DATA_IDX_WIDTH-1:0] rsp_start_offset = 0;
    wire                      rsp_start_flag = !rsp_indx;
    reg  [DATA_IDX_WIDTH-1:0] rsp_end_offset;
    reg                       rsp_end_flag;

    //----------------------------------------------------------------------------
    always @(posedge clk) rsp_last_q <= rsp_last;
    always @(*) begin
        if (rst) begin
            rsp_last = 10'h0;
        end else
        if (req_done) begin
            rsp_last = req_length + 2;
        end else begin
            rsp_last = rsp_last_q;
        end
    end
   
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            rsp_indx <= 10'h0;
            rsp_wait <=  1'h0;
        end else begin
            if (tx_cfg_valid && tx_cfg_ready) begin
                rsp_indx <= rsp_indx + {1'h1,{DATA_IDX_WIDTH-2{1'h0}}};
            end

            if (req_done) begin
                rsp_wait <= 1'h1;
            end

            if (tx_cfg_valid && tx_cfg_ready && tx_cfg_end_flag) begin
                rsp_indx <= 10'h0;
                rsp_wait <=  1'h0;
            end
        end
    end

    always @(*) begin
        if (rst) begin
            rsp_end_offset = {DATA_IDX_WIDTH{1'h0}};
            rsp_end_flag   =  1'h0;
            rsp_data       = {PCI_DATA_WIDTH{1'h0}};
        end else
        if ((req_done || rsp_wait) && req_type == 5'h4) begin
            rsp_end_offset = {DATA_IDX_WIDTH{1'h0}};
            rsp_end_flag   = 1'h0;
            
            for (i = 0; i < PCI_DATA_WIDTH/32; i = i + 1) begin
                case (rsp_indx + i)                  //  < Fmt ,Type, -- , TC , --- , Len >
                    10'h00: rsp_data[{i,5'h0}+:32] = {1'h0,2'h2,5'hA,1'h0,3'h0,10'h0,req_length};
                    10'h01: rsp_data[{i,5'h0}+:32] = {req_bus_nr,req_dev_nr,req_fun_nr,3'h0,1'h0,12'h0}; // Status,BCM,ByteCount = 0,0,0
                    10'h02: rsp_data[{i,5'h0}+:32] = {req_req_id,req_tag,1'h0,req_reg_nr[4:0],2'h0}; // req_reg_nr[6:0]
                    
                    default: begin
                        if (rsp_end_flag) begin
                            rsp_data[{i,5'h0}+:32] = 32'h0;
                        end else begin
                            rsp_data[{i,5'h0}+:32] = rsp_value(req_reg_nr, rsp_indx + i - 3);
                        end

                        rsp_end_flag = rsp_end_flag || (rsp_last == rsp_indx + i);
                        if (rsp_indx + i == rsp_last) begin
                            rsp_end_offset = {i,2'h3};
                        end
                    end
                endcase
            end
        end else begin
            rsp_end_offset = {DATA_IDX_WIDTH{1'h0}};
            rsp_end_flag   = 1'h0;
            rsp_data       = {PCI_DATA_WIDTH{1'h0}};
        end
    end

    //----------------------------------------------------------------------------
    assign rx_int_ready = !(req_done || rsp_wait);
    assign rx_cfg_ready = !(req_done || rsp_wait);

    //----------------------------------------------------------------------------
    assign tx_cfg_valid        = req_done || rsp_wait;
    assign tx_cfg_start_flag   = rsp_start_flag  ;
    assign tx_cfg_start_offset = rsp_start_offset;
    assign tx_cfg_end_flag     = rsp_end_flag    ;
    assign tx_cfg_end_offset   = rsp_end_offset  ;
    assign tx_cfg_data         = rsp_data        ;
    
endmodule
