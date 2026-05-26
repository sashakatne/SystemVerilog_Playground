catch {vdel -all}

vlib work

vlog -source -lint ShortCircuitSideEffect_buggy.sv
vlog -source -lint ShortCircuitSideEffect_fixed.sv
vlog -source -lint ShortCircuitSideEffect_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+ShortCircuitSideEffect_buggy(rtl).+ShortCircuitSideEffect_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save ShortCircuitSideEffect.ucdb
vcover report ShortCircuitSideEffect.ucdb -details -cvg
