vdel -all

vlib work

# Floating point operations
vlog -source -lint floatingpointpkg.sv
vlog -source -lint floatingpoint.sv

vopt top -o top_optimized +acc +cover=sbfec+floatingpointpkg(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save floatingpointpkg.ucdb
vcover report floatingpointpkg.ucdb
vcover report floatingpointpkg.ucdb -cvg -details
