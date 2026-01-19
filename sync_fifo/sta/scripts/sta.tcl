set BLOCK_NAME "sync_fifo"

## cell libs
# X-FAB 0.18um
set LIB_PATH "/eda/xfab/XKIT/x_all/cadence/XFAB_Digital_Power_RefKit-cadence/v1_3_1/pdk/xh018/diglibs/D_CELLS_JIHD/v4_1/liberty_LPMOS/v4_1_1/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_slow_1_62V_125C.lib"
# AMS 0.35um
#set LIB_PATH "/eda/AMS/AMS_410_ISR15/liberty/c35_1.8V/c35_CORELIB_WC.lib"

set REPORT_DIR "../rep"

################################
# Load netlist 
################################

source ../scripts/load_design.tcl

################################
# Load parasitics
################################

read_spef -rc_corner rc_cworst ../in/${BLOCK_NAME}_rc_cworst.spef
read_spef -rc_corner rc_cbest ../in/${BLOCK_NAME}_rc_cbest.spef

################################
# Add constraints
################################

read_sdc ../../tcons/${BLOCK_NAME}_func.sdc

################################
# Adjust timer settings
################################

set_delay_cal_mode -siAware true    ;# Turn on SI when true

################################################################
#To dump aggressor info in report_delay_calculation -si command
#################################################################

set_si_mode -enable_delay_report true
set_si_mode -separate_delta_delay_on_data true

##########################################
#enable the glitch reports to be generated
##########################################

set_si_mode -enable_glitch_report true

##########################
#Enable glitch propagation
##########################

set_si_mode -enable_glitch_propagation true
set_global timing_pba_exhaustive_path_nworst_limit 2
set_global timing_path_based_exhaustive_max_paths_limit 1000
#set_global timing_path_based_enable_exhaustive_depth_bounded_by_gba false

###################################
# Run timing
###################################

update_timing -full

###################################
# Create reports
###################################

source ../scripts/reports.tcl


puts "STA completed"
###################################
# If in interactive session, return to the Tempus prompt
# If in batch session, return to the Linux prompt
###################################
#exit
