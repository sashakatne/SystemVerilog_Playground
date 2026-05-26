catch {vdel -all}

vlib work

vlog -source -lint ConditionalX_buggy.sv
vlog -source -lint ConditionalX_fixed.sv
vlog -source -lint ConditionalX_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+ConditionalX_buggy(rtl).+ConditionalX_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save ConditionalX.ucdb
vcover report ConditionalX.ucdb -details -cvg
