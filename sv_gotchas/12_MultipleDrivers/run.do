catch {vdel -all}

vlib work

# Note: vopt may emit a "Variable counter has multiple constant drivers" or
# similar elaboration warning on MultipleDrivers_buggy. Carrying that warning
# is the lesson of demo #12 -- a single reg should only have one writer.
vlog -source -lint MultipleDrivers_buggy.sv
vlog -source -lint MultipleDrivers_fixed.sv
vlog -source -lint MultipleDrivers_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+MultipleDrivers_buggy(rtl).+MultipleDrivers_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save MultipleDrivers.ucdb
vcover report MultipleDrivers.ucdb -details -cvg
