vdel -all

vlib work

# Sequential Parity Generator
vlog -source -lint seqparitygen.sv
vlog -source -lint seqparitygentb.sv

vopt top -o top_optimized +acc +cover=sbfec+paritygen(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save paritygen.ucdb
vcover report paritygen.ucdb
vcover report paritygen.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
