module top;

    import complexpkg::*;

    int checks = 0;
    int errors = 0;

    function automatic shortreal abs_shortreal(input shortreal value);
        if (value < 0.0)
            return -value;
        return value;
    endfunction

    function automatic bit close_shortreal(
        input shortreal actual,
        input shortreal expected
    );
        return abs_shortreal(actual - expected) <= 0.0001;
    endfunction

    task automatic check_complex(
        input complex actual,
        input shortreal expected_real,
        input shortreal expected_imaginary,
        input string label
    );
        checks++;
        if (!close_shortreal(actual.real_part, expected_real) ||
            !close_shortreal(actual.imaginary_part, expected_imaginary)) begin
            $display("FAIL [%0d]: %s => (r: %f, i: %f) expected (r: %f, i: %f)",
                     checks, label, actual.real_part, actual.imaginary_part,
                     expected_real, expected_imaginary);
            errors++;
        end else begin
            $display("PASS [%0d]: %s => (r: %f, i: %f)",
                     checks, label, actual.real_part, actual.imaginary_part);
        end
    endtask

    task automatic check_components(
        input complex value,
        input shortreal expected_real,
        input shortreal expected_imaginary,
        input string label
    );
        shortreal real_part;
        shortreal imaginary_part;
        ComplexToComponents(value, real_part, imaginary_part);

        checks++;
        if (!close_shortreal(real_part, expected_real) ||
            !close_shortreal(imaginary_part, expected_imaginary)) begin
            $display("FAIL [%0d]: %s => components r=%f i=%f expected r=%f i=%f",
                     checks, label, real_part, imaginary_part,
                     expected_real, expected_imaginary);
            errors++;
        end else begin
            $display("PASS [%0d]: %s => components r=%f i=%f",
                     checks, label, real_part, imaginary_part);
        end
    endtask

    initial begin
        complex a;
        complex b;
        complex c;
        complex zero;

        a = CreateComplex(1.5, -2.0);
        b = CreateComplex(3.25, 4.0);
        zero = CreateComplex(0.0, 0.0);

        check_complex(a, 1.5, -2.0, "CreateComplex");
        check_components(a, 1.5, -2.0, "ComplexToComponents");

        c = AddComplex(a, b);
        check_complex(c, 4.75, 2.0, "AddComplex");

        c = MultComplex(a, b);
        check_complex(c, 12.875, -0.5, "MultComplex");

        c = AddComplex(a, zero);
        check_complex(c, 1.5, -2.0, "AddComplex identity");

        c = MultComplex(a, zero);
        check_complex(c, 0.0, 0.0, "MultComplex zero");

        $display("PrintComplex demonstration:");
        PrintComplex(b);

        $display("");
        $display("Ran %0d checks, %0d errors", checks, errors);
        if (errors == 0)
            $display("No errors -- passed testbench");
        else
            $display("FAILED -- %0d errors", errors);
        $finish;
    end

endmodule
