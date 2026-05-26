catch {vdel -all}

vlib work

vlog -source -lint BitwiseVsLogicalNot_buggy.sv
vlog -source -lint BitwiseVsLogicalNot_fixed.sv
vlog -source -lint BitwiseVsLogicalNot_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+BitwiseVsLogicalNot_buggy(rtl).+BitwiseVsLogicalNot_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save BitwiseVsLogicalNot.ucdb
vcover report BitwiseVsLogicalNot.ucdb -details -cvg
