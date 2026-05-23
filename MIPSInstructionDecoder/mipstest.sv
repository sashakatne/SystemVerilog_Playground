module top;

    import mipspkg::*;

    int checks = 0;
    int errors = 0;

    task automatic expect_equal(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string label
    );
        checks++;
        if (actual !== expected) begin
            $display("FAIL [%0d]: %s actual=0x%08h expected=0x%08h",
                     checks, label, actual, expected);
            errors++;
        end else begin
            $display("PASS [%0d]: %s = 0x%08h", checks, label, actual);
        end
    endtask

    task automatic check_r_instruction(
        input logic [31:0] raw,
        input logic [4:0]  expected_rs,
        input logic [4:0]  expected_rt,
        input logic [4:0]  expected_rd,
        input logic [4:0]  expected_shamt,
        input logic [5:0]  expected_funct,
        input string label
    );
        mips_instruction_t instruction;
        instruction = raw;

        expect_equal(instruction.generic.opcode, 6'h00, {label, " opcode"});
        expect_equal(instruction.r.rs, expected_rs, {label, " rs"});
        expect_equal(instruction.r.rt, expected_rt, {label, " rt"});
        expect_equal(instruction.r.rd, expected_rd, {label, " rd"});
        expect_equal(instruction.r.shamt, expected_shamt, {label, " shamt"});
        expect_equal(instruction.r.funct, expected_funct, {label, " funct"});
        DecodeInstruction(instruction);
    endtask

    task automatic check_i_instruction(
        input logic [31:0] raw,
        input logic [5:0]  expected_opcode,
        input logic [4:0]  expected_rs,
        input logic [4:0]  expected_rt,
        input logic [15:0] expected_immediate,
        input string label
    );
        mips_instruction_t instruction;
        instruction = raw;

        expect_equal(instruction.generic.opcode, expected_opcode, {label, " opcode"});
        expect_equal(instruction.i.rs, expected_rs, {label, " rs"});
        expect_equal(instruction.i.rt, expected_rt, {label, " rt"});
        expect_equal(instruction.i.immediate, expected_immediate, {label, " immediate"});
        DecodeInstruction(instruction);
    endtask

    task automatic check_j_instruction(
        input logic [31:0] raw,
        input logic [5:0]  expected_opcode,
        input logic [25:0] expected_address,
        input string label
    );
        mips_instruction_t instruction;
        instruction = raw;

        expect_equal(instruction.generic.opcode, expected_opcode, {label, " opcode"});
        expect_equal(instruction.j.address, expected_address, {label, " address"});
        DecodeInstruction(instruction);
    endtask

    initial begin
        check_r_instruction(
            {6'h00, 5'd9, 5'd10, 5'd8, 5'd0, 6'h20},
            5'd9,
            5'd10,
            5'd8,
            5'd0,
            6'h20,
            "add"
        );

        check_r_instruction(
            {6'h00, 5'd0, 5'd11, 5'd12, 5'd4, 6'h00},
            5'd0,
            5'd11,
            5'd12,
            5'd4,
            6'h00,
            "sll"
        );

        check_i_instruction(
            {6'h08, 5'd9, 5'd8, 16'h0010},
            6'h08,
            5'd9,
            5'd8,
            16'h0010,
            "addi"
        );

        check_i_instruction(
            {6'h23, 5'd29, 5'd16, 16'hfffc},
            6'h23,
            5'd29,
            5'd16,
            16'hfffc,
            "lw"
        );

        check_j_instruction(
            {6'h02, 26'h0001234},
            6'h02,
            26'h0001234,
            "j"
        );

        check_j_instruction(
            {6'h03, 26'h0004321},
            6'h03,
            26'h0004321,
            "jal"
        );

        $display("Ran %0d checks, %0d errors", checks, errors);
        if (errors == 0)
            $display("No errors -- passed testbench");
        else
            $display("FAILED -- %0d errors", errors);
        $finish;
    end

endmodule
