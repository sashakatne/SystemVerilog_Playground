vdel -all

vlib work

# Train Controller
vlog -source -lint traincontrol_fsm.v
vlog -source -lint traincontrol_fsmTB.v

vopt top -o top_optimized +acc +cover=sbfec+traincontroller_fsm(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save traincontroller_fsm.ucdb
vcover report traincontroller_fsm.ucdb
vcover report traincontroller_fsm.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
