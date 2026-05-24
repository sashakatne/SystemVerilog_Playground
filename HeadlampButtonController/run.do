if {[file isdirectory work]} {
    vdel -all
}

vlib work

if {![info exists HOLDTICKS]} {
    quietly set HOLDTICKS 1000
}

if {![info exists RECALLTICKS]} {
    quietly set RECALLTICKS 8000
}

if {![info exists DESIGN_HOLDTICKS]} {
    quietly set DESIGN_HOLDTICKS $HOLDTICKS
}

if {![info exists DESIGN_RECALLTICKS]} {
    quietly set DESIGN_RECALLTICKS $RECALLTICKS
}

if {![info exists ASSERT_HOLDTICKS]} {
    quietly set ASSERT_HOLDTICKS $HOLDTICKS
}

if {![info exists ASSERT_RECALLTICKS]} {
    quietly set ASSERT_RECALLTICKS $RECALLTICKS
}

if {![info exists EXPECT_ASSERTION_FAILURE]} {
    quietly set EXPECT_ASSERTION_FAILURE 0
}

vlog -source -lint \
    +define+ASSERT_HOLDTICKS_VALUE=$ASSERT_HOLDTICKS \
    +define+ASSERT_RECALLTICKS_VALUE=$ASSERT_RECALLTICKS \
    +define+EXPECT_ASSERTION_FAILURE_VALUE=$EXPECT_ASSERTION_FAILURE \
    buttons.sv assertions.sv testbench.sv

vopt top -o top_optimized +acc +cover=sbfec \
    -GHOLDTICKS=$HOLDTICKS \
    -GRECALLTICKS=$RECALLTICKS \
    -GDESIGN_HOLDTICKS=$DESIGN_HOLDTICKS \
    -GDESIGN_RECALLTICKS=$DESIGN_RECALLTICKS

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save HeadlampButtonController.ucdb
vcover report HeadlampButtonController.ucdb
vcover report HeadlampButtonController.ucdb -cvg -details
