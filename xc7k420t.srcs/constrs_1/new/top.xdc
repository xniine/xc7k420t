
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property CFGBVS VCCO [current_design]

# 3, 6, 9, 12, 16, 22, 26, 33, 40, 50, 66
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

##################################################################################
# Clock & Reset
##################################################################################

set_property PACKAGE_PIN AA27     [get_ports CLK_100MHz[1]]
set_property IOSTANDARD  LVCMOS33 [get_ports CLK_100MHz[1]]

set_property PACKAGE_PIN AC27     [get_ports CLK_100MHz[0]]
set_property IOSTANDARD  LVCMOS33 [get_ports CLK_100MHz[0]]

set_property PACKAGE_PIN AK16     [get_ports RESET]
set_property IOSTANDARD  LVCMOS33 [get_ports RESET]

##################################################################################
# Key & LED
##################################################################################

set_property IOSTANDARD  LVCMOS33 [get_ports LED[*]]
set_property PACKAGE_PIN AJ22     [get_ports LED[0]]
set_property PACKAGE_PIN AJ21     [get_ports LED[1]]
set_property PACKAGE_PIN AK21     [get_ports LED[2]]
set_property PACKAGE_PIN AK20     [get_ports LED[3]]
set_property PACKAGE_PIN AK19     [get_ports LED[4]]
set_property PACKAGE_PIN AJ19     [get_ports LED[5]]
set_property PACKAGE_PIN AK18     [get_ports LED[6]]
set_property PACKAGE_PIN AJ18     [get_ports LED[7]]

set_property IOSTANDARD  LVCMOS33 [get_ports KEY[*]]
set_property PACKAGE_PIN N30      [get_ports KEY[0]]
set_property PACKAGE_PIN Y30      [get_ports KEY[1]]
set_property PACKAGE_PIN Y29      [get_ports KEY[2]]
set_property PACKAGE_PIN AA30     [get_ports KEY[3]]
set_property PACKAGE_PIN AB30     [get_ports KEY[4]]
set_property PACKAGE_PIN AB29     [get_ports KEY[5]]
set_property PACKAGE_PIN AC30     [get_ports KEY[6]]
set_property PACKAGE_PIN AC29     [get_ports KEY[7]]

#set_property IOSTANDARD  LVCMOS33 [get_ports KEY2]
#set_property PACKAGE_PIN AK16     [get_ports KEY2]

set_property IOSTANDARD  LVCMOS33 [get_ports KEY3]
set_property PACKAGE_PIN AK15     [get_ports KEY3]

##################################################################################
# GPIO
##################################################################################

set_property IOSTANDARD  LVCMOS33 [get_ports GPIO[ *]]

set_property PACKAGE_PIN C29      [get_ports GPIO[ 0]]
set_property PACKAGE_PIN B30      [get_ports GPIO[ 1]]
set_property PACKAGE_PIN D29      [get_ports GPIO[ 2]]
set_property PACKAGE_PIN C30      [get_ports GPIO[ 3]]
set_property PACKAGE_PIN E30      [get_ports GPIO[ 4]]
set_property PACKAGE_PIN E29      [get_ports GPIO[ 5]]
set_property PACKAGE_PIN G29      [get_ports GPIO[ 6]]
set_property PACKAGE_PIN F30      [get_ports GPIO[ 7]]
set_property PACKAGE_PIN H29      [get_ports GPIO[ 8]]
set_property PACKAGE_PIN G30      [get_ports GPIO[ 9]]
set_property PACKAGE_PIN J29      [get_ports GPIO[10]]
set_property PACKAGE_PIN H30      [get_ports GPIO[11]]
set_property PACKAGE_PIN K30      [get_ports GPIO[12]]
set_property PACKAGE_PIN K29      [get_ports GPIO[13]]
set_property PACKAGE_PIN M29      [get_ports GPIO[14]]
set_property PACKAGE_PIN L30      [get_ports GPIO[15]]

set_property PACKAGE_PIN AG30     [get_ports GPIO[16]]
set_property PACKAGE_PIN M30      [get_ports GPIO[17]]
set_property PACKAGE_PIN AG29     [get_ports GPIO[18]]
set_property PACKAGE_PIN AH30     [get_ports GPIO[19]]
set_property PACKAGE_PIN AH29     [get_ports GPIO[20]]
set_property PACKAGE_PIN AK30     [get_ports GPIO[21]]
set_property PACKAGE_PIN AJ29     [get_ports GPIO[22]]
set_property PACKAGE_PIN AK29     [get_ports GPIO[23]]
set_property PACKAGE_PIN AJ28     [get_ports GPIO[24]]
set_property PACKAGE_PIN AK28     [get_ports GPIO[25]]
set_property PACKAGE_PIN AJ27     [get_ports GPIO[26]]
set_property PACKAGE_PIN AJ26     [get_ports GPIO[27]]
set_property PACKAGE_PIN AK26     [get_ports GPIO[28]]
set_property PACKAGE_PIN AK25     [get_ports GPIO[29]]
set_property PACKAGE_PIN AJ24     [get_ports GPIO[30]]
set_property PACKAGE_PIN AK24     [get_ports GPIO[31]]
set_property PACKAGE_PIN AJ23     [get_ports GPIO[32]]
set_property PACKAGE_PIN AK23     [get_ports GPIO[33]]

##################################################################################
# UART
##################################################################################

set_property IOSTANDARD  LVCMOS33 [get_ports UART_*]
set_property PACKAGE_PIN A30      [get_ports UART_RXD]
set_property PACKAGE_PIN B29      [get_ports UART_TXD]

##################################################################################
# SFP
##################################################################################

set_property IOSTANDARD  LVCMOS33 [get_ports {SFP_TX_DISABLE[*]}]
set_property PACKAGE_PIN B24      [get_ports {SFP_TX_DISABLE[0]}]
set_property PACKAGE_PIN A22      [get_ports {SFP_TX_DISABLE[1]}]
set_property PACKAGE_PIN A25      [get_ports {SFP_TX_DISABLE[2]}]
set_property PACKAGE_PIN B27      [get_ports {SFP_TX_DISABLE[3]}]

set_property IOSTANDARD  LVCMOS33 [get_ports {SFP_RS0[*]}]
set_property PACKAGE_PIN A23      [get_ports {SFP_RS0[0]}]
set_property PACKAGE_PIN A20      [get_ports {SFP_RS0[1]}]
set_property PACKAGE_PIN A27      [get_ports {SFP_RS0[2]}]
set_property PACKAGE_PIN E28      [get_ports {SFP_RS0[3]}]

set_property IOSTANDARD  LVCMOS33 [get_ports {SFP_SDA[*]}]
set_property PACKAGE_PIN B23      [get_ports {SFP_SDA[0]}]
set_property PACKAGE_PIN A21      [get_ports {SFP_SDA[1]}]
set_property PACKAGE_PIN B25      [get_ports {SFP_SDA[2]}]
set_property PACKAGE_PIN A28      [get_ports {SFP_SDA[3]}]

set_property IOSTANDARD  LVCMOS33 [get_ports {SFP_SCL[*]}]
set_property PACKAGE_PIN B22      [get_ports {SFP_SCL[0]}]
set_property PACKAGE_PIN B20      [get_ports {SFP_SCL[1]}]
set_property PACKAGE_PIN A26      [get_ports {SFP_SCL[2]}]
set_property PACKAGE_PIN B28      [get_ports {SFP_SCL[3]}]

# Bank 117
create_clock -period     6.400    [get_ports SFP_GTREFCLK_P[0]]
set_property PACKAGE_PIN E8       [get_ports SFP_GTREFCLK_P[0]]
set_property PACKAGE_PIN E7       [get_ports SFP_GTREFCLK_N[0]]

# Bank 117-3
set_property PACKAGE_PIN A12      [get_ports {SFP_TXP[0]}]
set_property PACKAGE_PIN A11      [get_ports {SFP_TXN[0]}]
set_property PACKAGE_PIN C12      [get_ports {SFP_RXP[0]}]
set_property PACKAGE_PIN C11      [get_ports {SFP_RXN[0]}]

# Bank 117-1
set_property PACKAGE_PIN A8       [get_ports {SFP_TXP[1]}]
set_property PACKAGE_PIN A7       [get_ports {SFP_TXN[1]}]
set_property PACKAGE_PIN D10      [get_ports {SFP_RXP[1]}]
set_property PACKAGE_PIN D9       [get_ports {SFP_RXN[1]}]

# Bank 116-2
set_property PACKAGE_PIN A4       [get_ports {SFP_TXP[2]}]
set_property PACKAGE_PIN A3       [get_ports {SFP_TXN[2]}]
set_property PACKAGE_PIN D6       [get_ports {SFP_RXP[2]}]
set_property PACKAGE_PIN D5       [get_ports {SFP_RXN[2]}]

# Bank 116-1
set_property PACKAGE_PIN B2       [get_ports {SFP_TXP[3]}]
set_property PACKAGE_PIN B1       [get_ports {SFP_TXN[3]}]
set_property PACKAGE_PIN E4       [get_ports {SFP_RXP[3]}]
set_property PACKAGE_PIN E3       [get_ports {SFP_RXN[3]}]

##################################################################################
# PCIE
##################################################################################

# Bank 112
create_clock -period     10       [get_ports PCIE_CLK_P]
set_property PACKAGE_PIN W8       [get_ports PCIE_CLK_P]

# Bank 113-1
set_property PACKAGE_PIN Y2       [get_ports {PCIE_TXP[0]}]
set_property PACKAGE_PIN Y1       [get_ports {PCIE_TXN[0]}]
set_property PACKAGE_PIN W4       [get_ports {PCIE_RXP[0]}]
set_property PACKAGE_PIN W3       [get_ports {PCIE_RXN[0]}]

# Bank 113-2
set_property PACKAGE_PIN AB2      [get_ports {PCIE_TXP[1]}]
set_property PACKAGE_PIN AB1      [get_ports {PCIE_TXN[1]}]
set_property PACKAGE_PIN Y6       [get_ports {PCIE_RXP[1]}]
set_property PACKAGE_PIN Y5       [get_ports {PCIE_RXN[1]}]

# Bank 113-3
set_property PACKAGE_PIN AD2      [get_ports {PCIE_TXP[2]}]
set_property PACKAGE_PIN AD1      [get_ports {PCIE_TXN[2]}]
set_property PACKAGE_PIN AA4      [get_ports {PCIE_RXP[2]}]
set_property PACKAGE_PIN AA3      [get_ports {PCIE_RXN[2]}]

# Bank 111-0
set_property PACKAGE_PIN AF2      [get_ports {PCIE_TXP[3]}]
set_property PACKAGE_PIN AF1      [get_ports {PCIE_TXN[3]}]
set_property PACKAGE_PIN AB6      [get_ports {PCIE_RXP[3]}]
set_property PACKAGE_PIN AB5      [get_ports {PCIE_RXN[3]}]

# # Bank 112-3
# set_property PACKAGE_PIN AH2      [get_ports {PCIE_TXP[4]}]
# set_property PACKAGE_PIN AH1      [get_ports {PCIE_TXN[4]}]
# set_property PACKAGE_PIN AC4      [get_ports {PCIE_RXP[4]}]
# set_property PACKAGE_PIN AC3      [get_ports {PCIE_RXN[4]}]
# 
# # Bank 112-2
# set_property PACKAGE_PIN AK2      [get_ports {PCIE_TXP[5]}]
# set_property PACKAGE_PIN AK1      [get_ports {PCIE_TXN[5]}]
# set_property PACKAGE_PIN AE4      [get_ports {PCIE_RXP[5]}]
# set_property PACKAGE_PIN AE3      [get_ports {PCIE_RXN[5]}]
# 
# # Bank 112-1
# set_property PACKAGE_PIN AJ4      [get_ports {PCIE_TXP[6]}]
# set_property PACKAGE_PIN AJ3      [get_ports {PCIE_TXN[6]}]
# set_property PACKAGE_PIN AG4      [get_ports {PCIE_RXP[6]}]
# set_property PACKAGE_PIN AG3      [get_ports {PCIE_RXN[6]}]
# 
# # Bank 112-0
# set_property PACKAGE_PIN AK6      [get_ports {PCIE_TXP[7]}]
# set_property PACKAGE_PIN AK5      [get_ports {PCIE_TXN[7]}]
# set_property PACKAGE_PIN AH6      [get_ports {PCIE_RXP[7]}]
# set_property PACKAGE_PIN AH5      [get_ports {PCIE_RXN[7]}]

# Reset_N
set_property IOSTANDARD  LVCMOS33 [get_ports PCIE_RST_N]
set_property PACKAGE_PIN W21      [get_ports PCIE_RST_N]

set_false_path -from [get_ports PCIE_RST_N]

##################################################################################

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins gtx_wrapper_inst/gtwizard_usrclk_0/plle2_base_0/CLKOUT1]] -group [get_clocks -of_objects [get_pins eth_virtio_wrapper_inst/pcie_axi_wrapper_inst/pcie_wrapper_inst/pcie_pipe_clock_inst/mmcm2_adv_0/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins gtx_wrapper_inst/gtwizard_usrclk_1/plle2_base_0/CLKOUT1]] -group [get_clocks -of_objects [get_pins eth_virtio_wrapper_inst/pcie_axi_wrapper_inst/pcie_wrapper_inst/pcie_pipe_clock_inst/mmcm2_adv_0/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins gtx_wrapper_inst/gtwizard_usrclk_2/plle2_base_0/CLKOUT1]] -group [get_clocks -of_objects [get_pins eth_virtio_wrapper_inst/pcie_axi_wrapper_inst/pcie_wrapper_inst/pcie_pipe_clock_inst/mmcm2_adv_0/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins gtx_wrapper_inst/gtwizard_usrclk_3/plle2_base_0/CLKOUT1]] -group [get_clocks -of_objects [get_pins eth_virtio_wrapper_inst/pcie_axi_wrapper_inst/pcie_wrapper_inst/pcie_pipe_clock_inst/mmcm2_adv_0/CLKOUT3]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins gtx_wrapper_inst/gtwizard_usrclk_4/plle2_base_0/CLKOUT1]] -group [get_clocks -of_objects [get_pins eth_virtio_wrapper_inst/pcie_axi_wrapper_inst/pcie_wrapper_inst/pcie_pipe_clock_inst/mmcm2_adv_0/CLKOUT3]]

##################################################################################

## For SPIx4 flash programming
#set_property CONFIG_MODE SPIx4 [current_design]
## 3, 6, 9, 12, 16, 22, 26, 33, 40, 50, 66
#set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

set_property BITSTREAM.CONFIG.PERSIST YES [current_design]

#------------------------------------------------------------------------------
# Tandem Main Pblock
#------------------------------------------------------------------------------
set main_pblock [create_pblock pcie_7x_0_main_pblock_boot]
set_property BOOT_BLOCK 1 [get_pblocks pcie_7x_0_main_pblock_boot]

resize_pblock $main_pblock -add {SLICE_X162Y200:SLICE_X189Y249 SLICE_X178Y100:SLICE_X189Y249}
resize_pblock $main_pblock -add {DSP48_X11Y60:DSP48_X11Y99}
resize_pblock $main_pblock -add {RAMB18_X10Y80:RAMB18_X11Y99}
resize_pblock $main_pblock -add {RAMB36_X10Y40:RAMB36_X11Y49}
resize_pblock $main_pblock -add {GTXE2_CHANNEL_X0Y8:GTXE2_CHANNEL_X0Y11}
resize_pblock $main_pblock -add {GTXE2_COMMON_X0Y2:GTXE2_COMMON_X0Y2}
resize_pblock $main_pblock -add {PCIE_X0Y0}

add_cells_to_pblock $main_pblock [get_cells -hierarchical -filter {REF_NAME == pcie_7x_0}]

#------------------------------------------------------------------------------
# Tandem Clk Logic Pblock
#------------------------------------------------------------------------------
set clk_logic_pblock [create_pblock clk_logic_pblock_boot]
set_property BOOT_BLOCK 1 [get_pblocks clk_logic_pblock_boot]

resize_pblock -add {SLICE_X124Y150:SLICE_X127Y199} $clk_logic_pblock

add_cells_to_pblock $clk_logic_pblock [get_cells eth_virtio_wrapper_inst/pcie_axi_wrapper_inst/pcie_wrapper_inst/pcie_pipe_clock_inst]

#------------------------------------------------------------------------------
# Tandem MMCM Pblock
#------------------------------------------------------------------------------
set mmcm_pblock [create_pblock pcie_7x_0_ext_mmcm_pblock_boot]
set_property BOOT_BLOCK 1 [get_pblocks pcie_7x_0_ext_mmcm_pblock_boot]

# Add the MMCM and all associated primitive to the PBLOCK
resize_pblock $mmcm_pblock -add {MMCME2_ADV_X0Y3}
resize_pblock $mmcm_pblock -add {IN_FIFO_X0Y12:IN_FIFO_X0Y15}
resize_pblock $mmcm_pblock -add {OUT_FIFO_X0Y12:OUT_FIFO_X0Y15}
resize_pblock $mmcm_pblock -add {PLLE2_ADV_X0Y3}
resize_pblock $mmcm_pblock -add {PHASER_IN_PHY_X0Y12:PHASER_IN_PHY_X0Y15}
resize_pblock $mmcm_pblock -add {PHASER_OUT_PHY_X0Y12:PHASER_OUT_PHY_X0Y15}
resize_pblock $mmcm_pblock -add {PHY_CONTROL_X0Y3}
resize_pblock $mmcm_pblock -add {PHASER_REF_X0Y3}

add_cells_to_pblock $mmcm_pblock [get_cells {eth_virtio_wrapper_inst/pcie_axi_wrapper_inst/pcie_wrapper_inst/pcie_pipe_clock_inst/mmcm2_adv_0}]

#------------------------------------------------------------------------------
# iLA Timeing Workaround
#------------------------------------------------------------------------------
#set_false_path -to [get_pins -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_0_allx_typeA_inst/DUT/I_WHOLE_SLICE.G_SLICE_IDX[*].U_ALL_SRL_SLICE/I_IS_TERMINATION_SLICE_W_OUTPUT_REG.DOUT_O_reg/D"}]
#set_false_path -to [get_pins -hierarchical -filter {NAME =~ "*allx_typeA_match_detection.ltlib_v1_0_0_allx_typeA_inst/probeDelay1_reg[*]/D"}]
#set_false_path -to [get_pins -hierarchical -filter {NAME =~ "*ila_core_inst/shifted_data_in_reg[*][*]_srl8/D"}]
