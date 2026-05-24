`timescale 1ns/1ps

`ifndef ASSERT_HOLDTICKS_VALUE
`define ASSERT_HOLDTICKS_VALUE 1000
`endif

`ifndef ASSERT_RECALLTICKS_VALUE
`define ASSERT_RECALLTICKS_VALUE 8000
`endif

`ifndef EXPECT_ASSERTION_FAILURE_VALUE
`define EXPECT_ASSERTION_FAILURE_VALUE 0
`endif

module top;

    parameter int HOLDTICKS = 1000;
    parameter int RECALLTICKS = 8000;
    parameter int DESIGN_HOLDTICKS = HOLDTICKS;
    parameter int DESIGN_RECALLTICKS = RECALLTICKS;
    parameter int ASSERT_HOLDTICKS = `ASSERT_HOLDTICKS_VALUE;
    parameter int ASSERT_RECALLTICKS = `ASSERT_RECALLTICKS_VALUE;
    parameter bit EXPECT_ASSERTION_FAILURE = `EXPECT_ASSERTION_FAILURE_VALUE;

    logic Clock;
    logic Reset;
    logic Button;
    logic Press;
    logic Hold;
    logic Recall;

    int checks;
    int errors;

    Buttons #(
        .HOLDTICKS(DESIGN_HOLDTICKS),
        .RECALLTICKS(DESIGN_RECALLTICKS)
    ) B0 (
        .Clock(Clock),
        .Reset(Reset),
        .Button(Button),
        .Press(Press),
        .Hold(Hold),
        .Recall(Recall)
    );

    bind Buttons ButtonAssertions #(
        .ASSERT_HOLDTICKS(`ASSERT_HOLDTICKS_VALUE),
        .ASSERT_RECALLTICKS(`ASSERT_RECALLTICKS_VALUE),
        .EXPECT_ASSERTION_FAILURE(`EXPECT_ASSERTION_FAILURE_VALUE)
    ) BA0 (
        .Clock(Clock),
        .Reset(Reset),
        .Button(Button),
        .Press(Press),
        .Hold(Hold),
        .Recall(Recall)
    );

    initial begin
        Clock = 1'b0;
        forever #5 Clock = ~Clock;
    end

    initial begin
        $dumpfile("button_waveforms.vcd");
        $dumpvars(0, Clock, Reset, Button, Press, Hold, Recall, B0);
    end

    task automatic sample_cycle();
        @(posedge Clock);
        #1;
    endtask

    task automatic drive_button(input logic value);
        @(negedge Clock);
        Button = value;
    endtask

    task automatic record_pass(input string label);
        checks++;
        $display("PASS [%0d]: %s", checks, label);
    endtask

    task automatic record_fail(input string label);
        checks++;
        errors++;
        $display("FAIL [%0d]: %s", checks, label);
    endtask

    task automatic expect_outputs(
        input logic expected_press,
        input logic expected_hold,
        input logic expected_recall,
        input string label
    );
        if ((Press === expected_press) &&
            (Hold === expected_hold) &&
            (Recall === expected_recall)) begin
            record_pass($sformatf(
                "%s Press/Hold/Recall=%0b/%0b/%0b",
                label,
                Press,
                Hold,
                Recall
            ));
        end else begin
            record_fail($sformatf(
                "%s got Press/Hold/Recall=%0b/%0b/%0b expected=%0b/%0b/%0b",
                label,
                Press,
                Hold,
                Recall,
                expected_press,
                expected_hold,
                expected_recall
            ));
        end
    endtask

    task automatic apply_reset();
        Button = 1'b0;
        Reset = 1'b1;
        repeat (3) sample_cycle();
        Reset = 1'b0;
        sample_cycle();
        expect_outputs(1'b0, 1'b0, 1'b0, "reset clears outputs");
    endtask

    task automatic hold_button_high(input int unsigned ticks);
        drive_button(1'b1);
        repeat (ticks) sample_cycle();
    endtask

    task automatic release_button();
        drive_button(1'b0);
        sample_cycle();
    endtask

    task automatic short_press(input int unsigned ticks, input string label);
        hold_button_high(ticks);
        expect_outputs(1'b0, 1'b0, Recall, $sformatf("%s before release", label));
        release_button();
        expect_outputs(1'b1, 1'b0, 1'b0, $sformatf("%s release pulse", label));
        sample_cycle();
        expect_outputs(1'b0, 1'b0, 1'b0, $sformatf("%s press clears", label));
    endtask

    task automatic repress_from_release(input int unsigned ticks, input string label);
        hold_button_high(ticks);
        release_button();
        expect_outputs(1'b1, 1'b0, 1'b0, $sformatf("%s first release pulse", label));
        hold_button_high(1);
        expect_outputs(1'b0, 1'b0, 1'b0, $sformatf("%s immediate re-press clears pulse", label));
        release_button();
        expect_outputs(1'b1, 1'b0, 1'b0, $sformatf("%s second release pulse", label));
        sample_cycle();
        expect_outputs(1'b0, 1'b0, 1'b0, $sformatf("%s second pulse clears", label));
    endtask

    task automatic long_press(input int unsigned ticks, input string label);
        hold_button_high(ticks);
        expect_outputs(1'b0, 1'b1, Recall, $sformatf("%s hold active", label));
        release_button();
        expect_outputs(1'b0, 1'b0, 1'b0, $sformatf("%s release clears hold", label));
        sample_cycle();
        expect_outputs(1'b0, 1'b0, 1'b0, $sformatf("%s stays clear", label));
    endtask

    task automatic idle_low(input int unsigned ticks);
        drive_button(1'b0);
        repeat (ticks) sample_cycle();
    endtask

    initial begin
        int unsigned short_ticks;

        checks = 0;
        errors = 0;
        Reset = 1'b0;
        Button = 1'b0;

        $timeformat(-9, 0, " ns", 6);
        $display(
            "Starting headlamp button self-check: design HOLDTICKS=%0d RECALLTICKS=%0d, assertions HOLDTICKS=%0d RECALLTICKS=%0d",
            DESIGN_HOLDTICKS,
            DESIGN_RECALLTICKS,
            ASSERT_HOLDTICKS,
            ASSERT_RECALLTICKS
        );

        apply_reset();

        short_ticks = (DESIGN_HOLDTICKS > 1) ? (DESIGN_HOLDTICKS - 1) : 1;
        short_press(short_ticks, "short press below hold threshold");
        repress_from_release(short_ticks, "short press followed by immediate re-press");

        long_press(DESIGN_HOLDTICKS, "long press at hold threshold");

        idle_low(DESIGN_RECALLTICKS);
        expect_outputs(1'b0, 1'b0, 1'b1, "idle interval sets recall");

        hold_button_high(1);
        expect_outputs(1'b0, 1'b0, 1'b1, "recall remains during next press");
        release_button();
        expect_outputs(1'b1, 1'b0, 1'b0, "release clears recall and pulses press");
        sample_cycle();
        expect_outputs(1'b0, 1'b0, 1'b0, "post-recall press clears");

        long_press(DESIGN_HOLDTICKS + 3, "extended hold remains hold-only");

        repeat (4) sample_cycle();

        if (errors == 0) begin
            $display("Completed %0d self-checks with 0 errors", checks);
            if (EXPECT_ASSERTION_FAILURE) begin
                $display("Self-checks passed; assertion mismatch mode should report expected assertion failures above");
            end else begin
                $display("No errors -- passed testbench");
            end
        end else begin
            $display("Failed testbench with %0d errors across %0d checks", errors, checks);
            $fatal(1);
        end

        $finish;
    end

endmodule
