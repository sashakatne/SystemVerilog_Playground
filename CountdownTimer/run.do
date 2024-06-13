vdel -all

vlib work

# Countdown Timer
vlog -source -lint countdowntimer.sv
vlog -source -lint countdowntimertb.sv

vopt top -o top_optimized +acc +cover=sbfec+countdowntimer(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save countdowntimer.ucdb
vcover report countdowntimer.ucdb
vcover report countdowntimer.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
