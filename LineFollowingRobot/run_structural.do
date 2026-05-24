if {[file isdirectory work]} {
    vdel -all
}

vlib work

vlog -source -lint robotstructural.sv
vlog -source -lint +define+VCD_FILE=\"linefollowing_structural_waveforms.vcd\" testbench.sv

# vlog -source -lint robotdataflow.sv

vopt top -o top_optimized +acc +cover=sbfec+RobotController(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save RobotController_structural.ucdb
vcover report RobotController_structural.ucdb
vcover report RobotController_structural.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
