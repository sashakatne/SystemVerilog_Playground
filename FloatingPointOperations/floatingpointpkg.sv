package floatingpointpkg;

  // Define local parameters for exponent and fraction bits
  localparam int EXPONENT_BITS = 8;
  localparam int FRACTION_BITS = 23;

  // Define the float type using a packed struct
  typedef struct packed {
    bit sign;
    bit [EXPONENT_BITS-1:0] exp;
    bit [FRACTION_BITS-1:0] frac;
  } float;

  // Construct a floating point number from components
  function float fpnumberfromcomponents(input bit sign, input bit [EXPONENT_BITS-1:0] exp, input bit [FRACTION_BITS-1:0] frac);
    begin
      float f;
      f.sign = sign;
      f.exp = exp;
      f.frac = frac;
      return f;
    end
  endfunction

  // Construct floating point number from short real
  function float fpnumberfromshortreal(input shortreal sr);
    begin
      bit [31:0] bits;
      bits = $shortrealtobits(sr);
      return fpnumberfromcomponents(bits[EXPONENT_BITS + FRACTION_BITS], bits[EXPONENT_BITS + FRACTION_BITS - 1: FRACTION_BITS], bits[FRACTION_BITS - 1:0]);
    end
  endfunction

  // Return shortreal representation of floating point number
  function shortreal shortrealfromfpnumber(input float f);
    begin
      bit [31:0] bits;
      bits = {f.sign, f.exp, f.frac};
      return $bitstoshortreal(bits);
    end
  endfunction

  // Check if the float is zero
  function bit iszero(float f);
    begin
      return (f.exp === 0) && (f.frac === 0);
    end
  endfunction

  // Check if the float is denormalized
  function bit isdenorm(float f);
    begin
      return (f.exp === 0) && (f.frac !== 0);
    end
  endfunction

  // Check if the float is NaN
  function bit isnan(float f);
    begin
      return (f.exp === 255) && (f.frac !== 0);
    end
  endfunction

  // Check if the float is infinity
  function bit isinfinity(float f);
    begin
      return (f.exp === 255) && (f.frac === 0);
    end
  endfunction

  // Print a floating point number's components
  function void printfp(float f);
    begin
      $display("Sign: %b, Exponent: %b, Fraction: %b", f.sign, f.exp, f.frac);
    end
  endfunction

  // return the integer part of a float.
  // Return 0x80000000 – the 32-bit twos complement, that is, the largest magnitude negative number if the integer is too big to be represented in a signed 32-bit integer
  function int fptoint(float f);
      int exponent_val;
      int integer_part;
      int error_code;
      error_code = 32'h80000000; // Error code for out-of-range values

      // Check for NaN, infinity, or exponent indicating the number is too large
      if (isnan(f) || isinfinity(f) || f.exp > 158) return error_code;

      exponent_val = f.exp - 127;

      // If the exponent is negative, the number is less than 1, integer part is 0
      if (exponent_val < 0) return 0;

      integer_part = (1'b1 << FRACTION_BITS) | f.frac;

      // Shift the significand to get the integer part
      integer_part = (exponent_val >= FRACTION_BITS) ? 
                    (integer_part << (exponent_val - FRACTION_BITS)) : 
                    (integer_part >> (FRACTION_BITS - exponent_val));

      // Apply the sign and check for overflow in one step
      if ((f.sign && (integer_part <= 0)) || (!f.sign && (integer_part < 0))) return error_code;

      return f.sign ? -integer_part : integer_part;
  endfunction

endpackage: floatingpointpkg
