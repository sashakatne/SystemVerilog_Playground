catch {vdel -all}

vlib work

vlog -source -lint barrelshifter.sv
vlog -source -lint testbench.sv

vopt top -o top_optimized +acc +cover=sbfec+BarrelShifter(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save BarrelShifter.ucdb
vcover report BarrelShifter.ucdb
vcover report BarrelShifter.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
