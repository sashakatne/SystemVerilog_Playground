// Drives five (a, b) pairs. The buggy averager wraps and produces a value
// roughly half what it should whenever a+b overflows 16 bits.
//
//   a=b=0xFFFF: true avg=0xFFFF, buggy=0x7FFF (lost top bit before shift)
//   a=b=0x8000: true avg=0x8000, buggy=0x0000 (wrap to zero, then shift)
module top;
  reg  [15:0] a, b;
  wire [15:0] avg_buggy, avg_fixed;
  reg  [15:0] avg_expected;
  integer     vec, n_buggy_caught, n_fixed_clean, errors;

  BitLengthCarry_buggy dut_buggy (.a(a), .b(b), .avg(avg_buggy));
  BitLengthCarry_fixed dut_fixed (.a(a), .b(b), .avg(avg_fixed));

  initial begin
    n_buggy_caught = 0;
    n_fixed_clean  = 0;
    errors         = 0;

    $display("vec  a      b      expected  buggy  fixed  verdict");
    for (vec = 0; vec < 5; vec = vec + 1) begin
      case (vec)
        0: begin a = 16'h0000; b = 16'h0000; end
        1: begin a = 16'h0100; b = 16'h0100; end
        2: begin a = 16'h8000; b = 16'h8000; end
        3: begin a = 16'hFFFF; b = 16'hFFFF; end
        4: begin a = 16'hC000; b = 16'hC000; end
      endcase
      avg_expected = ({1'b0, a} + {1'b0, b}) >> 1;   // 17-bit reference
      #1;

      if (avg_buggy !== avg_expected) begin
        n_buggy_caught = n_buggy_caught + 1;
        $display(" %0d   %h   %h   %h      %h   %h   GOTCHA OBSERVED (carry lost)",
                 vec, a, b, avg_expected, avg_buggy, avg_fixed);
      end else begin
        $display(" %0d   %h   %h   %h      %h   %h   (buggy matches)",
                 vec, a, b, avg_expected, avg_buggy, avg_fixed);
      end

      if (avg_fixed !== avg_expected) begin
        errors = errors + 1;
        $display("     *** FIX FAILED on vec=%0d  fixed=%h want=%h",
                 vec, avg_fixed, avg_expected);
      end else begin
        n_fixed_clean = n_fixed_clean + 1;
      end
    end

    if (n_buggy_caught == 0)
      $display("*** Error: gotcha never triggered -- demo is silently passing");
    else if (errors != 0)
      $display("*** Error: %0d fix-version mismatches", errors);
    else
      $display("No errors -- passed testbench  (gotcha caught %0d times, fix clean %0d/%0d)",
               n_buggy_caught, n_fixed_clean, 5);

    $finish;
  end
endmodule
