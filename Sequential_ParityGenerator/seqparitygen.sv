module paritygen #(parameter N = 8) (
    input clock,
    input reset,
    input start,
    input [N-1:0] b,
    output reg parity,
    output reg ready
);

    // State declaration
    localparam IDLE = 4'b0001,
                LOAD = 4'b0010,
                SHIFT_COUNT = 4'b0100,
                DONE = 4'b1000;

    // Signals for FSM
    reg [3:0] state, next_state;
    reg [N-1:0] SR; // Shift Register
    reg [N-1:0] parity_counter; // Counter for number of ones
    reg [N-1:0] bit_counter; // Counter for bit position
    reg LoadSR, ShiftSR, ClearCount, IncOneCount;

    // Output Logic
    assign parity = (parity_counter % 2 == 0);

    // Shift Register Logic
    always_ff @(posedge clock) begin
        if (LoadSR)
            SR <= b;
        else if (ShiftSR)
            SR <= SR << 1;
    end

    // Parity Counter Logic
    always_ff @(posedge clock) begin
        if (reset || ClearCount)
            parity_counter <= '0;
        else if (IncOneCount)
            parity_counter <= parity_counter + 1'b1;
    end

    // Bit Counter Logic
    always_ff @(posedge clock) begin
        if (reset || ClearCount)
            bit_counter <= '0;
        else if (ShiftSR)
            bit_counter <= bit_counter + 1'b1;
    end

    // FSM: Current State Logic
    always_ff @(posedge clock) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM: Next State Logic
    always_comb begin

        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD;
            end
            LOAD: begin
                next_state = SHIFT_COUNT;
            end
            SHIFT_COUNT: begin
                next_state = (bit_counter == N) ? DONE : SHIFT_COUNT;
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    // FSM: Output Logic
    always_comb begin

        {LoadSR, ShiftSR, ClearCount, IncOneCount, ready} = '0;

        case (state)
            IDLE: begin
                ready = reset ? '0 : '1;
                ClearCount = '1;
            end
            LOAD: begin
                LoadSR = '1;
            end
            SHIFT_COUNT: begin
                if ((SR[N-1]) && !(bit_counter == N)) begin
                    IncOneCount = '1;
                    ShiftSR = '1;
                end
                if (!(SR[N-1]) && !(bit_counter == N)) begin
                    ShiftSR = '1;
                end
            end
            DONE: begin
                ready = '1;
            end
        endcase
    end

endmodule
