catch {vdel -all}

vlib work

vlog -source -lint CaseUnsizedLiteral_buggy.sv
vlog -source -lint CaseUnsizedLiteral_fixed.sv
vlog -source -lint CaseUnsizedLiteral_tb.sv

vopt top -o top_optimized +acc +cover=sbfec+CaseUnsizedLiteral_buggy(rtl).+CaseUnsizedLiteral_fixed(rtl).

vsim top_optimized -coverage
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save CaseUnsizedLiteral.ucdb
vcover report CaseUnsizedLiteral.ucdb -details -cvg
