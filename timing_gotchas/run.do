catch {vdel -all}

vlib work

vlog -source -lint timing_gotchas_tb.sv

vopt top -o top_optimized +acc

vsim top_optimized
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
run -all
