catch {vdel -all}

vlib work

vlog -source -lint VerifierSensitivityMiss_dut.sv
vlog -source -lint VerifierSensitivityMiss_buggy.sv
vlog -source -lint VerifierSensitivityMiss_fixed.sv
vlog -source -lint VerifierSensitivityMiss_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+VerifierSensitivityMiss_dut(rtl).+VerifierSensitivityMiss_buggy(rtl).+VerifierSensitivityMiss_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save VerifierSensitivityMiss.ucdb
vcover report VerifierSensitivityMiss.ucdb -details -cvg
