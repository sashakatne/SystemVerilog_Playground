// Testbench for Mealy FSM Implementation of FFO32

module top;

    localparam N = 32;
    reg [0:N-1] b;
    wire v, ve;
    wire [0:$clog2(N)-1] p, pe;
    bit Error;

    reg start, reset;
    reg clock = '1;
    wire ready;


    // wait for ready but timeout if too many clock cycles, then check results/report errors
    task CheckResults;
    begin

    fork
        wait(ready);
        if (ve) repeat(2 * (pe) +3 ) @(negedge clock); else repeat(2 * (32) +3) @(negedge clock);
    join_any

    if (!ready) begin
        $display("Error: timeout while waiting for ready, b = %b",b);
        Error = '1;
    end

    if (v !== ve) begin
        $display("Error: b = %b, got v = %b, expected ve = %b", b, v, ve);
        Error = '1;
    end
    if ((ve) && (p !== pe)) begin
        $display("Error: b = %b, got p = %d, expected pe = %d", b, p, pe);
        Error = '1;		
    end
        
    start = '0;
    end
    endtask

    FFO32sMealy DUT (clock, reset, start, b, v, p, ready);
    FFO32 kgd (b, ve, pe);

    initial
    begin

        `ifdef DEBUG
            $dumpfile("dump.vcd"); $dumpvars;
            $display("               time         clock reset start ready              b                    p   v");
            $monitor($time,"           %b   %b     %b     %b    %b %b %b",clock, reset, start, ready, b, p, v);
        `endif

        forever #50 clock = ~clock;
    end

    initial
    begin
        Error = '0;

        @(negedge clock);
        reset = '1;
        repeat (2) @(negedge clock);
        reset = '0;

        b = 'x;
        b = b | (1 << N-1);
        wait(ready);
        for (int i = 0; i <= N; i++)
            begin
            start = '1;
            
            `ifdef DEBUG	
                $display("%b %d %b",v,p,b);	
            `endif

            @(negedge clock);
            if (ready) begin
                    $display("Error: ready still asserted one cycle after start asserted");
                    Error = '1;
            end
            if ($random() % 2) 		// should work whether we de-assert start or not because FSM shouldn't be looking
                start = '0;	

            CheckResults;	

            @(negedge clock);	
            b = (b >> 1);
            repeat ($random() % 5) @(negedge clock);	// should be able to stay in initial state without start	
            end
            
        if (Error)
            $display("\n\n *** FAILED *** \n\n");
        else
            $display("\n\n *** PASSED *** \n\n");

        $finish();
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

module LZD2(input logic [0:1] b, output logic v, output logic p);

    assign v = b[0] | b[1];
    assign p = ~b[0];
    
endmodule

module LZDn(v0, v1, p0, p1, v, p);

    parameter n = 32;
    input v0, v1;
    input [0:$clog2(n)-2] p0, p1;
    output v;
    output [0:$clog2(n)-1] p;

    assign v = v0 | v1;
    assign p = v0 ? {1'b0, p0} : {1'b1, p1};

endmodule
