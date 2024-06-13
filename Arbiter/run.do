vdel -all

vlib work

vlog -source -lint ArbiterCell.sv
vlog -source -lint ArbiterNStructural.sv
vlog -source -lint ArbiterNTB.sv

# vlog -source -lint ArbiterCellTB.sv

# vlog -source -lint Arbiter4Behavioral.sv
# vlog -source -lint Arbiter4Structural.sv
# vlog -source -lint Arbiter4TB.sv

vopt top -o top_optimized +acc +cover=sbfec+ArbiterCell(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save ArbiterCell.ucdb
vcover report ArbiterCell.ucdb
vcover report ArbiterCell.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
