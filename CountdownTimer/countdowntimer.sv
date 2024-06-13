module countdowntimer #(
    parameter N = 8 // Parameter for the width of the counter
)(
    input clk,          // Clock signal
    input reset,        // Synchronous reset signal
    input load,         // Load signal to load the counter
    input [N-1:0] value, // Value to load into the counter
    input decr,         // Decrement signal
    output reg timeup        // Output signal to indicate counter has reached zero
);

    // Internal counter register
    reg [N-1:0] counter;

    // Always block for synchronous logic
    always @(posedge clk) begin
        if (reset) begin
            // Synchronous reset: set counter to zero
            counter <= 0;
            timeup <= 0;
        end else if (load) begin
            // Load the counter with the input value when load signal is asserted
            counter <= value;
            timeup <= (value == 0); // If value loaded is 0, assert timeup
        end else if (decr && counter > 0) begin
            // Decrement the counter if it's greater than zero and decr is asserted
            counter <= counter - 1;
            timeup <= (counter == 1); // If after decrement counter is 1, next cycle it will be 0, so assert timeup
        end
        // If none of the above conditions are met, retain the current counter value
        // and timeup state (timeup should remain asserted once counter reaches zero)
    end

endmodule
