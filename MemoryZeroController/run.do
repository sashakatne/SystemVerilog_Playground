if {[file isdirectory work]} {
    vdel -all
}

vlib work

# Memory Zero Controller
vlog -source -lint memoryzero.sv
vlog -source -lint fsmtb.sv

vopt top -o top_optimized +acc +cover=sbfec+mz(rtl).

vsim top_optimized -coverage

set NoQuitOnFinish 1
onbreak {resume}
log /* -r
vcd file memoryzero_waveforms.vcd
vcd add /top/clock /top/reset /top/ld_high /top/ld_low /top/addr /top/din /top/write /top/zero /top/dout /top/busy
vcd add /top/DUT/set_busy /top/DUT/clr_busy /top/DUT/ld_cnt /top/DUT/cnt_en /top/DUT/addr_sel /top/DUT/zero_we /top/DUT/cnt_eq
vcd add /top/DUT/FSM/State /top/DUT/FSM/NextState
vcd add /top/DUT/DP/dina /top/DUT/DP/dcnt /top/DUT/DP/dinb /top/DUT/DP/addrm /top/DUT/DP/dinm /top/DUT/DP/mem_we
run -all

coverage save mz.ucdb
vcover report mz.ucdb
vcover report mz.ucdb -cvg -details

add wave -position insertpoint sim:/top/DUT/*
