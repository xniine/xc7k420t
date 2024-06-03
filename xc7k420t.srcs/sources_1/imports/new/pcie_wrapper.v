`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:

// Create Date:08/15/2022 02:17:40 PM
// Design Name:
// Module Name:pcie_wrapper
// Project Name:
// Target Devices:
// Tool Versions:
// Description:

// Dependencies:

// Revision:
// Revision 0.01 - File Created
// Additional Comments:

//////////////////////////////////////////////////////////////////////////////////

module pcie_wrapper(
    pci_exp_txn                               ,
    pci_exp_txp                               ,
    pci_exp_rxn                               ,
    pci_exp_rxp                               ,
    
 // pipe_pclk_in                              ,
 // pipe_rxusrclk_in                          ,
 // pipe_rxoutclk_in                          ,
 // pipe_dclk_in                              ,
 // pipe_userclk1_in                          ,
 // pipe_userclk2_in                          ,
 // pipe_oobclk_in                            ,
 // pipe_mmcm_lock_in                         ,
 // pipe_txoutclk_out                         ,
 // pipe_rxoutclk_out                         ,
 // pipe_pclk_sel_out                         ,
 // pipe_gen3_out                             ,
    
    user_clk_out                              ,
    user_reset_out                            ,
    user_lnk_up                               ,
    user_app_rdy                              ,
    tx_buf_av                                 ,
    tx_err_drop                               ,
    tx_cfg_req                                ,
    s_axis_tx_tdata                           ,
    s_axis_tx_tvalid                          ,
    s_axis_tx_tready                          ,
    s_axis_tx_tkeep                           ,
    s_axis_tx_tlast                           ,
    s_axis_tx_tuser                           ,
    tx_cfg_gnt                                ,
    m_axis_rx_tdata                           ,
    m_axis_rx_tvalid                          ,
    m_axis_rx_tready                          ,
    m_axis_rx_tkeep                           ,
    m_axis_rx_tlast                           ,
    m_axis_rx_tuser                           ,
    rx_np_ok                                  ,
    rx_np_req                                 ,
    fc_cpld                                   ,
    fc_cplh                                   ,
    fc_npd                                    ,
    fc_nph                                    ,
    fc_pd                                     ,
    fc_ph                                     ,
    fc_sel                                    ,

    cfg_status                                ,
    cfg_command                               ,
    cfg_dstatus                               ,
    cfg_dcommand                              ,
    cfg_lstatus                               ,
    cfg_lcommand                              ,
    cfg_dcommand2                             ,
    cfg_pcie_link_state                       ,

    cfg_pmcsr_pme_en                          ,
    cfg_pmcsr_powerstate                      ,
    cfg_pmcsr_pme_status                      ,
    cfg_received_func_lvl_rst                 ,

    cfg_mgmt_do                               ,
    cfg_mgmt_rd_wr_done                       ,
    cfg_mgmt_di                               ,
    cfg_mgmt_byte_en                          ,
    cfg_mgmt_dwaddr                           ,
    cfg_mgmt_wr_en                            ,
    cfg_mgmt_rd_en                            ,
    cfg_mgmt_wr_readonly                      ,

 // cfg_err_ecrc                              ,
 // cfg_err_ur                                ,
 // cfg_err_cpl_timeout                       ,
 // cfg_err_cpl_unexpect                      ,
 // cfg_err_cpl_abort                         ,
 // cfg_err_posted                            ,
 // cfg_err_cor                               ,
 // cfg_err_atomic_egress_blocked             ,
 // cfg_err_internal_cor                      ,
 // cfg_err_malformed                         ,
 // cfg_err_mc_blocked                        ,
 // cfg_err_poisoned                          ,
 // cfg_err_norecovery                        ,
 // cfg_err_tlp_cpl_header                    ,
 // cfg_err_cpl_rdy                           ,
 // cfg_err_locked                            ,
 // cfg_err_acs                               ,
 // cfg_err_internal_uncor                    ,

 // cfg_trn_pending                           ,
 // cfg_pm_halt_aspm_l0s                      ,
 // cfg_pm_halt_aspm_l1                       ,
 // cfg_pm_force_state_en                     ,
 // cfg_pm_force_state                        ,

 // cfg_dsn                                   ,
 // cfg_msg_received                          ,
 // cfg_msg_data                              ,

    cfg_interrupt                             , // EP Only
    cfg_interrupt_rdy                         , // EP Only
    cfg_interrupt_assert                      , // EP Only
    cfg_interrupt_di                          , // EP Only
    cfg_interrupt_do                          , // EP Only
    cfg_interrupt_mmenable                    , // EP Only
    cfg_interrupt_msienable                   , // EP Only
    cfg_interrupt_msixenable                  , // EP Only
    cfg_interrupt_msixfm                      , // EP Only
    cfg_interrupt_stat                        , // EP Only
 // cfg_pciecap_interrupt_msgnum              , // EP Only
 
 // cfg_to_turnoff                            , // EP Only
 // cfg_turnoff_ok                            , // EP Only
    cfg_bus_number                            , // EP Only
    cfg_device_number                         , // EP Only
    cfg_function_number                       , // EP Only
 // cfg_pm_wake                               , // EP Only
	
 // cfg_pm_send_pme_to                        , // RP Only
 // cfg_ds_bus_number                         , // RP Only
 // cfg_ds_device_number                      , // RP Only
 // cfg_ds_function_number                    , // RP Only
 // cfg_mgmt_wr_rw1c_as_rw                    , // RP Only
 // cfg_bridge_serr_en                        , // RP Only
 // cfg_slot_control_electromech_il_ctl_pulse , // RP Only
 // cfg_root_control_syserr_corr_err_en       , // RP Only
 // cfg_root_control_syserr_non_fatal_err_en  , // RP Only
 // cfg_root_control_syserr_fatal_err_en      , // RP Only
 // cfg_root_control_pme_int_en               , // RP Only
 // cfg_aer_rooterr_corr_err_reporting_en     , // RP Only
 // cfg_aer_rooterr_non_fatal_err_reporting_en, // RP Only
 // cfg_aer_rooterr_fatal_err_reporting_en    , // RP Only
 // cfg_aer_rooterr_corr_err_received         , // RP Only
 // cfg_aer_rooterr_non_fatal_err_received    , // RP Only
 // cfg_aer_rooterr_fatal_err_received        , // RP Only
 // cfg_msg_received_err_cor                  , // RP Only
 // cfg_msg_received_err_non_fatal            , // RP Only
 // cfg_msg_received_err_fatal                , // RP Only
 // cfg_msg_received_pm_pme                   , // RP Only
 // cfg_msg_received_pme_to_ack               , // RP Only
 // cfg_msg_received_assert_int_a             , // RP Only
 // cfg_msg_received_assert_int_b             , // RP Only
 // cfg_msg_received_assert_int_c             , // RP Only
 // cfg_msg_received_assert_int_d             , // RP Only
 // cfg_msg_received_deassert_int_a           , // RP Only
 // cfg_msg_received_deassert_int_b           , // RP Only
 // cfg_msg_received_deassert_int_c           , // RP Only
 // cfg_msg_received_deassert_int_d           , // RP Only
	
 // cfg_msg_received_pm_as_nak                ,
 // cfg_msg_received_setslotpowerlimit        ,

 // pl_directed_link_change                   ,
 // pl_directed_link_width                    ,
 // pl_directed_link_speed                    ,
 // pl_directed_link_auton                    ,
 // pl_upstream_prefer_deemph                 ,
 
 // pl_sel_lnk_rate                           ,
 // pl_sel_lnk_width                          ,
 // pl_ltssm_state                            ,
 // pl_lane_reversal_mode                     ,
 // pl_phy_lnk_up                             ,
 // pl_tx_pm_state                            ,
 // pl_rx_pm_state                            ,
 // pl_link_upcfg_cap                         ,
 // pl_link_gen2_cap                          ,
 // pl_link_partner_gen2_supported            ,
 // pl_initial_link_width                     ,
 // pl_directed_change_done                   ,
 
 // pl_received_hot_rst                       , // EP Only
 // pl_transmit_hot_rst                       , // RP Only
 // pl_downstream_deemph_source               , // RP Only
    
 // cfg_err_aer_headerlog                     ,
 // cfg_aer_interrupt_msgnum                  ,
 // cfg_err_aer_headerlog_set                 ,
 // cfg_aer_ecrc_check_en                     ,
 // cfg_aer_ecrc_gen_en                       ,

 // cfg_vc_tcvc_map                           ,

    pcie_drp_clk                              ,
    pcie_drp_en                               ,
    pcie_drp_we                               ,
    pcie_drp_addr                             ,
    pcie_drp_di                               ,
    pcie_drp_rdy                              ,
    pcie_drp_do                               ,

    sys_clk                                   ,
    sys_rst_n
    );

    localparam LINK_CAP_MAX_LINK_WIDTH = 4;
    localparam C_DATA_WIDTH = 128;
    localparam KEEP_WIDTH = 16;
    
    //////////////////////////////////////////////////////////////////////////////

    //----------------------------------------------------------------------------
    // 1. PCI Express (pci_exp) Interface
    //----------------------------------------------------------------------------
  
    // Tx
    output   wire [LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_txn; 
    output   wire [LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_txp; 
    // Rx
    input    wire [LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_rxn; 
    input    wire [LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_rxp; 
  
    //----------------------------------------------------------------------------
    // 2. Clock & GT COMMON Sharing Interface
    //----------------------------------------------------------------------------
    
    // Shared Logic External  - Clocks
 /* input */ wire                               pipe_pclk_in     ;
 /* input */ wire                               pipe_rxusrclk_in ;
 /* input */ wire [LINK_CAP_MAX_LINK_WIDTH-1:0] pipe_rxoutclk_in ;
 /* input */ wire                               pipe_dclk_in     ;
 /* input */ wire                               pipe_userclk1_in ;
 /* input */ wire                               pipe_userclk2_in ;
 /* input */ wire                               pipe_oobclk_in   ;
 /* input */ wire                               pipe_mmcm_lock_in;
 
 /* output*/ wire                               pipe_txoutclk_out;
 /* output*/ wire [LINK_CAP_MAX_LINK_WIDTH-1:0] pipe_rxoutclk_out;
 /* output*/ wire [LINK_CAP_MAX_LINK_WIDTH-1:0] pipe_pclk_sel_out;
 /* output*/ wire                               pipe_gen3_out    ; // Ignored by pcie_pipe_clk
   
    //----------------------------------------------------------------------------
    // 3. AXI-S Interface
    //----------------------------------------------------------------------------
  
    // Common
    output   wire                    user_clk_out      ; 
    output   wire                    user_reset_out    ; 
    output   wire                    user_lnk_up       ; 
    output   wire                    user_app_rdy      ; 
 
    // AXI Tx
    output   wire [             5:0] tx_buf_av         ; 
    output   wire                    tx_err_drop       ; 
    output   wire                    tx_cfg_req        ; 
    input    wire [C_DATA_WIDTH-1:0] s_axis_tx_tdata   ; 
    input    wire                    s_axis_tx_tvalid  ; 
    output   wire                    s_axis_tx_tready  ; 
    input    wire [  KEEP_WIDTH-1:0] s_axis_tx_tkeep   ; 
    input    wire                    s_axis_tx_tlast   ; 
    input    wire [             3:0] s_axis_tx_tuser   ; 
    input    wire                    tx_cfg_gnt        ; 
 
    // AXI Rx
    output   wire [C_DATA_WIDTH-1:0] m_axis_rx_tdata   ; 
    output   wire                    m_axis_rx_tvalid  ; 
    input    wire                    m_axis_rx_tready  ; 
    output   wire [  KEEP_WIDTH-1:0] m_axis_rx_tkeep   ; 
    output   wire                    m_axis_rx_tlast   ; 
    output   wire [            21:0] m_axis_rx_tuser   ; 
    input    wire                    rx_np_ok          ; 
    input    wire                    rx_np_req         ; 
 
    // Flow Control
    output   wire [            11:0] fc_cpld           ; 
    output   wire [             7:0] fc_cplh           ; 
    output   wire [            11:0] fc_npd            ; 
    output   wire [             7:0] fc_nph            ; 
    output   wire [            11:0] fc_pd             ; 
    output   wire [             7:0] fc_ph             ; 
    input    wire [             2:0] fc_sel            ; 
  
    //----------------------------------------------------------------------------
    // 4. Configuration (CFG) Interface
    //----------------------------------------------------------------------------
  
    // EP and RP -----------------------------------------------------------------
    
    output   wire [ 15:0] cfg_status                   ; 
    output   wire [ 15:0] cfg_command                  ; 
    output   wire [ 15:0] cfg_dstatus                  ; 
    output   wire [ 15:0] cfg_dcommand                 ; 
    output   wire [ 15:0] cfg_lstatus                  ; 
    output   wire [ 15:0] cfg_lcommand                 ; 
    output   wire [ 15:0] cfg_dcommand2                ; 
    output   wire [  2:0] cfg_pcie_link_state          ; 
  
    output   wire         cfg_pmcsr_pme_en             ; 
    output   wire [  1:0] cfg_pmcsr_powerstate         ; 
    output   wire         cfg_pmcsr_pme_status         ; 
    output   wire         cfg_received_func_lvl_rst    ; 
  
    // Management Interface
    output   wire [ 31:0] cfg_mgmt_do                  ; 
    output   wire         cfg_mgmt_rd_wr_done          ; 
    input    wire [ 31:0] cfg_mgmt_di                  ; 
    input    wire [  3:0] cfg_mgmt_byte_en             ; 
    input    wire [  9:0] cfg_mgmt_dwaddr              ; 
    input    wire         cfg_mgmt_wr_en               ; 
    input    wire         cfg_mgmt_rd_en               ; 
    input    wire         cfg_mgmt_wr_readonly         ; 
  
    // Error Reporting Interface
 /* input */ wire         cfg_err_ecrc                 ; 
 /* input */ wire         cfg_err_ur                   ; 
 /* input */ wire         cfg_err_cpl_timeout          ; 
 /* input */ wire         cfg_err_cpl_unexpect         ; 
 /* input */ wire         cfg_err_cpl_abort            ; 
 /* input */ wire         cfg_err_posted               ; 
 /* input */ wire         cfg_err_cor                  ; 
 /* input */ wire         cfg_err_atomic_egress_blocked; 
 /* input */ wire         cfg_err_internal_cor         ; 
 /* input */ wire         cfg_err_malformed            ; 
 /* input */ wire         cfg_err_mc_blocked           ; 
 /* input */ wire         cfg_err_poisoned             ; 
 /* input */ wire         cfg_err_norecovery           ; 
 /* input */ wire [ 47:0] cfg_err_tlp_cpl_header       ; 
 /* output*/ wire         cfg_err_cpl_rdy              ; 
 /* input */ wire         cfg_err_locked               ; 
 /* input */ wire         cfg_err_acs                  ; 
 /* input */ wire         cfg_err_internal_uncor       ; 
  
 /* input */ wire         cfg_trn_pending              ; 
 /* input */ wire         cfg_pm_halt_aspm_l0s         ; 
 /* input */ wire         cfg_pm_halt_aspm_l1          ; 
 /* input */ wire         cfg_pm_force_state_en        ; 
 /* input */ wire [  1:0] cfg_pm_force_state           ; 
  
 /* input */ wire [ 63:0] cfg_dsn                      ; 
 /* output*/ wire         cfg_msg_received             ; 
 /* output*/ wire [ 15:0] cfg_msg_data                 ; 
  
    // EP Only -------------------------------------------------------------------
  
    // Interrupt Interface Signals
    input    wire         cfg_interrupt                ; 
    output   wire         cfg_interrupt_rdy            ; 
    input    wire         cfg_interrupt_assert         ; 
    input    wire [  7:0] cfg_interrupt_di             ; 
    output   wire [  7:0] cfg_interrupt_do             ; 
    output   wire [  2:0] cfg_interrupt_mmenable       ; 
    output   wire         cfg_interrupt_msienable      ; 
    output   wire         cfg_interrupt_msixenable     ; 
    output   wire         cfg_interrupt_msixfm         ; 
    input    wire         cfg_interrupt_stat           ; 
 /* input*/  wire [  4:0] cfg_pciecap_interrupt_msgnum ; 
  
 /* output*/ wire         cfg_to_turnoff               ; 
 /* input */ wire         cfg_turnoff_ok               ; 
    output   wire [  7:0] cfg_bus_number               ; 
    output   wire [  4:0] cfg_device_number            ; 
    output   wire [  2:0] cfg_function_number          ; 
 /* input */ wire         cfg_pm_wake                  ; 
  
 /* output*/ wire         cfg_msg_received_pm_as_nak   ; 
 /* output*/ wire         cfg_msg_received_setslotpowerlimit; 

    // RP Only ---- ---------------------------------------------------------------
	
 /* input */ wire         cfg_pm_send_pme_to                        ; 
 /* input */ wire [  7:0] cfg_ds_bus_number                         ; 
 /* input */ wire [  4:0] cfg_ds_device_number                      ; 
 /* input */ wire [  2:0] cfg_ds_function_number                    ; 
 /* input */ wire         cfg_mgmt_wr_rw1c_as_rw                    ; 
    
 /* output*/ wire         cfg_bridge_serr_en                        ; 
 /* output*/ wire         cfg_slot_control_electromech_il_ctl_pulse ; 
 /* output*/ wire         cfg_root_control_syserr_corr_err_en       ; 
 /* output*/ wire         cfg_root_control_syserr_non_fatal_err_en  ; 
 /* output*/ wire         cfg_root_control_syserr_fatal_err_en      ; 
 /* output*/ wire         cfg_root_control_pme_int_en               ; 
 /* output*/ wire         cfg_aer_rooterr_corr_err_reporting_en     ; 
 /* output*/ wire         cfg_aer_rooterr_non_fatal_err_reporting_en; 
 /* output*/ wire         cfg_aer_rooterr_fatal_err_reporting_en    ; 
 /* output*/ wire         cfg_aer_rooterr_corr_err_received         ; 
 /* output*/ wire         cfg_aer_rooterr_non_fatal_err_received    ; 
 /* output*/ wire         cfg_aer_rooterr_fatal_err_received        ;
 
 /* output*/ wire         cfg_msg_received_err_cor                  ; 
 /* output*/ wire         cfg_msg_received_err_non_fatal            ; 
 /* output*/ wire         cfg_msg_received_err_fatal                ; 
 /* output*/ wire         cfg_msg_received_pm_pme                   ; 
 /* output*/ wire         cfg_msg_received_pme_to_ack               ; 
 /* output*/ wire         cfg_msg_received_assert_int_a             ; 
 /* output*/ wire         cfg_msg_received_assert_int_b             ; 
 /* output*/ wire         cfg_msg_received_assert_int_c             ; 
 /* output*/ wire         cfg_msg_received_assert_int_d             ; 
 /* output*/ wire         cfg_msg_received_deassert_int_a           ; 
 /* output*/ wire         cfg_msg_received_deassert_int_b           ; 
 /* output*/ wire         cfg_msg_received_deassert_int_c           ; 
 /* output*/ wire         cfg_msg_received_deassert_int_d           ; 
  	 
    //----------------------------------------------------------------------------
    // 5. Physical Layer Control and Status (PL) Interface
    //----------------------------------------------------------------------------
  
    // EP and RP -----------------------------------------------------------------
    
 /* input */ wire [  1:0] pl_directed_link_change       ; 
 /* input */ wire [  1:0] pl_directed_link_width        ; 
 /* input */ wire         pl_directed_link_speed        ; 
 /* input */ wire         pl_directed_link_auton        ; 
 /* input */ wire         pl_upstream_prefer_deemph     ; 
 
 /* output*/ wire         pl_sel_lnk_rate               ; 
 /* output*/ wire [  1:0] pl_sel_lnk_width              ; 
 /* output*/ wire [  5:0] pl_ltssm_state                ; 
 /* output*/ wire [  1:0] pl_lane_reversal_mode         ; 
 /* output*/ wire         pl_phy_lnk_up                 ; 
 /* output*/ wire [  2:0] pl_tx_pm_state                ; 
 /* output*/ wire [  1:0] pl_rx_pm_state                ; 
 /* output*/ wire         pl_link_upcfg_cap             ; 
 /* output*/ wire         pl_link_gen2_cap              ; 
 /* output*/ wire         pl_link_partner_gen2_supported; 
 /* output*/ wire [  2:0] pl_initial_link_width         ; 
 /* output*/ wire         pl_directed_change_done       ; 
                         
    // EP Only -------------------------------------------------------------------

 /* output*/ wire         pl_received_hot_rst           ;

    // RP Only -------------------------------------------------------------------
	 
 /* input */ wire         pl_transmit_hot_rst           ; 
 /* input */ wire         pl_downstream_deemph_source   ; 
	
    //----------------------------------------------------------------------------
    // 6. AER interface
    //----------------------------------------------------------------------------
  
 /* input */ wire [127:0] cfg_err_aer_headerlog    ; 
 /* input */ wire [  4:0] cfg_aer_interrupt_msgnum ; 
 /* output*/ wire         cfg_err_aer_headerlog_set; 
 /* output*/ wire         cfg_aer_ecrc_check_en    ; 
 /* output*/ wire         cfg_aer_ecrc_gen_en      ; 
  
    //----------------------------------------------------------------------------
    // 7. VC interface
    //----------------------------------------------------------------------------
  
 /* output*/ wire [  6:0] cfg_vc_tcvc_map; 
  
    //----------------------------------------------------------------------------
    // 8. PCIe DRP (PCIe DRP) Interface
    //----------------------------------------------------------------------------
  
    input    wire         pcie_drp_clk ; 
    input    wire         pcie_drp_en  ; 
    input    wire         pcie_drp_we  ; 
    input    wire [  8:0] pcie_drp_addr; 
    input    wire [ 15:0] pcie_drp_di  ; 
    output   wire         pcie_drp_rdy ; 
    output   wire [ 15:0] pcie_drp_do  ; 

    //----------------------------------------------------------------------------
    // System (SYS) Interface
    //----------------------------------------------------------------------------
    
 /* input */ wire         pipe_mmcm_rst_n; 
    input    wire         sys_clk        ; 
    input    wire         sys_rst_n      ; 
  
    //////////////////////////////////////////////////////////////////////////////
    
    // System (SYS) Interface
    assign pipe_mmcm_rst_n = sys_rst_n;
    
    // Config CTRL
    assign cfg_trn_pending               = 0;
    assign cfg_pm_halt_aspm_l0s          = 0;
    assign cfg_pm_halt_aspm_l1           = 0;
    assign cfg_pm_force_state_en         = 0;
    assign cfg_pm_force_state            = 0;
    assign cfg_dsn                       = 0;
    assign cfg_pciecap_interrupt_msgnum  = 0;
    assign cfg_turnoff_ok                = 0;
    assign cfg_pm_wake                   = 0;

    // Error Reporting
    assign cfg_err_ecrc                  = 0;
    assign cfg_err_ur                    = 0;
    assign cfg_err_cpl_timeout           = 0;
    assign cfg_err_cpl_unexpect          = 0;
    assign cfg_err_cpl_abort             = 0;
    assign cfg_err_posted                = 0;
    assign cfg_err_cor                   = 0;
    assign cfg_err_atomic_egress_blocked = 0;
    assign cfg_err_internal_cor          = 0;
    assign cfg_err_malformed             = 0;
    assign cfg_err_mc_blocked            = 0;
    assign cfg_err_poisoned              = 0;
    assign cfg_err_norecovery            = 0;
    assign cfg_err_tlp_cpl_header        = 0;
    assign cfg_err_locked                = 0;
    assign cfg_err_acs                   = 0;
    assign cfg_err_internal_uncor        = 0;
    assign cfg_err_aer_headerlog         = 0;
    assign cfg_aer_interrupt_msgnum      = 0;
    
    // Physical Layer Control and Status
    assign pl_directed_link_change       = 0;
    assign pl_directed_link_width        = 0;
    assign pl_directed_link_speed        = 0;
    assign pl_directed_link_auton        = 0;
    assign pl_upstream_prefer_deemph     = 0;
    
    // VC interface
    assign cfg_vc_tcvc_map               = 0;
    
    // RP Only (not used)
    assign cfg_pm_send_pme_to            = 0;
    assign cfg_ds_bus_number             = 0;
    assign cfg_ds_device_number          = 0;
    assign cfg_ds_function_number        = 0;
    assign cfg_mgmt_wr_rw1c_as_rw        = 1;
    assign pl_transmit_hot_rst           = 0;   
    assign pl_downstream_deemph_source   = 0;
    
    //----------------------------------------------------------------------------
    // PIPE Clock
    //----------------------------------------------------------------------------
    
    pcie_pipe_clock pcie_pipe_clock_inst (
        .sys_clk           (sys_clk          ),
    
        .pipe_txoutclk_in  (pipe_txoutclk_out),
        .pipe_rxoutclk_in  (pipe_rxoutclk_out),
        .pipe_pclk_sel_in  (pipe_pclk_sel_out),
        .pipe_gen3_in      (pipe_gen3_out    ),
        .pipe_mmcm_rst_n   (pipe_mmcm_rst_n  ),
        
        .pipe_pclk_out     (pipe_pclk_in     ),
        .pipe_rxusrclk_out (pipe_rxusrclk_in ),
        .pipe_rxoutclk_out (pipe_rxoutclk_in ),
        .pipe_dclk_out     (pipe_dclk_in     ),
        .pipe_userclk2_out (pipe_userclk2_in ),
        .pipe_userclk1_out (pipe_userclk1_in ),
        .pipe_oobclk_out   (pipe_oobclk_in   ),
        .pipe_mmcm_lock_out(pipe_mmcm_lock_in)
    );
    
    //----------------------------------------------------------------------------
 	// Integrated Block of PCIe
    //----------------------------------------------------------------------------
    
    pcie_7x_0 pcie_7x_0_inst(
        .pci_exp_txn                               (pci_exp_txn                               ),
		.pci_exp_txp                               (pci_exp_txp                               ),
        .pci_exp_rxn                               (pci_exp_rxn                               ),
        .pci_exp_rxp                               (pci_exp_rxp                               ),
        
        .pipe_pclk_in                              (pipe_pclk_in                              ),
        .pipe_rxusrclk_in                          (pipe_rxusrclk_in                          ),
        .pipe_rxoutclk_in                          (pipe_rxoutclk_in                          ),
        .pipe_dclk_in                              (pipe_dclk_in                              ),
        .pipe_userclk1_in                          (pipe_userclk1_in                          ),
        .pipe_userclk2_in                          (pipe_userclk2_in                          ),
        .pipe_oobclk_in                            (pipe_oobclk_in                            ),
        .pipe_mmcm_lock_in                         (pipe_mmcm_lock_in                         ),
        .pipe_txoutclk_out                         (pipe_txoutclk_out                         ),
        .pipe_rxoutclk_out                         (pipe_rxoutclk_out                         ),
        .pipe_pclk_sel_out                         (pipe_pclk_sel_out                         ),
        .pipe_gen3_out                             (pipe_gen3_out                             ),
        
        .user_clk_out                              (user_clk_out                              ),
        .user_reset_out                            (user_reset_out                            ),
        .user_lnk_up                               (user_lnk_up                               ),
        .user_app_rdy                              (user_app_rdy                              ),
        .tx_buf_av                                 (tx_buf_av                                 ),
        .tx_err_drop                               (tx_err_drop                               ),
        .tx_cfg_req                                (tx_cfg_req                                ),
        .s_axis_tx_tdata                           (s_axis_tx_tdata                           ),
        .s_axis_tx_tvalid                          (s_axis_tx_tvalid                          ),
        .s_axis_tx_tready                          (s_axis_tx_tready                          ),
        .s_axis_tx_tkeep                           (s_axis_tx_tkeep                           ),
        .s_axis_tx_tlast                           (s_axis_tx_tlast                           ),
        .s_axis_tx_tuser                           (s_axis_tx_tuser                           ),
        .tx_cfg_gnt                                (tx_cfg_gnt                                ),
        .m_axis_rx_tdata                           (m_axis_rx_tdata                           ),
        .m_axis_rx_tvalid                          (m_axis_rx_tvalid                          ),
        .m_axis_rx_tready                          (m_axis_rx_tready                          ),
        .m_axis_rx_tkeep                           (m_axis_rx_tkeep                           ),
        .m_axis_rx_tlast                           (m_axis_rx_tlast                           ),
        .m_axis_rx_tuser                           (m_axis_rx_tuser                           ),
        .rx_np_ok                                  (rx_np_ok                                  ),
        .rx_np_req                                 (rx_np_req                                 ),
        .fc_cpld                                   (fc_cpld                                   ),
        .fc_cplh                                   (fc_cplh                                   ),
        .fc_npd                                    (fc_npd                                    ),
        .fc_nph                                    (fc_nph                                    ),
        .fc_pd                                     (fc_pd                                     ),
        .fc_ph                                     (fc_ph                                     ),
        .fc_sel                                    (fc_sel                                    ),
        
        .cfg_mgmt_do                               (cfg_mgmt_do                               ),
        .cfg_mgmt_rd_wr_done                       (cfg_mgmt_rd_wr_done                       ),
        .cfg_status                                (cfg_status                                ),
        .cfg_command                               (cfg_command                               ),
        .cfg_dstatus                               (cfg_dstatus                               ),
        .cfg_dcommand                              (cfg_dcommand                              ),
        .cfg_lstatus                               (cfg_lstatus                               ),
        .cfg_lcommand                              (cfg_lcommand                              ),
        .cfg_dcommand2                             (cfg_dcommand2                             ),
        .cfg_pcie_link_state                       (cfg_pcie_link_state                       ),
        .cfg_pmcsr_pme_en                          (cfg_pmcsr_pme_en                          ),
        .cfg_pmcsr_powerstate                      (cfg_pmcsr_powerstate                      ),
        .cfg_pmcsr_pme_status                      (cfg_pmcsr_pme_status                      ),
        .cfg_received_func_lvl_rst                 (cfg_received_func_lvl_rst                 ),
        .cfg_mgmt_di                               (cfg_mgmt_di                               ),
        .cfg_mgmt_byte_en                          (cfg_mgmt_byte_en                          ),
        .cfg_mgmt_dwaddr                           (cfg_mgmt_dwaddr                           ),
        .cfg_mgmt_wr_en                            (cfg_mgmt_wr_en                            ),
        .cfg_mgmt_rd_en                            (cfg_mgmt_rd_en                            ),
        .cfg_mgmt_wr_readonly                      (cfg_mgmt_wr_readonly                      ),
        .cfg_err_ecrc                              (cfg_err_ecrc                              ),
        .cfg_err_ur                                (cfg_err_ur                                ),
        .cfg_err_cpl_timeout                       (cfg_err_cpl_timeout                       ),
        .cfg_err_cpl_unexpect                      (cfg_err_cpl_unexpect                      ),
        .cfg_err_cpl_abort                         (cfg_err_cpl_abort                         ),
        .cfg_err_posted                            (cfg_err_posted                            ),
        .cfg_err_cor                               (cfg_err_cor                               ),
        .cfg_err_atomic_egress_blocked             (cfg_err_atomic_egress_blocked             ),
        .cfg_err_internal_cor                      (cfg_err_internal_cor                      ),
        .cfg_err_malformed                         (cfg_err_malformed                         ),
        .cfg_err_mc_blocked                        (cfg_err_mc_blocked                        ),
        .cfg_err_poisoned                          (cfg_err_poisoned                          ),
        .cfg_err_norecovery                        (cfg_err_norecovery                        ),
        .cfg_err_tlp_cpl_header                    (cfg_err_tlp_cpl_header                    ),
        .cfg_err_cpl_rdy                           (cfg_err_cpl_rdy                           ),
        .cfg_err_locked                            (cfg_err_locked                            ),
        .cfg_err_acs                               (cfg_err_acs                               ),
        .cfg_err_internal_uncor                    (cfg_err_internal_uncor                    ),
        .cfg_trn_pending                           (cfg_trn_pending                           ),
        .cfg_pm_halt_aspm_l0s                      (cfg_pm_halt_aspm_l0s                      ),
        .cfg_pm_halt_aspm_l1                       (cfg_pm_halt_aspm_l1                       ),
        .cfg_pm_force_state_en                     (cfg_pm_force_state_en                     ),
        .cfg_pm_force_state                        (cfg_pm_force_state                        ),
        .cfg_dsn                                   (cfg_dsn                                   ),
        .cfg_msg_received                          (cfg_msg_received                          ),
        .cfg_msg_data                              (cfg_msg_data                              ),
        .cfg_interrupt                             (cfg_interrupt                             ), // EP Only
        .cfg_interrupt_rdy                         (cfg_interrupt_rdy                         ), // EP Only
        .cfg_interrupt_assert                      (cfg_interrupt_assert                      ), // EP Only
        .cfg_interrupt_di                          (cfg_interrupt_di                          ), // EP Only
        .cfg_interrupt_do                          (cfg_interrupt_do                          ), // EP Only
        .cfg_interrupt_mmenable                    (cfg_interrupt_mmenable                    ), // EP Only
        .cfg_interrupt_msienable                   (cfg_interrupt_msienable                   ), // EP Only
        .cfg_interrupt_msixenable                  (cfg_interrupt_msixenable                  ), // EP Only
        .cfg_interrupt_msixfm                      (cfg_interrupt_msixfm                      ), // EP Only
        .cfg_interrupt_stat                        (cfg_interrupt_stat                        ), // EP Only
        .cfg_pciecap_interrupt_msgnum              (cfg_pciecap_interrupt_msgnum              ), // EP Only
        .cfg_to_turnoff                            (cfg_to_turnoff                            ), // EP Only
        .cfg_turnoff_ok                            (cfg_turnoff_ok                            ), // EP Only
        .cfg_bus_number                            (cfg_bus_number                            ), // EP Only
        .cfg_device_number                         (cfg_device_number                         ), // EP Only
        .cfg_function_number                       (cfg_function_number                       ), // EP Only
        .cfg_pm_wake                               (cfg_pm_wake                               ), // EP Only
        
		.cfg_pm_send_pme_to                        (cfg_pm_send_pme_to                        ), // RP Only
        .cfg_ds_bus_number                         (cfg_ds_bus_number                         ), // RP Only
        .cfg_ds_device_number                      (cfg_ds_device_number                      ), // RP Only
        .cfg_ds_function_number                    (cfg_ds_function_number                    ), // RP Only
        .cfg_mgmt_wr_rw1c_as_rw                    (cfg_mgmt_wr_rw1c_as_rw                    ), // RP Only
        .cfg_bridge_serr_en                        (cfg_bridge_serr_en                        ), // RP Only
        .cfg_slot_control_electromech_il_ctl_pulse (cfg_slot_control_electromech_il_ctl_pulse ), // RP Only
        .cfg_root_control_syserr_corr_err_en       (cfg_root_control_syserr_corr_err_en       ), // RP Only
        .cfg_root_control_syserr_non_fatal_err_en  (cfg_root_control_syserr_non_fatal_err_en  ), // RP Only
        .cfg_root_control_syserr_fatal_err_en      (cfg_root_control_syserr_fatal_err_en      ), // RP Only
        .cfg_root_control_pme_int_en               (cfg_root_control_pme_int_en               ), // RP Only
        .cfg_aer_rooterr_corr_err_reporting_en     (cfg_aer_rooterr_corr_err_reporting_en     ), // RP Only
        .cfg_aer_rooterr_non_fatal_err_reporting_en(cfg_aer_rooterr_non_fatal_err_reporting_en), // RP Only
        .cfg_aer_rooterr_fatal_err_reporting_en    (cfg_aer_rooterr_fatal_err_reporting_en    ), // RP Only
        .cfg_aer_rooterr_corr_err_received         (cfg_aer_rooterr_corr_err_received         ), // RP Only
        .cfg_aer_rooterr_non_fatal_err_received    (cfg_aer_rooterr_non_fatal_err_received    ), // RP Only
        .cfg_aer_rooterr_fatal_err_received        (cfg_aer_rooterr_fatal_err_received        ), // RP Only
        .cfg_msg_received_err_cor                  (cfg_msg_received_err_cor                  ), // RP Only
        .cfg_msg_received_err_non_fatal            (cfg_msg_received_err_non_fatal            ), // RP Only
        .cfg_msg_received_err_fatal                (cfg_msg_received_err_fatal                ), // RP Only
        .cfg_msg_received_pm_pme                   (cfg_msg_received_pm_pme                   ), // RP Only
        .cfg_msg_received_pme_to_ack               (cfg_msg_received_pme_to_ack               ), // RP Only
        .cfg_msg_received_assert_int_a             (cfg_msg_received_assert_int_a             ), // RP Only
        .cfg_msg_received_assert_int_b             (cfg_msg_received_assert_int_b             ), // RP Only
        .cfg_msg_received_assert_int_c             (cfg_msg_received_assert_int_c             ), // RP Only
        .cfg_msg_received_assert_int_d             (cfg_msg_received_assert_int_d             ), // RP Only
        .cfg_msg_received_deassert_int_a           (cfg_msg_received_deassert_int_a           ), // RP Only
        .cfg_msg_received_deassert_int_b           (cfg_msg_received_deassert_int_b           ), // RP Only
        .cfg_msg_received_deassert_int_c           (cfg_msg_received_deassert_int_c           ), // RP Only
        .cfg_msg_received_deassert_int_d           (cfg_msg_received_deassert_int_d           ), // RP Only
        
        .cfg_msg_received_pm_as_nak                (cfg_msg_received_pm_as_nak                ),
        .cfg_msg_received_setslotpowerlimit        (cfg_msg_received_setslotpowerlimit        ),
        .pl_directed_link_change                   (pl_directed_link_change                   ),
        .pl_directed_link_width                    (pl_directed_link_width                    ),
        .pl_directed_link_speed                    (pl_directed_link_speed                    ),
        .pl_directed_link_auton                    (pl_directed_link_auton                    ),
        .pl_upstream_prefer_deemph                 (pl_upstream_prefer_deemph                 ),
        .pl_sel_lnk_rate                           (pl_sel_lnk_rate                           ),
        .pl_sel_lnk_width                          (pl_sel_lnk_width                          ),
        .pl_ltssm_state                            (pl_ltssm_state                            ),
        .pl_lane_reversal_mode                     (pl_lane_reversal_mode                     ),
        .pl_phy_lnk_up                             (pl_phy_lnk_up                             ),
        .pl_tx_pm_state                            (pl_tx_pm_state                            ),
        .pl_rx_pm_state                            (pl_rx_pm_state                            ),
        .pl_link_upcfg_cap                         (pl_link_upcfg_cap                         ),
        .pl_link_gen2_cap                          (pl_link_gen2_cap                          ),
        .pl_link_partner_gen2_supported            (pl_link_partner_gen2_supported            ),
        .pl_initial_link_width                     (pl_initial_link_width                     ),
        .pl_directed_change_done                   (pl_directed_change_done                   ),
        .pl_received_hot_rst                       (pl_received_hot_rst                       ), // EP Only
        
        .pl_transmit_hot_rst                       (pl_transmit_hot_rst                       ), // RP Only
        .pl_downstream_deemph_source               (pl_downstream_deemph_source               ), // RP Only
        
        .cfg_err_aer_headerlog                     (cfg_err_aer_headerlog                     ),
        .cfg_aer_interrupt_msgnum                  (cfg_aer_interrupt_msgnum                  ),
        .cfg_err_aer_headerlog_set                 (cfg_err_aer_headerlog_set                 ),
        .cfg_aer_ecrc_check_en                     (cfg_aer_ecrc_check_en                     ),
        .cfg_aer_ecrc_gen_en                       (cfg_aer_ecrc_gen_en                       ),
        .cfg_vc_tcvc_map                           (cfg_vc_tcvc_map                           ),
        
        .pcie_drp_clk                              (pcie_drp_clk                              ),
        .pcie_drp_en                               (pcie_drp_en                               ),
        .pcie_drp_we                               (pcie_drp_we                               ),
        .pcie_drp_addr                             (pcie_drp_addr                             ),
        .pcie_drp_di                               (pcie_drp_di                               ),
        .pcie_drp_rdy                              (pcie_drp_rdy                              ),
        .pcie_drp_do                               (pcie_drp_do                               ),
        
        .startup_cfgclk                            (                                          ),         // 1-bit output: Configuration main clock output
        .startup_cfgmclk                           (                                          ),         // 1-bit output: Configuration internal oscillator clock output
        .startup_eos                               (                                          ),         // 1-bit output: Active high output signal indicating the End Of Startup.
        .startup_preq                              (                                          ),         // 1-bit output: PROGRAM request to fabric output
        .startup_clk                               (1'b0                                      ),         // 1-bit input: User start-up clock input
        .startup_gsr                               (1'b0                                      ),         // 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
        .startup_gts                               (1'b0                                      ),         // 1-bit input: Global 3-state input (GTS cannot be used for the port name)
        .startup_keyclearb                         (1'b1                                      ),         // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
        .startup_pack                              (1'b0                                      ),         // 1-bit input: PROGRAM acknowledge input
        .startup_usrcclko                          (1'b0                                      ),         // 1-bit input: User CCLK input
        .startup_usrcclkts                         (1'b1                                      ),         // 1-bit input: User CCLK 3-state enable input
        .startup_usrdoneo                          (1'b0                                      ),         // 1-bit input: User DONE pin output control
        .startup_usrdonets                         (1'b1                                      ),         // 1-bit input: User DONE 3-state enable output
        
        .pipe_mmcm_rst_n                           (pipe_mmcm_rst_n                           ),
        .sys_clk                                   (sys_clk                                   ),
        .sys_rst_n                                 (sys_rst_n                                 )
    );
    
endmodule
