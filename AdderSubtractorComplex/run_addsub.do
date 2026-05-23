catch {vdel -all}

vlib work

# Structural adder/subtractor and procedural reference testbench
vlog -source -lint fulladder.sv
vlog -source -lint addsub.sv
vlog -source -lint addsubtb.sv

vopt top -o top_optimized +acc +cover=sbfec+AddSub8Bit(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save AddSub8Bit.ucdb
vcover report AddSub8Bit.ucdb
vcover report AddSub8Bit.ucdb -cvg -details
