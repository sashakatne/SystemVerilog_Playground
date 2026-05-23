if {[file isdirectory work]} {
    vdel -all
}

vlib work

if {![info exists NUMMEM]} {
    quietly set NUMMEM 4
}

vlog -source -lint simplebusif.sv

vopt top -o top_optimized +acc +cover=sbfec -GNUMMEM=$NUMMEM

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save SimpleBusMultiMemory.ucdb
vcover report SimpleBusMultiMemory.ucdb
vcover report SimpleBusMultiMemory.ucdb -cvg -details
