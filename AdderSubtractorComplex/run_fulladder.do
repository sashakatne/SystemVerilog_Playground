catch {vdel -all}

vlib work

# Full adder structural design
vlog -source -lint fulladder.sv
vlog -source -lint fulladdertb.sv

vopt top -o top_optimized +acc +cover=sbfec+FullAdder(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save FullAdder.ucdb
vcover report FullAdder.ucdb
vcover report FullAdder.ucdb -cvg -details
