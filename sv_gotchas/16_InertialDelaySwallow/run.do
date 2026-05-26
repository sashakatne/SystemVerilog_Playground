catch {vdel -all}

vlib work

vlog -source -lint InertialDelaySwallow_buggy.sv
vlog -source -lint InertialDelaySwallow_fixed.sv
vlog -source -lint InertialDelaySwallow_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+InertialDelaySwallow_buggy(rtl).+InertialDelaySwallow_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save InertialDelaySwallow.ucdb
vcover report InertialDelaySwallow.ucdb -details -cvg
