if {[file isdirectory work]} {
    vdel -all
}

vlib work

if {![info exists TESTS_PER_MODE]} {
    quietly set TESTS_PER_MODE 1000
}

vlog -source -lint floatingpointpkg.sv fpclass.sv testbench.sv

vopt top -o top_optimized +acc +cover=sbfec -GTESTS_PER_MODE=$TESTS_PER_MODE

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save FloatingPointClassRandomization.ucdb
vcover report FloatingPointClassRandomization.ucdb
vcover report FloatingPointClassRandomization.ucdb -cvg -details
