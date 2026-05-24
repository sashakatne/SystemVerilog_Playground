module Buttons #(
    parameter int HOLDTICKS = 1000,
    parameter int RECALLTICKS = 8000
) (
    input  logic Clock,
    input  logic Reset,
    input  logic Button,
    output logic Press,
    output logic Hold,
    output logic Recall
);

    localparam int EFFECTIVE_HOLDTICKS = (HOLDTICKS < 1) ? 1 : HOLDTICKS;
    localparam int EFFECTIVE_RECALLTICKS = (RECALLTICKS < 1) ? 1 : RECALLTICKS;

    typedef enum logic [3:0] {
        BUTTON_UP       = 4'b0001,
        BUTTON_PRESSED  = 4'b0010,
        BUTTON_DOWN     = 4'b0100,
        BUTTON_RELEASED = 4'b1000
    } button_state_t;

    button_state_t State;
    int unsigned   Timer;

    always_ff @(posedge Clock) begin
        if (Reset) begin
            State  <= BUTTON_UP;
            Timer  <= 0;
            Press  <= 1'b0;
            Hold   <= 1'b0;
            Recall <= 1'b0;
        end else begin
            Press <= 1'b0;

            unique case (State)
                BUTTON_UP: begin
                    Hold <= 1'b0;

                    if (Button) begin
                        State <= BUTTON_PRESSED;
                        Timer <= 1;
                    end else begin
                        State <= BUTTON_UP;
                        if (Timer < EFFECTIVE_RECALLTICKS) begin
                            Timer <= Timer + 1;
                        end

                        if ((Timer + 1) >= EFFECTIVE_RECALLTICKS) begin
                            Recall <= 1'b1;
                        end
                    end
                end

                BUTTON_PRESSED,
                BUTTON_DOWN: begin
                    if (Button) begin
                        State <= BUTTON_DOWN;

                        if (Timer < EFFECTIVE_HOLDTICKS) begin
                            Timer <= Timer + 1;
                        end

                        if ((Timer + 1) >= EFFECTIVE_HOLDTICKS) begin
                            Hold <= 1'b1;
                        end
                    end else begin
                        State  <= BUTTON_RELEASED;
                        Timer  <= 0;
                        Press  <= (Timer < EFFECTIVE_HOLDTICKS);
                        Hold   <= 1'b0;
                        Recall <= 1'b0;
                    end
                end

                BUTTON_RELEASED: begin
                    Press  <= 1'b0;
                    Hold   <= 1'b0;
                    Recall <= 1'b0;

                    if (Button) begin
                        State <= BUTTON_PRESSED;
                        Timer <= 1;
                    end else begin
                        State <= BUTTON_UP;
                        Timer <= 1;
                        if (EFFECTIVE_RECALLTICKS <= 1) begin
                            Recall <= 1'b1;
                        end
                    end
                end

                default: begin
                    State  <= BUTTON_UP;
                    Timer  <= 0;
                    Press  <= 1'b0;
                    Hold   <= 1'b0;
                    Recall <= 1'b0;
                end
            endcase
        end
    end

endmodule
