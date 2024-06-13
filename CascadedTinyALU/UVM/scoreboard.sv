import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;
`uvm_analysis_imp_decl(_port)

class cascaded_alu_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(cascaded_alu_scoreboard); // Register the component with the factory

    // Declare analysis port
    uvm_analysis_imp_port #(cascaded_alu_transaction, cascaded_alu_scoreboard) scoreboard_port;
    cascaded_alu_transaction tx_stack[$];

    // Constructor
	function new(string name = "cascaded_alu_scoreboard", uvm_component parent);
		super.new(name, parent);
        `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_HIGH);
	endfunction: new
	
    // Build phase
	function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Building %s", get_full_name()), UVM_HIGH);
        // Use new constructor to create the analysis ports
        scoreboard_port = new("scoreboard_port", this);
    endfunction: build_phase

    // Connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Connecting %s", get_full_name()), UVM_HIGH);
    endfunction: connect_phase
    
    // Run Phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);  
        `uvm_info(get_type_name(), $sformatf("Running %s", get_full_name()), UVM_HIGH);
        
        forever begin
            logic [RESULT_WIDTH-1:0] expected;
            logic [RESULT_WIDTH-1:0] received;
            cascaded_alu_transaction current_tx;
                
            wait(tx_stack.size() > 0);
            current_tx = tx_stack.pop_front();
            received = current_tx.result;

            wait(current_tx.end_op);

            unique case (current_tx.op_sel)
                3'b000: expected = current_tx.A * current_tx.B;
                3'b001: expected = current_tx.A + current_tx.B;
                3'b010: expected = current_tx.A - current_tx.B;
                3'b011: expected = current_tx.A + current_tx.B + 1;
                3'b100: expected = current_tx.A | current_tx.B;
                3'b101: expected = current_tx.A & current_tx.B;
                3'b110: expected = current_tx.A ^ current_tx.B;
                3'b111: expected = {~current_tx.A, ~current_tx.B};
            endcase
                
            if (received !== expected) begin
                `uvm_error("SCOREBOARD", $sformatf("Data mismatch!: A: %h, B: %h, op_sel: %b, expected: %h, received: %h", current_tx.A, current_tx.B, current_tx.op_sel, expected, received));
            end
            else begin
                `uvm_info("SCOREBOARD", $sformatf("Data match: expected %h, got %h", expected, received), UVM_MEDIUM);
            end
        end
    endtask: run_phase

    function void write_port(cascaded_alu_transaction mon_tx);
        tx_stack.push_back(mon_tx);
        `uvm_info(get_type_name(), $sformatf("Scoreboard tx \t|  A: %h | B: %h | op_sel: %h | end_op: %b | result: %h", mon_tx.A, mon_tx.B, mon_tx.op_sel, mon_tx.end_op, mon_tx.result), UVM_HIGH);
    endfunction : write_port

endclass 
