catch {vdel -all}

vlib work

vlog -source -lint NetDelayStack_buggy.sv
vlog -source -lint NetDelayStack_fixed.sv
vlog -source -lint NetDelayStack_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+NetDelayStack_buggy(rtl).+NetDelayStack_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save NetDelayStack.ucdb
vcover report NetDelayStack.ucdb -details -cvg
