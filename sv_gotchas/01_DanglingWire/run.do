catch {vdel -all}

vlib work

# expected: vlog -lint on DanglingWire_buggy.sv will warn about the implicit
# net `BC`. Carrying this warning is the entire point of demo #01 -- it shows
# that `vlog -lint` is the tool that catches the gotcha at compile time.
vlog -source -lint DanglingWire_buggy.sv
vlog -source -lint DanglingWire_fixed.sv
vlog -source -lint DanglingWire_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+DanglingWire_buggy(rtl).+DanglingWire_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save DanglingWire.ucdb
vcover report DanglingWire.ucdb -details -cvg
