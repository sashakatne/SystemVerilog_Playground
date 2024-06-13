vdel -all

vlib work

vlog -source -lint cascaded_alu.sv
# vlog -source -lint +define+DATA_CORRUPTION_BUG cascaded_alu.sv

vlog -source -lint cascaded_alu_pkg.sv

vlog -source -lint top.sv

vlog -source -lint test.sv
vlog -source -lint driver.sv
vlog -source -lint environment.sv
vlog -source -lint cascaded_alu_bfm.sv
vlog -source -lint agent.sv
vlog -source -lint scoreboard.sv
vlog -source -lint sequence.sv
vlog -source -lint sequencer.sv
vlog -source -lint coverage.sv
vlog -source -lint monitor.sv

vopt top -o top_optimized +acc +cover=sbfec+cascaded_alu(rtl).

vsim top_optimized -coverage
# vsim +define+BASE_TEST top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save cascaded_alu.ucdb
vcover report cascaded_alu.ucdb
vcover report cascaded_alu.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
