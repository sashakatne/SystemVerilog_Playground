vdel -all

vlib work

vlog -source -lint cascaded_ece593_alu.sv
vlog -source -lint package.sv
vlog -source -lint interface.sv
vlog -source -lint cascaded_ece593_alu_tb.sv
vlog -source -lint test.sv

vsim top

vsim -coverage top -voptargs="+cover=bcesfx"
vlog -cover bcst cascaded_ece593_alu.sv
vsim -coverage top -do "run -all; exit"

run -all

coverage report -code bcesft
coverage report -assert -binrhs -details -cvg
vcover report -html coverage_results
coverage report -codeAll
