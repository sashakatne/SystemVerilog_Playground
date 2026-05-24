package fpclasspkg;

    import floatingpointpkg::*;

    class FpNumber;
        rand bit sign;
        rand bit [EXPONENT_BITS-1:0] exponent;
        rand bit [FRACTION_BITS-1:0] fraction;

        int minexp;
        int maxexp;

        constraint nodenorm_c {
            !((exponent == '0) && (fraction != '0));
        }

        constraint alldenorm_c {
            (exponent == '0) && (fraction != '0);
        }

        constraint nonan_c {
            !((exponent == '1) && (fraction != '0));
        }

        constraint noinf_c {
            !((exponent == '1) && (fraction == '0));
        }

        constraint exprange_c {
            (minexp + BIAS) >= 0;
            (maxexp + BIAS) <= ((1 << EXPONENT_BITS) - 1);
            exponent inside {[(minexp + BIAS):(maxexp + BIAS)]};
        }

        function new();
            minexp = -BIAS;
            maxexp = ((1 << EXPONENT_BITS) - 1) - BIAS;
            constraint_mode(0);
        endfunction

        function void set_components(
            input bit value_sign,
            input bit [EXPONENT_BITS-1:0] value_exponent,
            input bit [FRACTION_BITS-1:0] value_fraction
        );
            sign = value_sign;
            exponent = value_exponent;
            fraction = value_fraction;
        endfunction

        function void set_exprange(input int minimum_exponent, input int maximum_exponent);
            minexp = minimum_exponent;
            maxexp = maximum_exponent;
        endfunction

        function floatingpointpkg::float to_float();
            return fpnumberfromcomponents(sign, exponent, fraction);
        endfunction

        function bit iszero();
            return floatingpointpkg::iszero(to_float());
        endfunction

        function bit isdenorm();
            return floatingpointpkg::isdenorm(to_float());
        endfunction

        function bit isnan();
            return floatingpointpkg::isnan(to_float());
        endfunction

        function bit isinfinity();
            return floatingpointpkg::isinfinity(to_float());
        endfunction

        function int exponent_value();
            return int'(exponent) - BIAS;
        endfunction

        function bit expinrange();
            return (exponent_value() >= minexp) && (exponent_value() <= maxexp);
        endfunction
    endclass

endpackage
