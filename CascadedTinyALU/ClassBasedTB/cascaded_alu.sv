module cascaded_alu (A1, B1, op_sel, clk, rst, start_op, end_op, result);

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    input [DATA_WIDTH-1:0] A1;
    input [DATA_WIDTH-1:0] B1;
    input [2:0] op_sel;
    input clk;
    input rst;
    input start_op;
    output end_op;
    output [RESULT_WIDTH-1:0] result;

    wire end_op_alu1; // End operation signal from ALU1 must be connected to start operation signal of ALU2
    wire [RESULT_WIDTH-1:0] result_alu1; // Upper half of the result from ALU1 must be connected to the lower half of the result from ALU2

    // Instantiate alu1 module
    alu1 #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) alu1
    (
        .A(A1),
        .B(B1),
        .op_sel(op_sel),
        .clk(clk),
        .rst(rst),
        .start_op(start_op),
        .end_op(end_op_alu1),
        .result(result_alu1)
    );

    // Instantiate alu2 module
    alu2 #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) alu2
    (
        .A(result_alu1[RESULT_WIDTH-1:DATA_WIDTH]),
        .B(result_alu1[DATA_WIDTH-1:0]),
        .op_sel(op_sel),
        .clk(clk),
        .rst(rst),
        .start_op(end_op_alu1),
        .end_op(end_op),
        .result(result)
    );

endmodule

module alu1 (A, B, op_sel, clk, rst, start_op, end_op, result);

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    input [DATA_WIDTH-1:0] A;
    input [DATA_WIDTH-1:0] B;
    input [2:0] op_sel;
    input clk;
    input rst;
    input start_op;
    output end_op;
    output [RESULT_WIDTH-1:0] result;

    // Internal signals
    wire [RESULT_WIDTH-1:0] result_zero, result_single, result_mult;
    wire start_op_zero, start_op_single, start_op_mult, end_op_zero, end_op_single, end_op_mult;

    assign start_op_zero = start_op & op_sel[2];
    assign start_op_single = start_op & (op_sel != 3'b000) & ~op_sel[2];
    assign start_op_mult   = start_op & (op_sel == 3'b000);

    // Instantiate the zero_cycle module for pass-through operation
    zero_cycle #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pass_through
    (
        .A(A),
        .B(B),
        .op_sel(op_sel),
        .clk(clk),
        .rst(rst),
        .start_op(start_op_zero),
        .end_op(end_op_zero),
        .result(result_zero)
    );

    // Instantiate single_cycle module
    single_cycle1 #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) single
    (
        .A(A),
        .B(B),
        .op_sel(op_sel),
        .clk(clk),
        .rst(rst),
        .start_op(start_op_single),
        .end_op(end_op_single),
        .result(result_single)
    );

    // Instantiate three_cycle module
    three_cycle #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) mult
    (
        .A(A),
        .B(B),
        .clk(clk),
        .rst(rst),
        .start_op(start_op_mult),
        .end_op(end_op_mult),
        .result(result_mult)
    );

    // Logic to select the correct result and end_op signals
    assign result = op_sel[2] ? result_zero : (op_sel == 3'b000) ? result_mult : result_single;
    assign end_op = op_sel[2] ? end_op_zero : (op_sel == 3'b000) ? end_op_mult : end_op_single;

endmodule

module alu2 (A, B, op_sel, clk, rst, start_op, end_op, result);

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    input [DATA_WIDTH-1:0] A;
    input [DATA_WIDTH-1:0] B;
    input [2:0] op_sel;
    input clk;
    input rst;
    input start_op;
    output end_op;
    output [RESULT_WIDTH-1:0] result;

    // Internal signals
    wire [RESULT_WIDTH-1:0] result_zero, result_single;
    wire start_op_zero, start_op_single, end_op_zero, end_op_single;

    assign start_op_zero = start_op & ~op_sel[2];
    assign start_op_single = start_op & op_sel[2];

    // Instantiate the zero_cycle module for pass-through operation
    zero_cycle #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pass_through
    (
        .A(A),
        .B(B),
        .op_sel(op_sel),
        .clk(clk),
        .rst(rst),
        .start_op(start_op_zero),
        .end_op(end_op_zero),
        .result(result_zero)
    );

    // Instantiate single_cycle module
    single_cycle2 #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) single
    (
        .A(A),
        .B(B),
        .op_sel(op_sel),
        .clk(clk),
        .rst(rst),
        .start_op(start_op_single),
        .end_op(end_op_single),
        .result(result_single)
    );

    // Logic to select the correct result and end_op signals
    assign result = ~op_sel[2] ? result_zero : result_single;
    assign end_op = ~op_sel[2] ? end_op_zero : end_op_single;

endmodule

module zero_cycle (A, B, op_sel, clk, rst, start_op, end_op, result);

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    input [DATA_WIDTH-1:0] A;
    input [DATA_WIDTH-1:0] B;
    input [2:0] op_sel;
    input clk;
    input rst;
    input start_op;
    output logic end_op;
    output logic [RESULT_WIDTH-1:0] result;

    // Zero Cycle operation
    assign result = {A, B};
    assign end_op = start_op; // End immediately since it's a pass-through

endmodule

module single_cycle1 (A, B, op_sel, clk, rst, start_op, end_op, result);

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    input [DATA_WIDTH-1:0] A;
    input [DATA_WIDTH-1:0] B;
    input [2:0] op_sel;
    input clk;
    input rst;
    input start_op;
    output logic end_op;
    output logic [RESULT_WIDTH-1:0] result;

    // Single Cycle operation
    always_ff @(posedge clk)
        if (rst)
            result <= '0;
        else
            case(op_sel)
                3'b001 : result <= A + B;
                3'b010 : result <= A - B;
                3'b011 : result <= A + B + 1;
                default : result <= '0;
            endcase

    always_ff @(posedge clk)
        if (rst)
            end_op <= '0;
        else
            end_op = (start_op == '1);

endmodule

module single_cycle2 (A, B, op_sel, clk, rst, start_op, end_op, result);

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    input [DATA_WIDTH-1:0] A;
    input [DATA_WIDTH-1:0] B;
    input [2:0] op_sel;
    input clk;
    input rst;
    input start_op;
    output logic end_op;
    output logic [RESULT_WIDTH-1:0] result;

    // Single Cycle operation
    always_ff @(posedge clk)
        if (rst)
            result <= '0;
        else
            case(op_sel)
                3'b100 : result <= A | B;
                3'b101 : result <= A & B;
                3'b110 : result <= A ^ B;
                3'b111 : result <= {~A, ~B};
                default : result <= '0;
            endcase

    always_ff @(posedge clk)
        if (rst)
            end_op <= '0;
        else
            end_op = (start_op == '1);

endmodule

module three_cycle (A, B, clk, rst, start_op, end_op, result);

    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;

    input [DATA_WIDTH-1:0] A;
    input [DATA_WIDTH-1:0] B;
    input clk;
    input rst;
    input start_op;
    output logic end_op;
    output logic [RESULT_WIDTH-1:0] result;

    // Define states for the multiplication operation
    typedef enum logic [1:0] {
        MUL_IDLE,
        MUL_START,
        MUL_WAIT
    } mul_state_t;

    mul_state_t mul_state;

    // Three Cycle operation
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset the module
            mul_state <= MUL_IDLE;
            end_op <= '0;
            result <= '0;
        end else begin
            unique case (mul_state)
                MUL_IDLE: begin
                    if (start_op) begin
                        mul_state <= MUL_START;
                    end
                    end_op <= '0;
                end
                MUL_START: begin
                    mul_state <= MUL_WAIT;
                end             
                MUL_WAIT: begin
                    result <= A * B;
                    end_op <= '1;
                    mul_state <= MUL_IDLE;
                end
            endcase
        end
    end

endmodule
