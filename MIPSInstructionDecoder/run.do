catch {vdel -all}

vlib work

# MIPS instruction packed-union decoder
vlog -source -lint mipspkg.sv
vlog -source -lint mipstest.sv

vopt top -o top_optimized +acc +cover=sbfec+top(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all

coverage save MIPSInstructionDecoder.ucdb
vcover report MIPSInstructionDecoder.ucdb
vcover report MIPSInstructionDecoder.ucdb -cvg -details
