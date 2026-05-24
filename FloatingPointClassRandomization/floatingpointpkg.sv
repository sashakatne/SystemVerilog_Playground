package floatingpointpkg;

    localparam int EXPONENT_BITS = 8;
    localparam int FRACTION_BITS = 23;
    localparam int FLOAT_BITS = 1 + EXPONENT_BITS + FRACTION_BITS;
    localparam int BIAS = (1 << (EXPONENT_BITS - 1)) - 1;

    typedef struct packed {
        bit sign;
        bit [EXPONENT_BITS-1:0] exp;
        bit [FRACTION_BITS-1:0] frac;
    } float;

    function automatic float fpnumberfromcomponents(
        input bit sign,
        input bit [EXPONENT_BITS-1:0] exp,
        input bit [FRACTION_BITS-1:0] frac
    );
        float value;

        value.sign = sign;
        value.exp = exp;
        value.frac = frac;
        return value;
    endfunction

    function automatic float fpnumberfromshortreal(input shortreal value);
        bit [FLOAT_BITS-1:0] bits;

        bits = $shortrealtobits(value);
        return fpnumberfromcomponents(
            bits[FLOAT_BITS-1],
            bits[FRACTION_BITS +: EXPONENT_BITS],
            bits[FRACTION_BITS-1:0]
        );
    endfunction

    function automatic shortreal shortrealfromfpnumber(input float value);
        bit [FLOAT_BITS-1:0] bits;

        bits = {value.sign, value.exp, value.frac};
        return $bitstoshortreal(bits);
    endfunction

    function automatic bit iszero(input float value);
        return (value.exp == '0) && (value.frac == '0);
    endfunction

    function automatic bit isdenorm(input float value);
        return (value.exp == '0) && (value.frac != '0);
    endfunction

    function automatic bit isnan(input float value);
        return (value.exp == '1) && (value.frac != '0);
    endfunction

    function automatic bit isinfinity(input float value);
        return (value.exp == '1) && (value.frac == '0);
    endfunction

endpackage
