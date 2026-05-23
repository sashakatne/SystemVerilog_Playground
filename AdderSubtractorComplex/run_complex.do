catch {vdel -all}

vlib work

# Complex-number package demonstration
vlog -source -lint complexpkg.sv
vlog -source -lint complexm.sv

vopt top -o top_optimized +acc +cover=sbfec+top(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save complexpkg.ucdb
vcover report complexpkg.ucdb
vcover report complexpkg.ucdb -cvg -details
