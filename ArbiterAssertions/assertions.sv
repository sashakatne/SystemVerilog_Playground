module ArbiterAssertions(clock, reset, r, g);

    localparam n=8;
    input clock, reset;
    input [0:n-1] r;
    input [0:n-1] g;

    // Assertion to ensure that the request vector never has invalid bits
    property valid_request;
        disable iff (reset) !$isunknown(r);
    endproperty
    a_valid_request: assert property (@(posedge clock) valid_request) else $error("*** Invalid Request %t: r=%b, g=%b", $time, r, g);

    // Assertion to ensure that except during a reset, the grant vector never has invalid bits
    property valid_grant;
        disable iff (reset) !$isunknown(g);
    endproperty
    a_valid_grant: assert property (@(posedge clock) valid_grant) else $error("*** Invalid Grant %t: r=%b, g=%b", $time, r, g);

    // Assertion to ensure that the arbiter always produces a grant in one cycle
    property grant_in_one_cycle;
        disable iff (reset) |r |=> |g;
    endproperty
    a_grant_in_one_cycle: assert property(@(posedge clock) grant_in_one_cycle) else $error("*** Grant not produced in one cycle %t: r=%b, g=%b", $time, $sampled(r), $sampled(g));

    // Assertion to ensure that there is never more than one simultaneous grant
    property one_grant;
        disable iff (reset) $onehot0(g);
    endproperty
    a_one_grant: assert property (@(posedge clock) one_grant) else $error("*** More than one grant %t: r=%b, g=%b", $time, r, g);

    // Assertion to ensure that if there is a single requestor, then that requestor will receive the grant
    property single_requestor_grant;
        disable iff (reset) $onehot(r) |=> (g == $past(r));
    endproperty
    a_single_requestor_grant: assert property (@(posedge clock) single_requestor_grant) else $error("*** Single requestor did not receive grant %t: r=%b, g=%b", $time, $sampled(r), $sampled(g));

    // Assertion to ensure that a grant is never given to an agent that didn’t request it
    function automatic bit grant_only_to_requestors(input [0:n-1] g, input [0:n-1] r_past);
        for (int i = 0; i < n; i++) begin
            if (g[i] && !r_past[i]) return '0; // If grant is given without request, return false
        end
        return '1; // All grants are valid
    endfunction
    property grant_only_on_request;
        disable iff (reset) grant_only_to_requestors(g, $past(r));
    endproperty
    a_grant_only_on_request: assert property (@(posedge clock) grant_only_on_request) else $error("*** Grant given without request %t: r=%b, g=%b", $time, $sampled(r), $sampled(g));

    // Assertion to ensure a grant is never revoked. That is, if an agent has the grant and continues to request it, it will not lose the grant
    property grant_not_revoked;
        disable iff (reset) (r == $past(r)) |=> $stable(g);
    endproperty
    a_grant_not_revoked: assert property (@(posedge clock) grant_not_revoked) else $error("*** Grant revoked %t: r=%b, g=%b", $time, $sampled(r), $sampled(g));

    // Counter for each agent to track the number of cycles they have been requesting after being granted
    int request_count [0:n-1];
    // Saturation counter logic
    always_ff @(posedge clock) begin
        if (reset) begin
            // Reset all counters on reset
            for (int i = 0; i < n; i++) begin
                request_count[i] <= 0;
            end
        end else begin
            for (int i = 0; i < n; i++) begin
                if (g[i] && r[i])
                    if (request_count[i] < 8'd255) request_count[i] <= request_count[i] + 1;
                    else request_count[i] <= 0;
                else request_count[i] <= 0;
            end
        end
    end

    // Assertions to ensure an agent which has received a grant should not continue to request it for more than 256 total cycles
    generate
        for (genvar i = 0; i < n; i++) begin : gen_request_limit
            property request_limit;
                disable iff (reset) request_count[i] < 8'd255;
            endproperty
            a_request_limit: assert property (@(posedge clock) request_limit) else $error("Agent %0d requested for more than 256 cycles", i);
        end
    endgenerate

    // property Max256;
    //     int grant;
    //     //@(posedge clock) disable iff (reset) (g, grant = g) |-> ##[0:256] !((g == grant));
    //     @(posedge clock) disable iff (reset) ($changed(g), grant = g) |-> not ((r & grant) [*256]);
    // endproperty
    // a_Max256: assert property (Max256) else $error("Agent requested for more than 256 cycles");

endmodule
