// Mealy FSM with 2 states

module FFO32sMealy(clock, reset, start, b, v, p, ready);

    input clock, reset, start;
    input [0:31] b;
    output v;
    output [0:4] p;
    output reg ready;

localparam 
	IDLE  = 2'b01,
	CHECK = 2'b10;

reg [1:0] State, NextState;

reg [31:0] Count;
reg [31:0] SR;

reg ClearCount, IncCount;
reg LoadSR, ShiftSR;

assign v = SR[31];
assign p = Count[31:0];

// counter
always_ff @(posedge clock) begin

    if (ClearCount)
        Count <= '0;
    else
        if (IncCount)
            Count <= Count + 1'b1;
        else
            Count <= Count;

end

// shift register
always_ff @(posedge clock) begin

    if (LoadSR)
        SR <= b;
    else
        if (ShiftSR)
            SR <= SR << 1;
        else
            SR <= SR;

end

// sequential logic
always_ff @(posedge clock) begin

    if (reset)
        State <= IDLE;	
    else
        State <= NextState;
    end

// Next state and output combinational logic
always_comb begin
    // Default assignments
    NextState = State;
    {ready, LoadSR, ShiftSR, IncCount, ClearCount} = '0;

    case (State)
        IDLE: begin
            ready = '1;
            if (start) begin
                NextState = CHECK;
                {LoadSR, ClearCount} = '1;
            end
        end
        CHECK: begin
            if (SR[31] || Count == 31) begin
                NextState = IDLE;
            end else begin
                {IncCount, ShiftSR} = '1;
            end
        end
    endcase
end

endmodule
