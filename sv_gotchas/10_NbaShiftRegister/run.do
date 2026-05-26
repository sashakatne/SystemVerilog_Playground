catch {vdel -all}

vlib work

vlog -source -lint NbaShiftRegister_buggy.sv
vlog -source -lint NbaShiftRegister_fixed.sv
vlog -source -lint NbaShiftRegister_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+NbaShiftRegister_buggy(rtl).+NbaShiftRegister_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save NbaShiftRegister.ucdb
vcover report NbaShiftRegister.ucdb -details -cvg
