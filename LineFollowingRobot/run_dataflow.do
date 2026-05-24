if {[file isdirectory work]} {
    vdel -all
}

vlib work

vlog -source -lint robotdataflow.sv
vlog -source -lint +define+VCD_FILE=\"linefollowing_dataflow_waveforms.vcd\" testbench.sv

# vlog -source -lint robotstructural.sv

vopt top -o top_optimized +acc +cover=sbfec+RobotController(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save RobotController_dataflow.ucdb
vcover report RobotController_dataflow.ucdb
vcover report RobotController_dataflow.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
