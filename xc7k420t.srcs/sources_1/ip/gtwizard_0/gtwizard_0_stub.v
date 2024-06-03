// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
// Date        : Mon Jun 12 14:53:52 2023
// Host        : ubuntu running 64-bit Ubuntu 20.04.3 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/ubuntu/Dev/xc7k420t_1/xc7k420t.srcs/sources_1/ip/gtwizard_0/gtwizard_0_stub.v
// Design      : gtwizard_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k420tffg901-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "gtwizard_0,gtwizard_v3_6_10,{protocol_file=10GBASE-R}" *)
module gtwizard_0(sysclk_in, soft_reset_tx_in, 
  soft_reset_rx_in, dont_reset_on_data_error_in, gt0_tx_fsm_reset_done_out, 
  gt0_rx_fsm_reset_done_out, gt0_data_valid_in, gt0_tx_mmcm_lock_in, 
  gt0_tx_mmcm_reset_out, gt0_rx_mmcm_lock_in, gt0_rx_mmcm_reset_out, 
  gt1_tx_fsm_reset_done_out, gt1_rx_fsm_reset_done_out, gt1_data_valid_in, 
  gt1_tx_mmcm_lock_in, gt1_tx_mmcm_reset_out, gt1_rx_mmcm_lock_in, gt1_rx_mmcm_reset_out, 
  gt2_tx_fsm_reset_done_out, gt2_rx_fsm_reset_done_out, gt2_data_valid_in, 
  gt2_tx_mmcm_lock_in, gt2_tx_mmcm_reset_out, gt2_rx_mmcm_lock_in, gt2_rx_mmcm_reset_out, 
  gt3_tx_fsm_reset_done_out, gt3_rx_fsm_reset_done_out, gt3_data_valid_in, 
  gt3_tx_mmcm_lock_in, gt3_tx_mmcm_reset_out, gt3_rx_mmcm_lock_in, gt3_rx_mmcm_reset_out, 
  gt0_gtnorthrefclk0_in, gt0_gtnorthrefclk1_in, gt0_gtsouthrefclk0_in, 
  gt0_gtsouthrefclk1_in, gt0_drpaddr_in, gt0_drpclk_in, gt0_drpdi_in, gt0_drpdo_out, 
  gt0_drpen_in, gt0_drprdy_out, gt0_drpwe_in, gt0_dmonitorout_out, gt0_loopback_in, 
  gt0_rxrate_in, gt0_eyescanreset_in, gt0_rxuserrdy_in, gt0_eyescandataerror_out, 
  gt0_eyescantrigger_in, gt0_rxcdrhold_in, gt0_rxusrclk_in, gt0_rxusrclk2_in, 
  gt0_rxdata_out, gt0_rxprbserr_out, gt0_rxprbssel_in, gt0_rxprbscntreset_in, 
  gt0_gtxrxp_in, gt0_gtxrxn_in, gt0_rxbufreset_in, gt0_rxbufstatus_out, 
  gt0_rxdfelpmreset_in, gt0_rxmonitorout_out, gt0_rxmonitorsel_in, gt0_rxratedone_out, 
  gt0_rxoutclk_out, gt0_rxoutclkfabric_out, gt0_rxdatavalid_out, gt0_rxheader_out, 
  gt0_rxheadervalid_out, gt0_rxgearboxslip_in, gt0_gtrxreset_in, gt0_rxpcsreset_in, 
  gt0_rxpmareset_in, gt0_rxlpmen_in, gt0_rxpolarity_in, gt0_rxresetdone_out, 
  gt0_txpostcursor_in, gt0_txprecursor_in, gt0_gttxreset_in, gt0_txuserrdy_in, 
  gt0_txusrclk_in, gt0_txusrclk2_in, gt0_txprbsforceerr_in, gt0_txbufstatus_out, 
  gt0_txdiffctrl_in, gt0_txinhibit_in, gt0_txmaincursor_in, gt0_txdata_in, gt0_gtxtxn_out, 
  gt0_gtxtxp_out, gt0_txoutclk_out, gt0_txoutclkfabric_out, gt0_txoutclkpcs_out, 
  gt0_txheader_in, gt0_txsequence_in, gt0_txpcsreset_in, gt0_txpmareset_in, 
  gt0_txresetdone_out, gt0_txpolarity_in, gt0_txprbssel_in, gt1_gtnorthrefclk0_in, 
  gt1_gtnorthrefclk1_in, gt1_gtsouthrefclk0_in, gt1_gtsouthrefclk1_in, gt1_drpaddr_in, 
  gt1_drpclk_in, gt1_drpdi_in, gt1_drpdo_out, gt1_drpen_in, gt1_drprdy_out, gt1_drpwe_in, 
  gt1_dmonitorout_out, gt1_loopback_in, gt1_rxrate_in, gt1_eyescanreset_in, 
  gt1_rxuserrdy_in, gt1_eyescandataerror_out, gt1_eyescantrigger_in, gt1_rxcdrhold_in, 
  gt1_rxusrclk_in, gt1_rxusrclk2_in, gt1_rxdata_out, gt1_rxprbserr_out, gt1_rxprbssel_in, 
  gt1_rxprbscntreset_in, gt1_gtxrxp_in, gt1_gtxrxn_in, gt1_rxbufreset_in, 
  gt1_rxbufstatus_out, gt1_rxdfelpmreset_in, gt1_rxmonitorout_out, gt1_rxmonitorsel_in, 
  gt1_rxratedone_out, gt1_rxoutclk_out, gt1_rxoutclkfabric_out, gt1_rxdatavalid_out, 
  gt1_rxheader_out, gt1_rxheadervalid_out, gt1_rxgearboxslip_in, gt1_gtrxreset_in, 
  gt1_rxpcsreset_in, gt1_rxpmareset_in, gt1_rxlpmen_in, gt1_rxpolarity_in, 
  gt1_rxresetdone_out, gt1_txpostcursor_in, gt1_txprecursor_in, gt1_gttxreset_in, 
  gt1_txuserrdy_in, gt1_txusrclk_in, gt1_txusrclk2_in, gt1_txprbsforceerr_in, 
  gt1_txbufstatus_out, gt1_txdiffctrl_in, gt1_txinhibit_in, gt1_txmaincursor_in, 
  gt1_txdata_in, gt1_gtxtxn_out, gt1_gtxtxp_out, gt1_txoutclk_out, gt1_txoutclkfabric_out, 
  gt1_txoutclkpcs_out, gt1_txheader_in, gt1_txsequence_in, gt1_txpcsreset_in, 
  gt1_txpmareset_in, gt1_txresetdone_out, gt1_txpolarity_in, gt1_txprbssel_in, 
  gt2_gtnorthrefclk0_in, gt2_gtnorthrefclk1_in, gt2_gtsouthrefclk0_in, 
  gt2_gtsouthrefclk1_in, gt2_drpaddr_in, gt2_drpclk_in, gt2_drpdi_in, gt2_drpdo_out, 
  gt2_drpen_in, gt2_drprdy_out, gt2_drpwe_in, gt2_dmonitorout_out, gt2_loopback_in, 
  gt2_rxrate_in, gt2_eyescanreset_in, gt2_rxuserrdy_in, gt2_eyescandataerror_out, 
  gt2_eyescantrigger_in, gt2_rxcdrhold_in, gt2_rxusrclk_in, gt2_rxusrclk2_in, 
  gt2_rxdata_out, gt2_rxprbserr_out, gt2_rxprbssel_in, gt2_rxprbscntreset_in, 
  gt2_gtxrxp_in, gt2_gtxrxn_in, gt2_rxbufreset_in, gt2_rxbufstatus_out, 
  gt2_rxdfelpmreset_in, gt2_rxmonitorout_out, gt2_rxmonitorsel_in, gt2_rxratedone_out, 
  gt2_rxoutclk_out, gt2_rxoutclkfabric_out, gt2_rxdatavalid_out, gt2_rxheader_out, 
  gt2_rxheadervalid_out, gt2_rxgearboxslip_in, gt2_gtrxreset_in, gt2_rxpcsreset_in, 
  gt2_rxpmareset_in, gt2_rxlpmen_in, gt2_rxpolarity_in, gt2_rxresetdone_out, 
  gt2_txpostcursor_in, gt2_txprecursor_in, gt2_gttxreset_in, gt2_txuserrdy_in, 
  gt2_txusrclk_in, gt2_txusrclk2_in, gt2_txprbsforceerr_in, gt2_txbufstatus_out, 
  gt2_txdiffctrl_in, gt2_txinhibit_in, gt2_txmaincursor_in, gt2_txdata_in, gt2_gtxtxn_out, 
  gt2_gtxtxp_out, gt2_txoutclk_out, gt2_txoutclkfabric_out, gt2_txoutclkpcs_out, 
  gt2_txheader_in, gt2_txsequence_in, gt2_txpcsreset_in, gt2_txpmareset_in, 
  gt2_txresetdone_out, gt2_txpolarity_in, gt2_txprbssel_in, gt3_gtnorthrefclk0_in, 
  gt3_gtnorthrefclk1_in, gt3_gtsouthrefclk0_in, gt3_gtsouthrefclk1_in, gt3_drpaddr_in, 
  gt3_drpclk_in, gt3_drpdi_in, gt3_drpdo_out, gt3_drpen_in, gt3_drprdy_out, gt3_drpwe_in, 
  gt3_dmonitorout_out, gt3_loopback_in, gt3_rxrate_in, gt3_eyescanreset_in, 
  gt3_rxuserrdy_in, gt3_eyescandataerror_out, gt3_eyescantrigger_in, gt3_rxcdrhold_in, 
  gt3_rxusrclk_in, gt3_rxusrclk2_in, gt3_rxdata_out, gt3_rxprbserr_out, gt3_rxprbssel_in, 
  gt3_rxprbscntreset_in, gt3_gtxrxp_in, gt3_gtxrxn_in, gt3_rxbufreset_in, 
  gt3_rxbufstatus_out, gt3_rxdfelpmreset_in, gt3_rxmonitorout_out, gt3_rxmonitorsel_in, 
  gt3_rxratedone_out, gt3_rxoutclk_out, gt3_rxoutclkfabric_out, gt3_rxdatavalid_out, 
  gt3_rxheader_out, gt3_rxheadervalid_out, gt3_rxgearboxslip_in, gt3_gtrxreset_in, 
  gt3_rxpcsreset_in, gt3_rxpmareset_in, gt3_rxlpmen_in, gt3_rxpolarity_in, 
  gt3_rxresetdone_out, gt3_txpostcursor_in, gt3_txprecursor_in, gt3_gttxreset_in, 
  gt3_txuserrdy_in, gt3_txusrclk_in, gt3_txusrclk2_in, gt3_txprbsforceerr_in, 
  gt3_txbufstatus_out, gt3_txdiffctrl_in, gt3_txinhibit_in, gt3_txmaincursor_in, 
  gt3_txdata_in, gt3_gtxtxn_out, gt3_gtxtxp_out, gt3_txoutclk_out, gt3_txoutclkfabric_out, 
  gt3_txoutclkpcs_out, gt3_txheader_in, gt3_txsequence_in, gt3_txpcsreset_in, 
  gt3_txpmareset_in, gt3_txresetdone_out, gt3_txpolarity_in, gt3_txprbssel_in, 
  gt0_qplllock_in, gt0_qpllrefclklost_in, gt0_qpllreset_out, gt0_qplloutclk_in, 
  gt0_qplloutrefclk_in, gt1_qplllock_in, gt1_qpllrefclklost_in, gt1_qpllreset_out, 
  gt1_qplloutclk_in, gt1_qplloutrefclk_in)
/* synthesis syn_black_box black_box_pad_pin="sysclk_in,soft_reset_tx_in,soft_reset_rx_in,dont_reset_on_data_error_in,gt0_tx_fsm_reset_done_out,gt0_rx_fsm_reset_done_out,gt0_data_valid_in,gt0_tx_mmcm_lock_in,gt0_tx_mmcm_reset_out,gt0_rx_mmcm_lock_in,gt0_rx_mmcm_reset_out,gt1_tx_fsm_reset_done_out,gt1_rx_fsm_reset_done_out,gt1_data_valid_in,gt1_tx_mmcm_lock_in,gt1_tx_mmcm_reset_out,gt1_rx_mmcm_lock_in,gt1_rx_mmcm_reset_out,gt2_tx_fsm_reset_done_out,gt2_rx_fsm_reset_done_out,gt2_data_valid_in,gt2_tx_mmcm_lock_in,gt2_tx_mmcm_reset_out,gt2_rx_mmcm_lock_in,gt2_rx_mmcm_reset_out,gt3_tx_fsm_reset_done_out,gt3_rx_fsm_reset_done_out,gt3_data_valid_in,gt3_tx_mmcm_lock_in,gt3_tx_mmcm_reset_out,gt3_rx_mmcm_lock_in,gt3_rx_mmcm_reset_out,gt0_gtnorthrefclk0_in,gt0_gtnorthrefclk1_in,gt0_gtsouthrefclk0_in,gt0_gtsouthrefclk1_in,gt0_drpaddr_in[8:0],gt0_drpclk_in,gt0_drpdi_in[15:0],gt0_drpdo_out[15:0],gt0_drpen_in,gt0_drprdy_out,gt0_drpwe_in,gt0_dmonitorout_out[7:0],gt0_loopback_in[2:0],gt0_rxrate_in[2:0],gt0_eyescanreset_in,gt0_rxuserrdy_in,gt0_eyescandataerror_out,gt0_eyescantrigger_in,gt0_rxcdrhold_in,gt0_rxusrclk_in,gt0_rxusrclk2_in,gt0_rxdata_out[63:0],gt0_rxprbserr_out,gt0_rxprbssel_in[2:0],gt0_rxprbscntreset_in,gt0_gtxrxp_in,gt0_gtxrxn_in,gt0_rxbufreset_in,gt0_rxbufstatus_out[2:0],gt0_rxdfelpmreset_in,gt0_rxmonitorout_out[6:0],gt0_rxmonitorsel_in[1:0],gt0_rxratedone_out,gt0_rxoutclk_out,gt0_rxoutclkfabric_out,gt0_rxdatavalid_out,gt0_rxheader_out[1:0],gt0_rxheadervalid_out,gt0_rxgearboxslip_in,gt0_gtrxreset_in,gt0_rxpcsreset_in,gt0_rxpmareset_in,gt0_rxlpmen_in,gt0_rxpolarity_in,gt0_rxresetdone_out,gt0_txpostcursor_in[4:0],gt0_txprecursor_in[4:0],gt0_gttxreset_in,gt0_txuserrdy_in,gt0_txusrclk_in,gt0_txusrclk2_in,gt0_txprbsforceerr_in,gt0_txbufstatus_out[1:0],gt0_txdiffctrl_in[3:0],gt0_txinhibit_in,gt0_txmaincursor_in[6:0],gt0_txdata_in[63:0],gt0_gtxtxn_out,gt0_gtxtxp_out,gt0_txoutclk_out,gt0_txoutclkfabric_out,gt0_txoutclkpcs_out,gt0_txheader_in[1:0],gt0_txsequence_in[6:0],gt0_txpcsreset_in,gt0_txpmareset_in,gt0_txresetdone_out,gt0_txpolarity_in,gt0_txprbssel_in[2:0],gt1_gtnorthrefclk0_in,gt1_gtnorthrefclk1_in,gt1_gtsouthrefclk0_in,gt1_gtsouthrefclk1_in,gt1_drpaddr_in[8:0],gt1_drpclk_in,gt1_drpdi_in[15:0],gt1_drpdo_out[15:0],gt1_drpen_in,gt1_drprdy_out,gt1_drpwe_in,gt1_dmonitorout_out[7:0],gt1_loopback_in[2:0],gt1_rxrate_in[2:0],gt1_eyescanreset_in,gt1_rxuserrdy_in,gt1_eyescandataerror_out,gt1_eyescantrigger_in,gt1_rxcdrhold_in,gt1_rxusrclk_in,gt1_rxusrclk2_in,gt1_rxdata_out[63:0],gt1_rxprbserr_out,gt1_rxprbssel_in[2:0],gt1_rxprbscntreset_in,gt1_gtxrxp_in,gt1_gtxrxn_in,gt1_rxbufreset_in,gt1_rxbufstatus_out[2:0],gt1_rxdfelpmreset_in,gt1_rxmonitorout_out[6:0],gt1_rxmonitorsel_in[1:0],gt1_rxratedone_out,gt1_rxoutclk_out,gt1_rxoutclkfabric_out,gt1_rxdatavalid_out,gt1_rxheader_out[1:0],gt1_rxheadervalid_out,gt1_rxgearboxslip_in,gt1_gtrxreset_in,gt1_rxpcsreset_in,gt1_rxpmareset_in,gt1_rxlpmen_in,gt1_rxpolarity_in,gt1_rxresetdone_out,gt1_txpostcursor_in[4:0],gt1_txprecursor_in[4:0],gt1_gttxreset_in,gt1_txuserrdy_in,gt1_txusrclk_in,gt1_txusrclk2_in,gt1_txprbsforceerr_in,gt1_txbufstatus_out[1:0],gt1_txdiffctrl_in[3:0],gt1_txinhibit_in,gt1_txmaincursor_in[6:0],gt1_txdata_in[63:0],gt1_gtxtxn_out,gt1_gtxtxp_out,gt1_txoutclk_out,gt1_txoutclkfabric_out,gt1_txoutclkpcs_out,gt1_txheader_in[1:0],gt1_txsequence_in[6:0],gt1_txpcsreset_in,gt1_txpmareset_in,gt1_txresetdone_out,gt1_txpolarity_in,gt1_txprbssel_in[2:0],gt2_gtnorthrefclk0_in,gt2_gtnorthrefclk1_in,gt2_gtsouthrefclk0_in,gt2_gtsouthrefclk1_in,gt2_drpaddr_in[8:0],gt2_drpclk_in,gt2_drpdi_in[15:0],gt2_drpdo_out[15:0],gt2_drpen_in,gt2_drprdy_out,gt2_drpwe_in,gt2_dmonitorout_out[7:0],gt2_loopback_in[2:0],gt2_rxrate_in[2:0],gt2_eyescanreset_in,gt2_rxuserrdy_in,gt2_eyescandataerror_out,gt2_eyescantrigger_in,gt2_rxcdrhold_in,gt2_rxusrclk_in,gt2_rxusrclk2_in,gt2_rxdata_out[63:0],gt2_rxprbserr_out,gt2_rxprbssel_in[2:0],gt2_rxprbscntreset_in,gt2_gtxrxp_in,gt2_gtxrxn_in,gt2_rxbufreset_in,gt2_rxbufstatus_out[2:0],gt2_rxdfelpmreset_in,gt2_rxmonitorout_out[6:0],gt2_rxmonitorsel_in[1:0],gt2_rxratedone_out,gt2_rxoutclk_out,gt2_rxoutclkfabric_out,gt2_rxdatavalid_out,gt2_rxheader_out[1:0],gt2_rxheadervalid_out,gt2_rxgearboxslip_in,gt2_gtrxreset_in,gt2_rxpcsreset_in,gt2_rxpmareset_in,gt2_rxlpmen_in,gt2_rxpolarity_in,gt2_rxresetdone_out,gt2_txpostcursor_in[4:0],gt2_txprecursor_in[4:0],gt2_gttxreset_in,gt2_txuserrdy_in,gt2_txusrclk_in,gt2_txusrclk2_in,gt2_txprbsforceerr_in,gt2_txbufstatus_out[1:0],gt2_txdiffctrl_in[3:0],gt2_txinhibit_in,gt2_txmaincursor_in[6:0],gt2_txdata_in[63:0],gt2_gtxtxn_out,gt2_gtxtxp_out,gt2_txoutclk_out,gt2_txoutclkfabric_out,gt2_txoutclkpcs_out,gt2_txheader_in[1:0],gt2_txsequence_in[6:0],gt2_txpcsreset_in,gt2_txpmareset_in,gt2_txresetdone_out,gt2_txpolarity_in,gt2_txprbssel_in[2:0],gt3_gtnorthrefclk0_in,gt3_gtnorthrefclk1_in,gt3_gtsouthrefclk0_in,gt3_gtsouthrefclk1_in,gt3_drpaddr_in[8:0],gt3_drpclk_in,gt3_drpdi_in[15:0],gt3_drpdo_out[15:0],gt3_drpen_in,gt3_drprdy_out,gt3_drpwe_in,gt3_dmonitorout_out[7:0],gt3_loopback_in[2:0],gt3_rxrate_in[2:0],gt3_eyescanreset_in,gt3_rxuserrdy_in,gt3_eyescandataerror_out,gt3_eyescantrigger_in,gt3_rxcdrhold_in,gt3_rxusrclk_in,gt3_rxusrclk2_in,gt3_rxdata_out[63:0],gt3_rxprbserr_out,gt3_rxprbssel_in[2:0],gt3_rxprbscntreset_in,gt3_gtxrxp_in,gt3_gtxrxn_in,gt3_rxbufreset_in,gt3_rxbufstatus_out[2:0],gt3_rxdfelpmreset_in,gt3_rxmonitorout_out[6:0],gt3_rxmonitorsel_in[1:0],gt3_rxratedone_out,gt3_rxoutclk_out,gt3_rxoutclkfabric_out,gt3_rxdatavalid_out,gt3_rxheader_out[1:0],gt3_rxheadervalid_out,gt3_rxgearboxslip_in,gt3_gtrxreset_in,gt3_rxpcsreset_in,gt3_rxpmareset_in,gt3_rxlpmen_in,gt3_rxpolarity_in,gt3_rxresetdone_out,gt3_txpostcursor_in[4:0],gt3_txprecursor_in[4:0],gt3_gttxreset_in,gt3_txuserrdy_in,gt3_txusrclk_in,gt3_txusrclk2_in,gt3_txprbsforceerr_in,gt3_txbufstatus_out[1:0],gt3_txdiffctrl_in[3:0],gt3_txinhibit_in,gt3_txmaincursor_in[6:0],gt3_txdata_in[63:0],gt3_gtxtxn_out,gt3_gtxtxp_out,gt3_txoutclk_out,gt3_txoutclkfabric_out,gt3_txoutclkpcs_out,gt3_txheader_in[1:0],gt3_txsequence_in[6:0],gt3_txpcsreset_in,gt3_txpmareset_in,gt3_txresetdone_out,gt3_txpolarity_in,gt3_txprbssel_in[2:0],gt0_qplllock_in,gt0_qpllrefclklost_in,gt0_qpllreset_out,gt0_qplloutclk_in,gt0_qplloutrefclk_in,gt1_qplllock_in,gt1_qpllrefclklost_in,gt1_qpllreset_out,gt1_qplloutclk_in,gt1_qplloutrefclk_in" */;
  input sysclk_in;
  input soft_reset_tx_in;
  input soft_reset_rx_in;
  input dont_reset_on_data_error_in;
  output gt0_tx_fsm_reset_done_out;
  output gt0_rx_fsm_reset_done_out;
  input gt0_data_valid_in;
  input gt0_tx_mmcm_lock_in;
  output gt0_tx_mmcm_reset_out;
  input gt0_rx_mmcm_lock_in;
  output gt0_rx_mmcm_reset_out;
  output gt1_tx_fsm_reset_done_out;
  output gt1_rx_fsm_reset_done_out;
  input gt1_data_valid_in;
  input gt1_tx_mmcm_lock_in;
  output gt1_tx_mmcm_reset_out;
  input gt1_rx_mmcm_lock_in;
  output gt1_rx_mmcm_reset_out;
  output gt2_tx_fsm_reset_done_out;
  output gt2_rx_fsm_reset_done_out;
  input gt2_data_valid_in;
  input gt2_tx_mmcm_lock_in;
  output gt2_tx_mmcm_reset_out;
  input gt2_rx_mmcm_lock_in;
  output gt2_rx_mmcm_reset_out;
  output gt3_tx_fsm_reset_done_out;
  output gt3_rx_fsm_reset_done_out;
  input gt3_data_valid_in;
  input gt3_tx_mmcm_lock_in;
  output gt3_tx_mmcm_reset_out;
  input gt3_rx_mmcm_lock_in;
  output gt3_rx_mmcm_reset_out;
  input gt0_gtnorthrefclk0_in;
  input gt0_gtnorthrefclk1_in;
  input gt0_gtsouthrefclk0_in;
  input gt0_gtsouthrefclk1_in;
  input [8:0]gt0_drpaddr_in;
  input gt0_drpclk_in;
  input [15:0]gt0_drpdi_in;
  output [15:0]gt0_drpdo_out;
  input gt0_drpen_in;
  output gt0_drprdy_out;
  input gt0_drpwe_in;
  output [7:0]gt0_dmonitorout_out;
  input [2:0]gt0_loopback_in;
  input [2:0]gt0_rxrate_in;
  input gt0_eyescanreset_in;
  input gt0_rxuserrdy_in;
  output gt0_eyescandataerror_out;
  input gt0_eyescantrigger_in;
  input gt0_rxcdrhold_in;
  input gt0_rxusrclk_in;
  input gt0_rxusrclk2_in;
  output [63:0]gt0_rxdata_out;
  output gt0_rxprbserr_out;
  input [2:0]gt0_rxprbssel_in;
  input gt0_rxprbscntreset_in;
  input gt0_gtxrxp_in;
  input gt0_gtxrxn_in;
  input gt0_rxbufreset_in;
  output [2:0]gt0_rxbufstatus_out;
  input gt0_rxdfelpmreset_in;
  output [6:0]gt0_rxmonitorout_out;
  input [1:0]gt0_rxmonitorsel_in;
  output gt0_rxratedone_out;
  output gt0_rxoutclk_out;
  output gt0_rxoutclkfabric_out;
  output gt0_rxdatavalid_out;
  output [1:0]gt0_rxheader_out;
  output gt0_rxheadervalid_out;
  input gt0_rxgearboxslip_in;
  input gt0_gtrxreset_in;
  input gt0_rxpcsreset_in;
  input gt0_rxpmareset_in;
  input gt0_rxlpmen_in;
  input gt0_rxpolarity_in;
  output gt0_rxresetdone_out;
  input [4:0]gt0_txpostcursor_in;
  input [4:0]gt0_txprecursor_in;
  input gt0_gttxreset_in;
  input gt0_txuserrdy_in;
  input gt0_txusrclk_in;
  input gt0_txusrclk2_in;
  input gt0_txprbsforceerr_in;
  output [1:0]gt0_txbufstatus_out;
  input [3:0]gt0_txdiffctrl_in;
  input gt0_txinhibit_in;
  input [6:0]gt0_txmaincursor_in;
  input [63:0]gt0_txdata_in;
  output gt0_gtxtxn_out;
  output gt0_gtxtxp_out;
  output gt0_txoutclk_out;
  output gt0_txoutclkfabric_out;
  output gt0_txoutclkpcs_out;
  input [1:0]gt0_txheader_in;
  input [6:0]gt0_txsequence_in;
  input gt0_txpcsreset_in;
  input gt0_txpmareset_in;
  output gt0_txresetdone_out;
  input gt0_txpolarity_in;
  input [2:0]gt0_txprbssel_in;
  input gt1_gtnorthrefclk0_in;
  input gt1_gtnorthrefclk1_in;
  input gt1_gtsouthrefclk0_in;
  input gt1_gtsouthrefclk1_in;
  input [8:0]gt1_drpaddr_in;
  input gt1_drpclk_in;
  input [15:0]gt1_drpdi_in;
  output [15:0]gt1_drpdo_out;
  input gt1_drpen_in;
  output gt1_drprdy_out;
  input gt1_drpwe_in;
  output [7:0]gt1_dmonitorout_out;
  input [2:0]gt1_loopback_in;
  input [2:0]gt1_rxrate_in;
  input gt1_eyescanreset_in;
  input gt1_rxuserrdy_in;
  output gt1_eyescandataerror_out;
  input gt1_eyescantrigger_in;
  input gt1_rxcdrhold_in;
  input gt1_rxusrclk_in;
  input gt1_rxusrclk2_in;
  output [63:0]gt1_rxdata_out;
  output gt1_rxprbserr_out;
  input [2:0]gt1_rxprbssel_in;
  input gt1_rxprbscntreset_in;
  input gt1_gtxrxp_in;
  input gt1_gtxrxn_in;
  input gt1_rxbufreset_in;
  output [2:0]gt1_rxbufstatus_out;
  input gt1_rxdfelpmreset_in;
  output [6:0]gt1_rxmonitorout_out;
  input [1:0]gt1_rxmonitorsel_in;
  output gt1_rxratedone_out;
  output gt1_rxoutclk_out;
  output gt1_rxoutclkfabric_out;
  output gt1_rxdatavalid_out;
  output [1:0]gt1_rxheader_out;
  output gt1_rxheadervalid_out;
  input gt1_rxgearboxslip_in;
  input gt1_gtrxreset_in;
  input gt1_rxpcsreset_in;
  input gt1_rxpmareset_in;
  input gt1_rxlpmen_in;
  input gt1_rxpolarity_in;
  output gt1_rxresetdone_out;
  input [4:0]gt1_txpostcursor_in;
  input [4:0]gt1_txprecursor_in;
  input gt1_gttxreset_in;
  input gt1_txuserrdy_in;
  input gt1_txusrclk_in;
  input gt1_txusrclk2_in;
  input gt1_txprbsforceerr_in;
  output [1:0]gt1_txbufstatus_out;
  input [3:0]gt1_txdiffctrl_in;
  input gt1_txinhibit_in;
  input [6:0]gt1_txmaincursor_in;
  input [63:0]gt1_txdata_in;
  output gt1_gtxtxn_out;
  output gt1_gtxtxp_out;
  output gt1_txoutclk_out;
  output gt1_txoutclkfabric_out;
  output gt1_txoutclkpcs_out;
  input [1:0]gt1_txheader_in;
  input [6:0]gt1_txsequence_in;
  input gt1_txpcsreset_in;
  input gt1_txpmareset_in;
  output gt1_txresetdone_out;
  input gt1_txpolarity_in;
  input [2:0]gt1_txprbssel_in;
  input gt2_gtnorthrefclk0_in;
  input gt2_gtnorthrefclk1_in;
  input gt2_gtsouthrefclk0_in;
  input gt2_gtsouthrefclk1_in;
  input [8:0]gt2_drpaddr_in;
  input gt2_drpclk_in;
  input [15:0]gt2_drpdi_in;
  output [15:0]gt2_drpdo_out;
  input gt2_drpen_in;
  output gt2_drprdy_out;
  input gt2_drpwe_in;
  output [7:0]gt2_dmonitorout_out;
  input [2:0]gt2_loopback_in;
  input [2:0]gt2_rxrate_in;
  input gt2_eyescanreset_in;
  input gt2_rxuserrdy_in;
  output gt2_eyescandataerror_out;
  input gt2_eyescantrigger_in;
  input gt2_rxcdrhold_in;
  input gt2_rxusrclk_in;
  input gt2_rxusrclk2_in;
  output [63:0]gt2_rxdata_out;
  output gt2_rxprbserr_out;
  input [2:0]gt2_rxprbssel_in;
  input gt2_rxprbscntreset_in;
  input gt2_gtxrxp_in;
  input gt2_gtxrxn_in;
  input gt2_rxbufreset_in;
  output [2:0]gt2_rxbufstatus_out;
  input gt2_rxdfelpmreset_in;
  output [6:0]gt2_rxmonitorout_out;
  input [1:0]gt2_rxmonitorsel_in;
  output gt2_rxratedone_out;
  output gt2_rxoutclk_out;
  output gt2_rxoutclkfabric_out;
  output gt2_rxdatavalid_out;
  output [1:0]gt2_rxheader_out;
  output gt2_rxheadervalid_out;
  input gt2_rxgearboxslip_in;
  input gt2_gtrxreset_in;
  input gt2_rxpcsreset_in;
  input gt2_rxpmareset_in;
  input gt2_rxlpmen_in;
  input gt2_rxpolarity_in;
  output gt2_rxresetdone_out;
  input [4:0]gt2_txpostcursor_in;
  input [4:0]gt2_txprecursor_in;
  input gt2_gttxreset_in;
  input gt2_txuserrdy_in;
  input gt2_txusrclk_in;
  input gt2_txusrclk2_in;
  input gt2_txprbsforceerr_in;
  output [1:0]gt2_txbufstatus_out;
  input [3:0]gt2_txdiffctrl_in;
  input gt2_txinhibit_in;
  input [6:0]gt2_txmaincursor_in;
  input [63:0]gt2_txdata_in;
  output gt2_gtxtxn_out;
  output gt2_gtxtxp_out;
  output gt2_txoutclk_out;
  output gt2_txoutclkfabric_out;
  output gt2_txoutclkpcs_out;
  input [1:0]gt2_txheader_in;
  input [6:0]gt2_txsequence_in;
  input gt2_txpcsreset_in;
  input gt2_txpmareset_in;
  output gt2_txresetdone_out;
  input gt2_txpolarity_in;
  input [2:0]gt2_txprbssel_in;
  input gt3_gtnorthrefclk0_in;
  input gt3_gtnorthrefclk1_in;
  input gt3_gtsouthrefclk0_in;
  input gt3_gtsouthrefclk1_in;
  input [8:0]gt3_drpaddr_in;
  input gt3_drpclk_in;
  input [15:0]gt3_drpdi_in;
  output [15:0]gt3_drpdo_out;
  input gt3_drpen_in;
  output gt3_drprdy_out;
  input gt3_drpwe_in;
  output [7:0]gt3_dmonitorout_out;
  input [2:0]gt3_loopback_in;
  input [2:0]gt3_rxrate_in;
  input gt3_eyescanreset_in;
  input gt3_rxuserrdy_in;
  output gt3_eyescandataerror_out;
  input gt3_eyescantrigger_in;
  input gt3_rxcdrhold_in;
  input gt3_rxusrclk_in;
  input gt3_rxusrclk2_in;
  output [63:0]gt3_rxdata_out;
  output gt3_rxprbserr_out;
  input [2:0]gt3_rxprbssel_in;
  input gt3_rxprbscntreset_in;
  input gt3_gtxrxp_in;
  input gt3_gtxrxn_in;
  input gt3_rxbufreset_in;
  output [2:0]gt3_rxbufstatus_out;
  input gt3_rxdfelpmreset_in;
  output [6:0]gt3_rxmonitorout_out;
  input [1:0]gt3_rxmonitorsel_in;
  output gt3_rxratedone_out;
  output gt3_rxoutclk_out;
  output gt3_rxoutclkfabric_out;
  output gt3_rxdatavalid_out;
  output [1:0]gt3_rxheader_out;
  output gt3_rxheadervalid_out;
  input gt3_rxgearboxslip_in;
  input gt3_gtrxreset_in;
  input gt3_rxpcsreset_in;
  input gt3_rxpmareset_in;
  input gt3_rxlpmen_in;
  input gt3_rxpolarity_in;
  output gt3_rxresetdone_out;
  input [4:0]gt3_txpostcursor_in;
  input [4:0]gt3_txprecursor_in;
  input gt3_gttxreset_in;
  input gt3_txuserrdy_in;
  input gt3_txusrclk_in;
  input gt3_txusrclk2_in;
  input gt3_txprbsforceerr_in;
  output [1:0]gt3_txbufstatus_out;
  input [3:0]gt3_txdiffctrl_in;
  input gt3_txinhibit_in;
  input [6:0]gt3_txmaincursor_in;
  input [63:0]gt3_txdata_in;
  output gt3_gtxtxn_out;
  output gt3_gtxtxp_out;
  output gt3_txoutclk_out;
  output gt3_txoutclkfabric_out;
  output gt3_txoutclkpcs_out;
  input [1:0]gt3_txheader_in;
  input [6:0]gt3_txsequence_in;
  input gt3_txpcsreset_in;
  input gt3_txpmareset_in;
  output gt3_txresetdone_out;
  input gt3_txpolarity_in;
  input [2:0]gt3_txprbssel_in;
  input gt0_qplllock_in;
  input gt0_qpllrefclklost_in;
  output gt0_qpllreset_out;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;
  input gt1_qplllock_in;
  input gt1_qpllrefclklost_in;
  output gt1_qpllreset_out;
  input gt1_qplloutclk_in;
  input gt1_qplloutrefclk_in;
endmodule
