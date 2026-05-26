catch {vdel -all}

vlib work

vlog -source -lint EqualityX_buggy.sv
vlog -source -lint EqualityX_fixed.sv
vlog -source -lint EqualityX_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+EqualityX_buggy(rtl).+EqualityX_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save EqualityX.ucdb
vcover report EqualityX.ucdb -details -cvg
