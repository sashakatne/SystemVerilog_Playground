module top;

    // Testbench signals
    localparam N = 32;
    reg clock, reset, start;
    reg [0:N-1] b;
    wire v, ve;
    wire [0:$clog2(N)-1] p, pe;
    wire ready;
    integer i;
    bit error_flag = 1'b0;

    parameter CLOCK_CYCLE = 20; // Clock cycle
    localparam CLOCK_WIDTH = CLOCK_CYCLE / 2; // Clock width
    parameter IDLE_CLOCKS = 2;

    // Instantiate the Unit Under Test (UUT)
    FFO32s DUT (clock, reset, start, b, v, p, ready);
    // Instantiate the KGD module
    FFO32 kgd (b, ve, pe);

    // Clock generation
    initial begin
        clock = 1'b0;
        forever #CLOCK_CYCLE clock = ~clock;
    end

    // Generate Reset signal for 2 clock cycles
    initial begin
        reset = 1'b1;
        repeat(IDLE_CLOCKS) @(negedge clock);
        reset = 1'b0;
    end

    // Stimulus generation loop
    initial begin

        repeat(IDLE_CLOCKS) @(negedge clock);
        error_flag = 1'b0;
        start = 1'b0;
        repeat(IDLE_CLOCKS) @(negedge clock);

        b = 'x;
        b = b | (1 << N-1);
        for (i = 0; i <= N; i++) begin
            start = 1'b1;
            repeat(IDLE_CLOCKS) @(negedge clock);
            start = 1'b0;
            wait (ready);
            repeat(IDLE_CLOCKS) @(negedge clock);
            b = (b >> 1);
        end
    end

    // FSM checking statements based on the KGD module
    always @(posedge ready) begin
        if (v !== ve) begin
            $display("*** Error at time %t: v = %b, ve = %b", $time, v, ve);
            error_flag = 1'b1;
        end
        if ((ve) && (p !== pe)) begin
            $display("*** Error at time %t: p = %d, pe = %d", $time, p, pe);
            error_flag = 1'b1;
        end
    end

    // Report test result
    initial begin
        // Wait for all stimulus to be processed
        wait (i > N);
        if (error_flag)
            $display("\n\n *** FAILED *** \n\n");
        else
            $display("\n\n *** PASSED *** \n\n");
        
        $finish;
    end

endmodule

