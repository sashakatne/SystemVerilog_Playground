import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

typedef enum bit[2:0] {mul_op  = 3'b000,
						add_op  = 3'b001,
						sub_op  = 3'b010,
						addincr_op = 3'b011,
						or_op   = 3'b100,
						and_op  = 3'b101,
						xor_op  = 3'b110,
						not_op  = 3'b111} op_type;

class cascaded_alu_transaction extends uvm_sequence_item;
	`uvm_object_utils(cascaded_alu_transaction)	//provides type name for factory creation

	function new(string name = "cascaded_alu_transaction");
		super.new(name);
	endfunction: new

    rand bit [DATA_WIDTH-1:0] A;
    rand bit [DATA_WIDTH-1:0] B;
    rand op_type op_sel;
    rand bit start_op;

    bit clk;
    bit rst;

    // Outputs
    logic end_op;
    logic [RESULT_WIDTH-1:0] result;

    constraint A_distribution {
        A dist {
            16'h0000 :/ 1,
            [16'h0001 : 16'h3FFF] :/ 25,
            [16'h4000 : 16'h7FFF] :/ 25,
            [16'h8000 : 16'hBFFF] :/ 25,
            [16'hC000 : 16'hFFFE] :/ 25,
            16'hFFFF :/ 1
        };
    }

    constraint B_distribution {
        B dist {
            16'h0000 :/ 1,
            [16'h0001 : 16'h3FFF] :/ 25,
            [16'h4000 : 16'h7FFF] :/ 25,
            [16'h8000 : 16'hBFFF] :/ 25,
            [16'hC000 : 16'hFFFE] :/ 25,
            16'hFFFF :/ 1
        };
    }
	
	function string convert2string();
		return $sformatf("A: %h, B: %h, op_sel: %h, clk: %b, rst: %b, start_op: %b, end_op: %b, result: %h", A, B, op_sel, clk, rst, start_op, end_op, result);
	endfunction: convert2string

endclass: cascaded_alu_transaction
