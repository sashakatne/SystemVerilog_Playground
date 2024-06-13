// N-bit Sequential Multiplier implemented hierarchically using a DataPath module and a Control Sequencer FSM module

module SequentialMultiplier(clock, reset, multiplicand, multiplier, product, ready, start);

    parameter N = 4;
    input clock;
    input reset;
    input [N-1:0] multiplicand, multiplier;
    output [2*N-1:0] product;
    output ready;
    input start;

    // FSM control signals
    logic add_enable, load, shift, lsb, done, increment, counter_reset;

    // Instantiate DataPath module
    DataPath #(N) datapath (clock, reset, start, add_enable, load, shift, increment, counter_reset, multiplicand, multiplier, product, lsb, done);
    // Instantiate Control Sequencer FSM module
    FSM #(N) fsm (clock, reset, start, lsb, done, ready, add_enable, load, shift, increment, counter_reset);

endmodule

module DataPath (clock, reset, start, add_enable, load, shift, increment, counter_reset, multiplicand, multiplier, product, lsb, done);

    parameter N = 4;
    input logic clock;
    input logic reset;
    input logic start;
    input logic add_enable;
    input logic load;
    input logic shift;
    input logic increment;
    input logic counter_reset;
    input logic [N-1:0] multiplicand;
    input logic [N-1:0] multiplier;
    output logic [2*N-1:0] product;
    output logic lsb;
    output logic done;

    // Internal signals
    logic [N-1:0] m_register;
    logic [2*N-1:0] ph_pl_register;
    logic [$clog2(N)-1:0] counter_reg;
    logic adder_carry;
    logic [N-1:0] sum;

    assign done = (counter_reg == N-1);
    assign lsb = ph_pl_register[0];
    assign product = ph_pl_register;

    // Adder with conditional operation based on LSB of PL and 'add' control signal
    always_comb begin
        {adder_carry, sum} = add_enable ? (m_register + ph_pl_register[2*N-1:N]) : {1'b0, ph_pl_register[2*N-1:N]};
    end

    // M-Register (N-bit) and PH&PL-Registers (2N-bit)
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            m_register <= '0;
            ph_pl_register <= '0;
        end
        else if (load) begin
            m_register <= multiplicand;
            ph_pl_register <= {{N{1'b0}}, multiplier};
        end
        else if (shift) begin
            ph_pl_register <= {adder_carry, sum, ph_pl_register[N-1:0]} >> 1;
        end
    end

    // Counter (log2(N) bit)
    always_ff @(posedge clock or posedge reset) begin
        if (reset)
            counter_reg <= '0;
        else if (increment)
            counter_reg <= counter_reg + 1'b1;
        else if (counter_reset)
            counter_reg <= '0;
    end

endmodule

module FSM(clock, reset, start, lsb, done, ready, add_enable, load, shift, increment, counter_reset);

    parameter N = 4;
    input logic clock;
    input logic reset;
    input logic start;
    input logic lsb;
    input logic done;
    output logic ready;
    output logic add_enable;
    output logic load;
    output logic shift;
    output logic increment;
    output logic counter_reset;

    // Define the states using an enumerated type for clarity
    typedef enum logic [1:0] {
        INIT = 2'b01, // Initialization state
        EVAL = 2'b10  // Evaluate state
    } state_t;

    // State and next state variables
    state_t current_state, next_state;

    // Synchronous state transition block
    always_ff @(posedge clock or posedge reset) begin
        if (reset)
            current_state <= INIT;
        else
            current_state <= next_state;
    end

    // Combinational next state logic block
    always_comb begin
        next_state = current_state; // Default to stay in the current state

        case (current_state)
            INIT: if (start) next_state = EVAL;
            EVAL: if (done) next_state = INIT;
        endcase
    end

    // Combinational output logic block
    always_comb begin
        // Set all outputs to 0 by default
        {ready, add_enable, load, shift, increment, counter_reset} = '0;

        case (current_state)
            INIT: { ready, load, counter_reset } = { ~reset, start, start };
            EVAL: { add_enable, shift, increment } = { lsb, '1, '1 };
        endcase
    end

endmodule
