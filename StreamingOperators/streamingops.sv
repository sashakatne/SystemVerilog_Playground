
module top;

    typedef union packed {
        bit [511:0] quadquadword;
        bit [3:0][127:0] doublequadword;
        bit [7:0][63:0] quadword;
        bit [15:0][31:0] doubleword;
        bit [31:0][15:0] word;
        bit [63:0][7:0] byte8;
        bit [7:0][63:0] double;
        bit [15:0][31:0] float;
    } AV512;

    int R; // 32-bit register
    AV512 SIMD; // 512-bit SIMD register
    int pass = 1; // Variable to keep track of pass/fail status
    parameter DELAY = 10;
    int unsigned A = 0; // Memory address
    integer i,j;

    `ifndef PACKED_MEMORY
        // Unpacked memory
        byte M[]; // system memory modeled as dynamic array
        byte M_orig[]; // system memory modeled as dynamic array
        shortint unsigned operands[32], results[32]; // 32 unsigned shortint values Unpacked
        initial begin

            $display("Testing unpacked memory");
            // Initialize memory and operands with known values
            M = {8'h1a,8'h1b,8'h1c,8'h1d,8'h12,8'h23,8'h45,8'h65};
            for (int j = 0; j < 32; j++) begin
                operands[j] = $urandom_range(16'hFFFF, 0); // 16'hFFFF is 65535, and 0 is the minimum value
            end

            // Problem 3: Demonstrate big-endian loading 4 bytes from memory into R
            #DELAY;
            R = {>>8{M[A +: 4]}}; // Big-endian
            $display("Big endian %h",R);
            assert(R == {M[A], M[A+1], M[A+2], M[A+3]})
                else begin
                    $error("Problem 3: Big-endian load into R failed");
                    pass = 0;
                end
            
            // Problem 4: Demonstrate little-endian loading 4 bytes from memory into R
            #DELAY;
            R = {<<8{M[A +: 4]}}; // Little-endian
            $display("Little endian %h",R);
            assert(R == {M[A+3], M[A+2], M[A+1], M[A]})
                else begin
                    $error("Problem 4: Little-endian load into R failed");
                    pass = 0;
                end

            // Problem 5: Load an SIMD register from operands
            $display("Operands %p",operands);
            #DELAY;
            for (int i = 0; i < 32; i++) begin
                SIMD.word[i] = {<<16{operands[i]}}; // Use streaming operator to pack each word individually
            end
            $display("SIMD word after load %h",SIMD.word);
            foreach (operands[i]) begin
                assert(SIMD.word[i] == operands[i])
                    else begin
                        $error("Problem 5: Expected SIMD[%0d] = %0h, but got %0h", i, operands[i], SIMD.word[i]);
                        pass = 0;
                    end
            end

            // Problem 6: Store an SIMD register into results
            #DELAY;
            for (int i = 0; i < 32; i++) begin
                results[i] = {>>16{SIMD.word[i]}}; // Use streaming operator to unpack each word individually
            end
            $display("Results %p",results);
            foreach (results[i]) begin
                assert(results[i] == SIMD.word[i])
                    else begin
                        $error("Problem 6: Expected results[%0d] = %0h, but got %0h", i, SIMD.word[i], results[i]);
                        pass = 0;
                    end
            end

            M='{5{8'h1a,8'h1b,8'h1c,8'h1d,8'h12,8'h13,8'h14,8'h15,8'h16,8'h17,8'h18,8'h19,8'h21,8'h22,8'h23,8'h24,8'h25,8'h26,8'h27,8'h28,8'h29,8'h31,8'h32,8'h33,8'h34,8'h35,8'h36,8'h37,8'h38,8'h39,8'h41,8'h42,8'h43,8'h44,8'h45,8'h46,8'h47,8'h48,8'h49,8'h51,8'h52,8'h53,8'h54,8'h55,8'h56,8'h57,8'h58,8'h59,8'h61,8'h62,8'h63,8'h64,8'h65,8'h66,8'h67,8'h68,8'h69,8'h71,8'h72,8'h73,8'h74,8'h75,8'h76,8'h77}};

            M_orig = M;

            // Problem 7: Load an SIMD register with 32 unsigned shortint values from memory
            for (int i = 0; i < 32; i++) begin
                SIMD.word[i] = {M[A + 2*i + 1], M[A + 2*i]}; // Combine two adjacent memory bytes into one word
            end
            $display("SIMD word %h",SIMD.word);
            #DELAY;
            // Automated checking of SIMD register after loading from memory
            for (int i = 0; i < 32; i++) begin
                if (SIMD.word[i] !== {M[A + 2*i + 1], M[A + 2*i]}) begin
                    $display("Problem 7: Error loading SIMD register at index %0d: expected %0h, got %0h", i, {M[A + 2*i + 1], M[A + 2*i]}, SIMD.word[i]);
                    pass = 0;
                end
            end

            // Problem 8: Store an SIMD register into memory as 32 unsigned shortint values
            for (int i = 0; i < 32; i++) begin
                {M[A + 2*i + 1], M[A + 2*i]} = SIMD.word[i]; // Store each word back into memory
            end
            $display("Memory %p",M);
            #DELAY;
            // Automated checking of memory after storing SIMD register using M_orig
            for (int i = 0; i < 32; i++) begin
                if (M[A + 2*i + 1] !== M_orig[A + 2*i + 1] || M[A + 2*i] !== M_orig[A + 2*i]) begin
                    $display("Problem 8: Error storing SIMD register at index %0d: expected %0h, got %0h", i, {M_orig[A + 2*i + 1], M_orig[A + 2*i]}, {M[A + 2*i + 1], M[A + 2*i]});
                    pass = 0;
                end
            end

            #DELAY;
            // Final pass/fail statement
            if (pass) begin
                $display("All tests PASSED.");
            end else begin
                $display("Some tests FAILED.");
            end

        end

    `else
        // Packed memory
        parameter N = 64;
        bit [0:N-1][7:0] M; // system memory modeled as packed array

        initial begin

            $display("Testing packed memory");
            #DELAY;
            // Initialize memory with known values
            M = '{16{8'h1a,8'h1b,8'h1c,8'h1d}};

            // Problem 9: Demonstrate big-endian loading 4 bytes from memory into R
            R = {>>8{M[0:3]}}; // Stream the first four bytes into R2 in big-endian order
            $display("Big endian %h",R);
            #DELAY;
            assert(R == {M[0], M[1], M[2], M[3]})
                else begin
                    $error("Problem 9: Big-endian load into R failed");
                    pass = 0;
                end

            // Problem 10: Demonstrate little-endian loading 4 bytes from memory into R2
            R = {<<8{M[0:3]}}; // Stream the first four bytes into R2 in little-endian order
            $display("Little endian %h",R);
            #DELAY;
            assert(R == {M[3], M[2], M[1], M[0]})
                else begin
                    $error("Problem 10: Little-endian load into R failed");
                    pass = 0;
                end

            #DELAY;
            M='{8'h1a,8'h1b,8'h1c,8'h1d,8'h12,8'h13,8'h14,8'h15,8'h16,8'h17,8'h18,8'h19,8'h21,8'h22,8'h23,8'h24,8'h25,8'h26,8'h27,8'h28,8'h29,8'h31,8'h32,8'h33,8'h34,8'h35,8'h36,8'h37,8'h38,8'h39,8'h41,8'h42,8'h43,8'h44,8'h45,8'h46,8'h47,8'h48,8'h49,8'h51,8'h52,8'h53,8'h54,8'h55,8'h56,8'h57,8'h58,8'h59,8'h61,8'h62,8'h63,8'h64,8'h65,8'h66,8'h67,8'h68,8'h69,8'h71,8'h72,8'h73,8'h74,8'h75,8'h76,8'h77};
            $display("Full Memory %p",M);
            $display("First Memory element %p",M[0]);
            $display("Last Memory element %p",M[N-1]);
            #DELAY;
            // Problem 11: Load the SIMD register with 32 consecutive shortints from memory (big-endian) using streaming operators
            SIMD.word = {>>{M[A +: N]}}; // Use streaming with indexed part select for big-endian order
            #DELAY;
            $display("SIMD word Big-Endian %h",SIMD.word);
            // Automated checking of SIMD register after loading from memory
            for (int i = 0; i < 32; i++) begin
                if (SIMD.word[31-i] !== {M[A + 2*i], M[A + 2*i + 1]}) begin
                    $display("Problem 11: Error loading SIMD register at index %0d: expected %0h, got %0h", i, {M[A + 2*i], M[A + 2*i] + 1}, SIMD.word[31-i]);
                    pass = 0;
                end
            end
            #DELAY;

            // Problem 12: Load the SIMD register with 32 consecutive shortints from memory (little-endian) using streaming operators
            for (int i = 0; i < 32; i++) begin
                SIMD.word[i] = {<<8{M[A + 2*i +: 2]}}; // Use streaming with indexed part select for little-endian order
            end
            #DELAY;
            $display("SIMD word Little-Endian %h",SIMD.word);
            // Automated checking of SIMD register after loading from memory
            for (int i = 0; i < 32; i++) begin
                if (SIMD.word[i] !== {M[A + 2*i + 1], M[A + 2*i]}) begin
                    $display("Problem 12: Error loading SIMD register at index %0d: expected %0h, got %0h", i, {M[A + 2*i + 1], M[A + 2*i]}, SIMD.word[i]);
                    pass = 0;
                end
            end

            #DELAY;
            // Final pass/fail statement
            if (pass) begin
                $display("All tests PASSED.");
            end else begin
                $display("Some tests FAILED.");
            end

        end

    `endif

endmodule
