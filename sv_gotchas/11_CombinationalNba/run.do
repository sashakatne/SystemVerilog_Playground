catch {vdel -all}

vlib work

vlog -source -lint CombinationalNba_buggy.sv
vlog -source -lint CombinationalNba_fixed.sv
vlog -source -lint CombinationalNba_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+CombinationalNba_buggy(rtl).+CombinationalNba_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save CombinationalNba.ucdb
vcover report CombinationalNba.ucdb -details -cvg
