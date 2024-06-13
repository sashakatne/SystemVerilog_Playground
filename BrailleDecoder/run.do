vdel -all

vlib work

vlog -source -lint BrailleDataflow.v
vlog -source -lint BrailleTestbench.v

# vlog source -lint BrailleStructural.v

vopt top -o top_optimized +acc +cover=sbfec+BrailleDigits(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save BrailleDigits.ucdb
vcover report BrailleDigits.ucdb
vcover report BrailleDigits.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
