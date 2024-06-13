package floatingpointpkg;
  localparam INT_BITS = 32;
  localparam EXPONENT_BITS = 8;  // number of exponent bits
  localparam FRACTION_BITS = 23; // number of significand bits
  localparam BIAS = 2**(EXPONENT_BITS-1) - 1; // exponent bias
  class float;

    typedef struct packed {
        bit sign;                          // sign
        bit [EXPONENT_BITS-1:0] exponent;  // exponent
        bit [FRACTION_BITS-1:0] fraction;  // significand
    } float_s;

    rand float_s fbits;
    // Attributes (variables) for exprange_c constraint
    int minexp;
    int maxexp;

    // Method to set the range for the exprange_c constraint
    function void set_exprange(int min_exp, int max_exp);
      minexp = min_exp;
      maxexp = max_exp;
    endfunction

    // Function to check if the number is zero
    function bit iszero();
      return((fbits.exponent === '0) && (fbits.fraction === '0));
    endfunction: iszero

    // Function to check if the number is denormalized
    function bit isdenorm();
      return((fbits.exponent === '0) && (fbits.fraction !== '0));
    endfunction: isdenorm

    // Function to check if the number is NaN
    function bit isnan();
      return((fbits.exponent === '1) && fbits.fraction !== '0);
    endfunction: isnan

    // Function to check if the number is infinity
    function bit isinfinity();
      return((fbits.exponent === '1) && (fbits.fraction === '0));
    endfunction: isinfinity

    // Function to check if exponent is in range
    function bit expinrange();
      return(fbits.exponent inside {[minexp+BIAS : maxexp+BIAS]});
    endfunction: expinrange

    // Conversion function
    function int fptoint();
      int i;
      int e;
      if (iszero() || isdenorm())
        return(0);
      e = fbits.exponent - BIAS;
      if (e < 0)
        return(0);
      if (e > 30)
        return(32'h80000000);
      
      i = {1'b1, fbits.fraction, {(INT_BITS-2-FRACTION_BITS){1'b0}}} >> (INT_BITS-2-e);
      return(fbits.sign ? -i : i);
    endfunction

    // Constraints
    constraint nodenorm_c {!((fbits.exponent == '0) && (fbits.fraction != '0));}
    constraint alldenorm_c {((fbits.exponent == '0) && (fbits.fraction != '0));}
    constraint nonan_c {!((fbits.exponent == '1) && (fbits.fraction != '0));}
    constraint noinf_c {!((fbits.exponent == '1) && (fbits.fraction == '0));}
    constraint exprange_c {fbits.exponent inside {[minexp+BIAS : maxexp+BIAS]};}

  endclass

endpackage
