catch {vdel -all}

vlib work

# Note: vlog -lint may emit a "Bit/part-select out of declared range" notice
# on OutOfRangeBitSelect_buggy.sv. Carrying it is the lesson of demo #09:
# `vec[32]` on a `[31:0]` register silently returns X without `-lint`.
vlog -source -lint OutOfRangeBitSelect_buggy.sv
vlog -source -lint OutOfRangeBitSelect_fixed.sv
vlog -source -lint OutOfRangeBitSelect_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+OutOfRangeBitSelect_buggy(rtl).+OutOfRangeBitSelect_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save OutOfRangeBitSelect.ucdb
vcover report OutOfRangeBitSelect.ucdb -details -cvg
