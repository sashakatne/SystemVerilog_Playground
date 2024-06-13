module top;
    import   cascaded_alu_pkg::*;
    import   uvm_pkg::*;
    cascaded_alu_bfm     bfm();
   
    // Instantiate the ALU
    cascaded_ece593_alu #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESULT_WIDTH(RESULT_WIDTH)
    ) DUT (
        .clk(bfm.clk),
        .rst(bfm.rst),
        .start_op(bfm.start_op),
        .op_sel(bfm.op_sel),
        .A1(bfm.A),
        .B1(bfm.B),
        .result(bfm.result),
        .end_op(bfm.end_op)
    );

    initial begin
        // Type, Caller, Path, Name, Value
        uvm_config_db #(virtual cascaded_alu_bfm)::set(null, "*", "bfm", bfm);
        uvm_top.finish_on_completion = 1; // Calls $finish(1) when all tests are done
        run_test("cascaded_alu_test");
    end

endmodule : top
