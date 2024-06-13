vdel -all

vlib work

vlog -source -lint cascaded_ece593_alu.sv
vlog -source -lint cascaded_ece593_alu_tb.sv

# vlog -source -lint cascaded_ece593_alu_selfchecking_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+cascaded_ece593_alu(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save cascaded_ece593_alu.ucdb
vcover report cascaded_ece593_alu.ucdb
vcover report cascaded_ece593_alu.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
