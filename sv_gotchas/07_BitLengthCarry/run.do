catch {vdel -all}

vlib work

vlog -source -lint BitLengthCarry_buggy.sv
vlog -source -lint BitLengthCarry_fixed.sv
vlog -source -lint BitLengthCarry_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+BitLengthCarry_buggy(rtl).+BitLengthCarry_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save BitLengthCarry.ucdb
vcover report BitLengthCarry.ucdb -details -cvg
