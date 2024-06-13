vdel -all

vlib work

# Moore FSM FFO32
vlog -source -lint FFO32.sv
vlog -source -lint FFO32s.sv
vlog -source -lint FFO32stb.sv

vopt top -o top_optimized +acc +cover=sbfec+FFO32s(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save FFO32s.ucdb
vcover report FFO32s.ucdb
vcover report FFO32s.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
