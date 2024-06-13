interface intf(input logic clk, rst);

        parameter DATA_WIDTH = 16;
        parameter RESULT_WIDTH = 32;

        //Inputs
        logic [DATA_WIDTH-1:0] A;
        logic [DATA_WIDTH-1:0] B;
        logic [2:0] op_sel;
        logic start_op;

        //outputs
        logic [RESULT_WIDTH-1:0] result;
        logic end_op;
    
endinterface
