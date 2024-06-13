module top;

    localparam N = 32;
    localparam DELAY = $clog2(N);
    reg [N-1:0] b;
    bit [N-1:0] b_queue[$:DELAY];
    wire v, ve;
    wire [$clog2(N)-1:0] p, pe;
    bit ve_queue[$:DELAY];
    bit [$clog2(N)-1:0] pe_queue[$:DELAY];
    bit Error;
    reg clock = '1;

    // Instantiate the FFO32 and KGD (presumably the same design) modules
    FFO32p DUT (clock, b, v, p);
    FFO32 kgd (b, ve, pe);

    initial begin

        `ifdef DEBUG
            $dumpfile("dump.vcd"); $dumpvars;
            $display("               time         clock reset start ready              b                    p   v");
            $monitor($time,"           %b   %b     %b     %b    %b %b %b",clock, reset, start, ready, b, p, v);
        `endif

        forever #50 clock = ~clock;

    end

    // Shift KGD outputs by $clog2(N) clock cycles using queues
    always @(posedge clock) begin
        // Manage the delay queues
        if (ve_queue.size() == DELAY) begin
            b_queue.delete(0);
            ve_queue.delete(0);
            pe_queue.delete(0);
        end
        b_queue.push_back(b);
        ve_queue.push_back(ve);
        pe_queue.push_back(pe);
    end

    // Check results against delayed KGD outputs
    task CheckResults;
        if (v !== ve_queue[0]) begin
            $display("Error: b = %b, got v = %b, expected ve = %b", b_queue[0], v, ve_queue[0]);
            Error = '1;
        end
        if ((ve_queue[0]) && (p !== pe_queue[0])) begin
            $display("Error: b = %b, got p = %d, expected pe = %d", b_queue[0], p, pe_queue[0]);
            Error = '1;     
        end
    endtask

    // Test sequence
    initial begin
        Error = '0;
        b = 'x; // Initialize b with unknowns
        @(negedge clock); // Wait for the first negedge of clock
        b = b | 1 << (N-1); // Set the MSB of b to 1

        // Apply test vectors and check results
        for (int i = 0; i <= N+DELAY; i++) begin

            `ifdef DEBUG	
                $display("%b %d %b", v, p, b);	
            `endif

            @(negedge clock);
            if (i >= DELAY) CheckResults();
            b = b >> 1;
        end

        // Final report
        if (Error)
            $display("\n\n *** FAILED *** \n\n");
        else
            $display("\n\n *** PASSED *** \n\n");

        $finish;
    end

endmodule


module FFO32(input logic [0:31] b, output logic v, output logic [0:4] p);

    // Intermediate signals for the outputs of the LZD instances
    wire [0:15] v2;
    wire [0:15] p2;
    // Intermediate signals for the outputs of the LZD4 instances
    wire [0:7] v4;
    wire [0:15] p4;
    // Intermediate signals for the outputs of the LZD8 instances
    wire [0:3] v8;
    wire [0:11] p8;
    // Intermediate signals for the outputs of the LZD16 instances
    wire [0:1] v16;
    wire [0:7] p16;
    // Instantiate the 16 LZD2 modules using a for loop
    genvar i;

    generate
        for (i = 0; i < 16; i++) begin : lzd2_gen
            LZD2 lzd2_inst(b[2*i +: 2], v2[i], p2[i]);
        end
    endgenerate
    // Instantiate the 8 LZD4 modules using a for loop
    generate
        for (i = 0; i < 8; i++) begin : lzd4_gen
            LZDn #(4) lzd4_inst(v2[2*i], v2[2*i+1], p2[2*i], p2[2*i+1], v4[i], p4[2*i +: 2]);
        end
    endgenerate
    // Instantiate the 4 LZD8 modules using a for loop
    generate
        for (i = 0; i < 4; i++) begin : lzd8_gen
            LZDn #(8) lzd8_inst(v4[2*i], v4[2*i+1], p4[4*i +: 2], p4[4*i+2 +: 2], v8[i], p8[3*i +: 3]);
        end
    endgenerate
    // Instantiate the 2 LZD16 modules using a for loop
    generate
        for (i = 0; i < 2; i++) begin : lzd16_gen
            LZDn #(16) lzd16_inst(v8[2*i], v8[2*i+1], p8[6*i +: 3], p8[6*i+3 +: 3], v16[i], p16[4*i +: 4]);
        end
    endgenerate

    // Instantiate the single LZD32 module to finalize the FFO32 output
    LZDn #(32) lzd32_inst(v16[0], v16[1], p16[0 +: 4], p16[4 +: 4], v, p);

endmodule
