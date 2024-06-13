vdel -all

vlib work

# Mealy FSM FFO32
vlog -source -lint FFO32.sv
vlog -source -lint FFO32sMealy.sv

vlog -source -lint FFO32sMealytb.sv
# vlog -source -lint +define+DEBUG FFO32sMealytb.sv

vopt top -o top_optimized +acc +cover=sbfec+FFO32sMealy(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save FFO32sMealy.ucdb
vcover report FFO32sMealy.ucdb
vcover report FFO32sMealy.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
