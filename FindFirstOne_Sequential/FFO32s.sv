module FFO32s(clock, reset, start, b, v, p, ready);
    
    input clock, reset, start;
    input [0:31] b;
    output reg v;
    output reg [0:4] p;
    output reg ready;

    // State declaration using one-hot encoding
    localparam [0:3] INIT = 4'b0001,
                    LOAD = 4'b0010,
                    EVAL = 4'b0100,
                    SHIFT = 4'b1000;

    reg [0:3] state, next_state;

    // If load_reg is high, the shift register will load the input data
    // If shift_once is high, the shift register will shift the data once
    reg shift_once, load_reg;
    // Counter reset and increment signals
    reg clear_ctr, increment_ctr;

    // Internal signals
    reg [0:31] shift_reg_data;
    reg [0:4] counter_out;

    // Shift Register submodule
    ShiftRegister32 shift_reg_inst (.clock(clock), .reset(reset), .load_reg(load_reg), .shift_once(shift_once), .data_in(b), .data_out(shift_reg_data));

    // Counter submodule
    Counter5 counter_inst (.clock(clock), .reset(reset), .counter_reset(clear_ctr), .increment(increment_ctr), .count(counter_out));

    // FSM Sequential Logic for State Transition
    always_ff @(posedge clock) begin
        if (reset)
            state <= INIT;
        else
            state <= next_state;
    end

    // State output logic. Outputs depend only on the current state in a Moore machine
    always @(state) begin
        
        ready = 1'b0;
        load_reg = 1'b0;
        shift_once = 1'b0;
        clear_ctr = 1'b0;
        increment_ctr = 1'b0;
        v = shift_reg_data[0];
        p = counter_out;

        case (state)
            INIT: begin
                ready = 1'b1;
            end
            LOAD: begin
                load_reg = 1'b1;
                clear_ctr = 1'b1;
            end
            EVAL: begin
            end
            SHIFT: begin
                shift_once = 1'b1;
                increment_ctr = 1'b1;
            end
        endcase
    end

    // FSM Sequential Logic for State Transition
    always @(state or start or shift_reg_data[0] or counter_out) begin
        if (reset) begin
            next_state <= INIT;
        end else begin
            case (state)
                INIT: begin
                    next_state <= start ? LOAD : INIT;
                end
                LOAD: begin
                    next_state <= EVAL;
                end
                EVAL: begin
                    next_state <= (shift_reg_data[0] || (counter_out === 5'd31)) ? INIT : SHIFT;
                end
                SHIFT: begin
                    next_state <= EVAL;
                end
                default: begin
                    next_state <= INIT;
                end
            endcase
        end
    end


endmodule

module ShiftRegister32(clock, reset, load_reg, shift_once, data_in, data_out);
    input wire clock, reset, load_reg, shift_once;
    input wire [0:31] data_in;
    output reg [0:31] data_out;

    always_ff @(posedge clock) begin
        if (reset) begin
            data_out <= 32'bx;
        end else begin
            case({load_reg, shift_once})
                2'b10: begin
                    data_out <= data_in;
                end
                2'b01: begin
                    data_out <= {data_out[1:31], 1'b0};
                end
                default: begin
                    data_out <= data_out;
                end
            endcase
        end
    end
endmodule

module Counter5(clock, reset, counter_reset, increment, count);
    input wire clock, reset, counter_reset, increment;
    output reg [0:4] count;

    always_ff @(posedge clock) begin
        if (reset || counter_reset) begin
            count <= 5'b0;
        end else if (increment) begin
            count <= count + 1'b1;
        end
    end
endmodule

