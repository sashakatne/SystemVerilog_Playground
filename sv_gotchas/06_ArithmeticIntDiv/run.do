catch {vdel -all}

vlib work

vlog -source -lint ArithmeticIntDiv_buggy.sv
vlog -source -lint ArithmeticIntDiv_fixed.sv
vlog -source -lint ArithmeticIntDiv_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+ArithmeticIntDiv_buggy(rtl).+ArithmeticIntDiv_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save ArithmeticIntDiv.ucdb
vcover report ArithmeticIntDiv.ucdb -details -cvg
