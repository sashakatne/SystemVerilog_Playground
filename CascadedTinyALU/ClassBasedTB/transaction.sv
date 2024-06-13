class transaction;

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    bit [DATA_WIDTH-1:0] A;
    bit [DATA_WIDTH-1:0] B;
    rand bit [2:0] op_sel;

    bit clk;
    bit rst;
    bit start_op;

    // Outputs
    logic end_op;
    logic [RESULT_WIDTH-1:0] result;

    // Constrained randomization
    function bit [DATA_WIDTH-1:0] get_data();
        bit [1:0] choice;
        choice = $random % 3; // Randomly choose between 0, 1, or 2

        case (choice)
            0: return {DATA_WIDTH{1'b0}}; // All zeros
            1: return {DATA_WIDTH{1'b1}}; // All ones
            2: return $random; // Random data
        endcase
    endfunction

    function new();
        A = get_data();
        B = get_data();
    endfunction

endclass
