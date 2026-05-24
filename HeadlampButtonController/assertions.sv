module ButtonAssertions #(
    parameter int HOLDTICKS = 1000,
    parameter int RECALLTICKS = 8000,
    parameter int ASSERT_HOLDTICKS = HOLDTICKS,
    parameter int ASSERT_RECALLTICKS = RECALLTICKS,
    parameter bit EXPECT_ASSERTION_FAILURE = 1'b0
) (
    input logic Clock,
    input logic Reset,
    input logic Button,
    input logic Press,
    input logic Hold,
    input logic Recall
);

    localparam int EFFECTIVE_HOLDTICKS = (ASSERT_HOLDTICKS < 1) ? 1 : ASSERT_HOLDTICKS;
    localparam int EFFECTIVE_RECALLTICKS = (ASSERT_RECALLTICKS < 1) ? 1 : ASSERT_RECALLTICKS;

    int unsigned high_ticks;
    int unsigned low_ticks;
    int assertion_failures;
    logic        button_q;
    logic        initialized;
    logic        expected_press;
    logic        expected_hold;
    logic        expected_recall;

    always_ff @(posedge Clock) begin
        if (Reset) begin
            high_ticks      <= 0;
            low_ticks       <= 0;
            button_q        <= 1'b0;
            initialized     <= 1'b0;
            expected_press  <= 1'b0;
            expected_hold   <= 1'b0;
            expected_recall <= 1'b0;
        end else begin
            initialized    <= 1'b1;
            button_q       <= Button;
            expected_press <= 1'b0;

            if (Button) begin
                high_ticks <= button_q ? (high_ticks + 1) : 1;
                low_ticks  <= 0;

                if ((button_q ? (high_ticks + 1) : 1) >= EFFECTIVE_HOLDTICKS) begin
                    expected_hold <= 1'b1;
                end
            end else begin
                high_ticks    <= 0;
                expected_hold <= 1'b0;

                if (button_q) begin
                    low_ticks       <= 0;
                    expected_press  <= (high_ticks < EFFECTIVE_HOLDTICKS);
                    expected_recall <= 1'b0;
                end else begin
                    low_ticks <= low_ticks + 1;
                    if ((low_ticks + 1) >= EFFECTIVE_RECALLTICKS) begin
                        expected_recall <= 1'b1;
                    end
                end
            end
        end
    end

    task automatic report_assertion_failure(input string message);
        assertion_failures++;
        if (EXPECT_ASSERTION_FAILURE) begin
            $error("EXPECTED ASSERTION FAILURE: %s", message);
        end else begin
            $fatal(1, "ASSERTION FAILURE: %s", message);
        end
    endtask

    property known_outputs;
        disable iff (Reset) !$isunknown({Button, Press, Hold, Recall});
    endproperty
    a_known_outputs: assert property (@(posedge Clock) known_outputs)
        else report_assertion_failure("Button, Press, Hold, or Recall is unknown");

    property press_one_cycle;
        disable iff (Reset) Press |=> !Press;
    endproperty
    a_press_one_cycle: assert property (@(posedge Clock) press_one_cycle)
        else report_assertion_failure("Press remained asserted for more than one cycle");

    property no_press_and_hold;
        disable iff (Reset) !(Press && Hold);
    endproperty
    a_no_press_and_hold: assert property (@(posedge Clock) no_press_and_hold)
        else report_assertion_failure("Press and Hold asserted at the same time");

    property outputs_match_reference;
        disable iff (Reset || !initialized)
            (Press === expected_press) &&
            (Hold === expected_hold) &&
            (Recall === expected_recall);
    endproperty
    a_outputs_match_reference: assert property (@(posedge Clock) outputs_match_reference)
        else report_assertion_failure($sformatf(
            "outputs Press/Hold/Recall=%0b/%0b/%0b expected=%0b/%0b/%0b high_ticks=%0d low_ticks=%0d",
            $sampled(Press),
            $sampled(Hold),
            $sampled(Recall),
            $sampled(expected_press),
            $sampled(expected_hold),
            $sampled(expected_recall),
            $sampled(high_ticks),
            $sampled(low_ticks)
        ));

    property short_press_drives_press;
        disable iff (Reset || !initialized)
            expected_press |-> (Press && !Hold);
    endproperty
    a_short_press_drives_press: assert property (@(posedge Clock) short_press_drives_press)
        else report_assertion_failure("short press did not produce exactly Press");

    property long_press_drives_hold;
        disable iff (Reset || !initialized)
            expected_hold |-> (Hold && !Press);
    endproperty
    a_long_press_drives_hold: assert property (@(posedge Clock) long_press_drives_hold)
        else report_assertion_failure("long press did not produce exactly Hold");

    property recall_matches_idle_reference;
        disable iff (Reset || !initialized)
            expected_recall |-> Recall;
    endproperty
    a_recall_matches_idle_reference: assert property (@(posedge Clock) recall_matches_idle_reference)
        else report_assertion_failure("long idle interval did not produce Recall");

    final begin
        if (EXPECT_ASSERTION_FAILURE && (assertion_failures == 0)) begin
            $error("Expected assertion-failure mode did not trigger any assertion failures");
        end
    end

endmodule
