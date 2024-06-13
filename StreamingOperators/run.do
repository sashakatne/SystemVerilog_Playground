vdel -all

vlib work

# Streaming operations
vlog -source -lint streamingops.sv

vopt top -o top_optimized +acc +cover=sbfec+top(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save streamingops.ucdb
vcover report streamingops.ucdb
vcover report streamingops.ucdb -cvg -details
