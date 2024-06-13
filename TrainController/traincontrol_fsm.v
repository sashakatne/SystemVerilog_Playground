module traincontroller_fsm (RESET, S5, S4, S3, S2, S1, CLK, SW3, SW2, SW1, DA1, DA0, DB1, DB0);

    input RESET, S5, S4, S3, S2, S1, CLK;
    output reg SW3, SW2, SW1, DA1, DA0, DB1, DB0;

    // State encoding
    localparam [4:0] AoutBout  = 5'b00001,
                     Aincommon    = 5'b00010,
                     Bincommon    = 5'b00100,
                     Bstop  = 5'b01000,
                     Astop  = 5'b10000;

    // State register
    reg [4:0] state, next_state;

    // State transition logic (next state logic)
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            state <= AoutBout; // Initial state
        end else begin
            state <= next_state;
        end
    end

    // Next state equations based on the current state and sensor inputs
    always @(state or S1 or S2 or S3 or S4 or S5) begin
        case (state)
            AoutBout: begin
                if (!S1 && !S2) next_state = AoutBout;
                else if (!S1 && S2) next_state = Bincommon;
                else if (S1 && !S2) next_state = Aincommon;
                else if (S1 && S2) next_state = Aincommon; //Priority goes to Train A in case of conflict
                else next_state = AoutBout;
            end
            Aincommon: begin
                if (!S2 && !S4) next_state = Aincommon;
                else if (!S2 && S4) next_state = AoutBout;
                else if (S2 && !S4) next_state = Bstop;
                else if (S2 && S4) next_state = AoutBout;
                else next_state = AoutBout;
            end
            Bincommon: begin
                if (!S1 && !S3) next_state = Bincommon;
                else if (!S1 && S3) next_state = AoutBout;
                else if (S1 && !S3) next_state = Astop;
                else if (S1 && S3) next_state = AoutBout;
                else next_state = AoutBout;
            end
            Astop: begin
                if (S3) next_state = Aincommon;
                else next_state = Astop;
            end
            Bstop: begin
                if (S4) next_state = Bincommon;
                else next_state = Bstop;
            end
            default: next_state = AoutBout;
        endcase
    end

    // Output logic based on the current state (Moore outputs)
    always @(state) begin
        // Default outputs (safe state)
        {DA1, DA0} = 2'b00;
        {DB1, DB0} = 2'b00;
        SW1 = 1'b0;
        SW2 = 1'b0;
        SW3 = 1'b0;
        
        case (state)
            AoutBout: begin
                {DA1, DA0} = 2'b01; // Train A forward
                {DB1, DB0} = 2'b01; // Train B forward
                // Switches default to 0 (outer loop continuous)
            end
            Aincommon: begin
                {DA1, DA0} = 2'b01; // Train A forward
                {DB1, DB0} = 2'b01; // Train B forward
                // Switches default to 0 (outer loop continuous)
            end
            Bincommon: begin
                {DA1, DA0} = 2'b01; // Train A forward
                {DB1, DB0} = 2'b01; // Train B forward
                SW1 = 1'b1; // Connect inner track to common track
                SW2 = 1'b1; // Connect inner track to common track
            end
            Astop: begin
                {DA1, DA0} = 2'b00; // Train A stop
                {DB1, DB0} = 2'b01; // Train B forward
                SW1 = 1'b1; // Connect inner track to common track
                SW2 = 1'b1; // Connect inner track to common track
                // Switches default to 0 (outer loop continuous)
            end
            Bstop: begin
                {DA1, DA0} = 2'b01; // Train A forward
                {DB1, DB0} = 2'b00; // Train B stop
                // Switches default to 0 (outer loop continuous)
            end
        endcase
    end

endmodule
