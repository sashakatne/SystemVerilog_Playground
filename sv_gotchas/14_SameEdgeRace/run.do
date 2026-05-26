catch {vdel -all}

vlib work

vlog -source -lint SameEdgeRace_dut.sv
vlog -source -lint SameEdgeRace_buggy.sv
vlog -source -lint SameEdgeRace_fixed.sv
vlog -source -lint SameEdgeRace_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+SameEdgeRace_dut(rtl).+SameEdgeRace_buggy(rtl).+SameEdgeRace_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save SameEdgeRace.ucdb
vcover report SameEdgeRace.ucdb -details -cvg
