`timescale 1ns/1ps

module top;

    import floatingpointpkg::*;
    import fpclasspkg::*;

    parameter int unsigned TESTS_PER_MODE = 1000;

    localparam int unsigned MODE_DIRECT    = 0;
    localparam int unsigned MODE_NODENORM  = 1;
    localparam int unsigned MODE_ALLDENORM = 2;
    localparam int unsigned MODE_NONAN     = 3;
    localparam int unsigned MODE_NOINF     = 4;
    localparam int unsigned MODE_EXPRANGE  = 5;
    localparam int unsigned MODE_COMBINED  = 6;

    logic Clock;
    logic [2:0] Mode;
    logic RandomizeOK;
    logic SignSample;
    logic [EXPONENT_BITS-1:0] ExponentSample;
    logic [FRACTION_BITS-1:0] FractionSample;
    logic [FLOAT_BITS-1:0] PackedSample;
    logic DenormSample;
    logic NanSample;
    logic InfSample;
    logic RangeSample;
    logic ErrorSeen;
    int unsigned SampleCount;

    int unsigned checks;
    int unsigned errors;

    FpNumber number;

    covergroup fpclass_cg @(posedge Clock);
        option.per_instance = 1;

        mode_cp: coverpoint Mode {
            bins direct    = {MODE_DIRECT};
            bins nodenorm  = {MODE_NODENORM};
            bins alldenorm = {MODE_ALLDENORM};
            bins nonan     = {MODE_NONAN};
            bins noinf     = {MODE_NOINF};
            bins exprange  = {MODE_EXPRANGE};
            bins combined  = {MODE_COMBINED};
        }

        exponent_cp: coverpoint ExponentSample {
            bins zero    = {8'h00};
            bins normal  = {[8'h01:8'hFE]};
            bins special = {8'hFF};
        }

        denorm_cp: coverpoint DenormSample;
        nan_cp: coverpoint NanSample;
        inf_cp: coverpoint InfSample;
        range_cp: coverpoint RangeSample {
            bins in_range = {1'b1};
        }

        randomize_cp: coverpoint RandomizeOK {
            bins succeeded = {1'b1};
        }
    endgroup

    fpclass_cg Coverage;

    initial begin
        $dumpfile("fpclass_waveforms.vcd");
        $dumpvars(0);
    end

    task automatic record_pass(input string label);
        $display("PASS: %s", label);
    endtask

    task automatic record_fail(input string label);
        errors++;
        ErrorSeen = 1'b1;
        $display("FAIL: %s", label);
    endtask

    function automatic bit same_bits(
        input floatingpointpkg::float actual,
        input bit expected_sign,
        input bit [EXPONENT_BITS-1:0] expected_exponent,
        input bit [FRACTION_BITS-1:0] expected_fraction
    );
        return (actual.sign == expected_sign) &&
               (actual.exp == expected_exponent) &&
               (actual.frac == expected_fraction);
    endfunction

    task automatic sample_number(input int unsigned mode_value, input bit randomize_ok);
        floatingpointpkg::float value;

        value = number.to_float();
        Mode = mode_value[2:0];
        RandomizeOK = randomize_ok;
        SignSample = number.sign;
        ExponentSample = number.exponent;
        FractionSample = number.fraction;
        PackedSample = {value.sign, value.exp, value.frac};
        DenormSample = number.isdenorm();
        NanSample = number.isnan();
        InfSample = number.isinfinity();
        RangeSample = number.expinrange();
        SampleCount++;

        #1 Clock = 1'b1;
        #1 Clock = 1'b0;
    endtask

    task automatic disable_all_constraints();
        number.constraint_mode(0);
    endtask

    task automatic run_direct_build_check();
        floatingpointpkg::float value;
        floatingpointpkg::float expected;

        disable_all_constraints();
        number.set_components(1'b0, 8'd128, 23'h400000);
        value = number.to_float();
        expected = fpnumberfromcomponents(1'b0, 8'd128, 23'h400000);
        sample_number(MODE_DIRECT, 1'b1);

        checks++;
        if ((value === expected) && same_bits(value, 1'b0, 8'd128, 23'h400000)) begin
            record_pass("component attributes build the expected packed float");
        end else begin
            record_fail("component attributes did not build the expected packed float");
        end

        checks++;
        if (!number.iszero() && !number.isdenorm() && !number.isnan() && !number.isinfinity()) begin
            record_pass("built value is a finite normalized float");
        end else begin
            record_fail("built value classification is incorrect");
        end

        number.set_components(1'b0, '0, 23'h000001);
        sample_number(MODE_DIRECT, 1'b1);
        checks++;
        if (number.isdenorm() && !number.isnan() && !number.isinfinity()) begin
            record_pass("direct denormal probe is classified correctly");
        end else begin
            record_fail("direct denormal probe classification is incorrect");
        end

        number.set_components(1'b0, '1, '0);
        sample_number(MODE_DIRECT, 1'b1);
        checks++;
        if (number.isinfinity() && !number.isnan() && !number.isdenorm()) begin
            record_pass("direct infinity probe is classified correctly");
        end else begin
            record_fail("direct infinity probe classification is incorrect");
        end

        number.set_components(1'b0, '1, 23'h000001);
        sample_number(MODE_DIRECT, 1'b1);
        checks++;
        if (number.isnan() && !number.isinfinity() && !number.isdenorm()) begin
            record_pass("direct NaN probe is classified correctly");
        end else begin
            record_fail("direct NaN probe classification is incorrect");
        end
    endtask

    task automatic configure_mode(input int unsigned mode_value);
        disable_all_constraints();

        unique case (mode_value)
            MODE_NODENORM: begin
                number.nodenorm_c.constraint_mode(1);
            end

            MODE_ALLDENORM: begin
                number.alldenorm_c.constraint_mode(1);
            end

            MODE_NONAN: begin
                number.nonan_c.constraint_mode(1);
            end

            MODE_NOINF: begin
                number.noinf_c.constraint_mode(1);
            end

            MODE_EXPRANGE: begin
                number.set_exprange(-3, 5);
                number.exprange_c.constraint_mode(1);
            end

            MODE_COMBINED: begin
                number.set_exprange(-10, 10);
                number.nodenorm_c.constraint_mode(1);
                number.nonan_c.constraint_mode(1);
                number.noinf_c.constraint_mode(1);
                number.exprange_c.constraint_mode(1);
            end

            default: begin
                disable_all_constraints();
            end
        endcase
    endtask

    function automatic bit mode_predicate(input int unsigned mode_value);
        unique case (mode_value)
            MODE_NODENORM: begin
                return !number.isdenorm();
            end

            MODE_ALLDENORM: begin
                return number.isdenorm();
            end

            MODE_NONAN: begin
                return !number.isnan();
            end

            MODE_NOINF: begin
                return !number.isinfinity();
            end

            MODE_EXPRANGE: begin
                return number.expinrange();
            end

            MODE_COMBINED: begin
                return !number.isdenorm() &&
                       !number.isnan() &&
                       !number.isinfinity() &&
                       number.expinrange();
            end

            default: begin
                return 1'b1;
            end
        endcase
    endfunction

    function automatic string mode_label(input int unsigned mode_value);
        unique case (mode_value)
            MODE_NODENORM:  return "nodenorm_c rejects denormalized values";
            MODE_ALLDENORM: return "alldenorm_c accepts only denormalized values";
            MODE_NONAN:     return "nonan_c rejects NaN values";
            MODE_NOINF:     return "noinf_c rejects infinity values";
            MODE_EXPRANGE:  return "exprange_c limits unbiased exponents";
            MODE_COMBINED:  return "combined constraints produce finite ranged normals";
            default:        return "unconstrained mode";
        endcase
    endfunction

    task automatic run_random_mode(input int unsigned mode_value);
        int unsigned mode_errors;
        bit ok;

        mode_errors = errors;
        configure_mode(mode_value);

        repeat (TESTS_PER_MODE) begin
            ok = number.randomize();
            sample_number(mode_value, ok);
            checks++;

            if (!ok) begin
                record_fail($sformatf("%s: randomize failed", mode_label(mode_value)));
            end else if (!mode_predicate(mode_value)) begin
                record_fail($sformatf(
                    "%s: sign=%0b exponent=0x%02h fraction=0x%06h unbiased_exp=%0d",
                    mode_label(mode_value),
                    number.sign,
                    number.exponent,
                    number.fraction,
                    number.exponent_value()
                ));
            end
        end

        if (errors == mode_errors) begin
            record_pass($sformatf("%s across %0d randomized samples", mode_label(mode_value), TESTS_PER_MODE));
        end
    endtask

    initial begin
        Clock = 1'b0;
        Mode = '0;
        RandomizeOK = 1'b0;
        SignSample = 1'b0;
        ExponentSample = '0;
        FractionSample = '0;
        PackedSample = '0;
        DenormSample = 1'b0;
        NanSample = 1'b0;
        InfSample = 1'b0;
        RangeSample = 1'b0;
        ErrorSeen = 1'b0;
        SampleCount = 0;
        checks = 0;
        errors = 0;

        number = new();
        Coverage = new();

        $display("Starting floating-point class randomization checks: TESTS_PER_MODE=%0d", TESTS_PER_MODE);

        run_direct_build_check();
        run_random_mode(MODE_NODENORM);
        run_random_mode(MODE_ALLDENORM);
        run_random_mode(MODE_NONAN);
        run_random_mode(MODE_NOINF);
        run_random_mode(MODE_EXPRANGE);
        run_random_mode(MODE_COMBINED);

        if (errors == 0) begin
            $display("Completed %0d self-checks with 0 errors", checks);
            $display("No errors -- passed testbench");
        end else begin
            $display("Failed testbench with %0d errors across %0d checks", errors, checks);
            $fatal(1);
        end

        $finish;
    end

endmodule
