vdel -all

vlib work

# Non Overlapping Clock Generator
vlog -source -lint novckgen_structural.sv
vlog -source -lint novckgen_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+novckgen(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save novckgen.ucdb
vcover report novckgen.ucdb
vcover report novckgen.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
