vdel -all

vlib work

# Sequential Multiplier
vlog -source -lint multiplier.sv
vlog -source -lint multtb.sv

# vlog -source -lint +define+DEBUG multtb.sv

vopt top -o top_optimized +acc +cover=sbfec+SequentialMultiplier(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save SequentialMultiplier.ucdb
vcover report SequentialMultiplier.ucdb
vcover report SequentialMultiplier.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
