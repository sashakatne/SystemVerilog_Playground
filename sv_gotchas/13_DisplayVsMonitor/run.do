catch {vdel -all}

vlib work

vlog -source -lint DisplayVsMonitor_dut.sv
vlog -source -lint DisplayVsMonitor_buggy.sv
vlog -source -lint DisplayVsMonitor_fixed.sv
vlog -source -lint DisplayVsMonitor_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+DisplayVsMonitor_dut(rtl).+DisplayVsMonitor_buggy(rtl).+DisplayVsMonitor_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save DisplayVsMonitor.ucdb
vcover report DisplayVsMonitor.ucdb -details -cvg
