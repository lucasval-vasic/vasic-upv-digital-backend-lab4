################################
# Setup threading and client counts
################################
set_multi_cpu_usage -localCpu 8

################################
# Setup some global variables or report settings
################################
set_table_style -no_frame_fix_width -nosplit

################################
# Create views
################################
read_view_definition ../scripts/setup_mmmc.tcl

################################
# Read the netlist
################################
read_verilog "../in/$BLOCK_NAME.vg"

################################
# Link the design
################################
set_top_module $BLOCK_NAME 

################################
# Check the size of the design to ensure it was loaded correctly
################################
set cellCnt [sizeof_collection [get_cells -hier *]]
puts "Your design has: $cellCnt instances"
