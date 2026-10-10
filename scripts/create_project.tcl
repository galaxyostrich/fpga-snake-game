# -----------------------------------------------------------------------------
# create_project.tcl
#
# Recreates the Vivado project for the FPGA Snake Game from the files tracked
# in this repository. All paths are resolved relative to this script.
#
# Usage (from the repository root):
#   Create project only:
#     vivado -mode batch -source scripts/create_project.tcl
#   Create project and run synthesis, implementation and bitstream generation:
#     vivado -mode batch -source scripts/create_project.tcl -tclargs build
#   From the Vivado Tcl console (GUI):
#     source <repo>/scripts/create_project.tcl
#
# The project is generated in <repo>/build/ (ignored by git). Any existing
# project at that location is overwritten.
#
# The original project was built with Vivado 2018.2. On newer versions the
# Clocking Wizard IP is upgraded automatically (see below).
# -----------------------------------------------------------------------------

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]

set proj_name  "fpga_snake_game"
set proj_dir   [file join $repo_root build $proj_name]
set part       "xc7a35tcpg236-1"
set top        "final1"

# --- Project -----------------------------------------------------------------
create_project $proj_name $proj_dir -part $part -force
set_property target_language Verilog [current_project]

# --- RTL sources ---------------------------------------------------------------
set rtl_files [glob -nocomplain -directory [file join $repo_root rtl] *.v]
if {[llength $rtl_files] == 0} {
    error "No RTL files found in [file join $repo_root rtl]"
}
add_files -norecurse -fileset sources_1 $rtl_files

# --- Clocking Wizard IP (100 MHz in -> 40 MHz VGA pixel clock) ------------------
# import_ip copies the .xci into the project directory, so the repository copy
# is never modified by IP generation or upgrade.
import_ip -files [file join $repo_root ip clk_wiz_0.xci]
set ip [get_ips clk_wiz_0]
if {[get_property IS_LOCKED $ip]} {
    puts "INFO: clk_wiz_0 is locked (created in a different Vivado version); upgrading."
    upgrade_ip $ip
}
generate_target all $ip

# --- Constraints ----------------------------------------------------------------
add_files -norecurse -fileset constrs_1 [file join $repo_root constraints basys3.xdc]

# --- Top level ------------------------------------------------------------------
set_property top $top [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "INFO: Project created at $proj_dir"

# --- Optional build ---------------------------------------------------------------
if {[info exists argv] && [lsearch -exact $argv "build"] >= 0} {
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
        error "Synthesis failed"
    }

    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
        error "Implementation failed"
    }

    puts "INFO: Bitstream: [file join $proj_dir ${proj_name}.runs impl_1 ${top}.bit]"
}
