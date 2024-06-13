import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_driver extends uvm_driver #(cascaded_alu_transaction); 
  `uvm_component_utils(cascaded_alu_driver)

  virtual cascaded_alu_bfm bfm;
  cascaded_alu_transaction tx;
  bit mul_reset_done;
  int cycle_count;
  
  // Constructor
  function new(string name = "cascaded_alu_driver", uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_DEBUG);
  endfunction : new

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    `uvm_info(get_type_name(), $sformatf("Building %s", get_full_name()), UVM_DEBUG);
    
    if(!uvm_config_db #(virtual cascaded_alu_bfm)::get(this, "", "bfm", bfm))
      `uvm_fatal("NOBFM", {"bfm not defined for ", get_full_name(), "."});
  
  endfunction : build_phase

  // Connect Phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);  
    `uvm_info(get_type_name(), $sformatf("Connecting %s", get_full_name()), UVM_DEBUG);
  endfunction : connect_phase
  
  // Run Phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    bfm.reset_cascaded_alu();
    mul_reset_done = '0;

    forever begin
      seq_item_port.get_next_item(tx);

      // Drive data to Cascaded ALU
      repeat(IDLE_CYCLES) @(posedge bfm.clk);
      bfm.A <= tx.A;
      bfm.B <= tx.B;
      bfm.op_sel <= tx.op_sel;
      bfm.start_op <= tx.start_op;

      assert(!$isunknown(tx.A)) else begin
        `uvm_error(get_type_name(), "A has unknowns");
      end
      assert(!$isunknown(tx.B)) else begin
        `uvm_error(get_type_name(), "B has unknowns");
      end
      assert(!$isunknown(tx.op_sel)) else begin
        `uvm_error(get_type_name(), "op_sel has unknowns");
      end
      assert(!$isunknown(tx.start_op)) else begin
        `uvm_error(get_type_name(), "start_op has unknowns");
      end

      // Initiate reset sequence for multiply operation to cover that case
      if (tx.start_op && tx.op_sel == 3'b000 && !mul_reset_done) begin
        bfm.reset_formulop_cascaded_alu();
        mul_reset_done = '1;
      end else if (tx.start_op) begin
        // Wait for the operation to complete if start_op was high and no reset
        wait(bfm.end_op);
      end

      `uvm_info(get_type_name(), $sformatf("Driver tx \t\t|  A: %h  |  B: %h  |  op_sel: %h  |  start_op: %b  ", tx.A, tx.B, tx.op_sel, tx.start_op), UVM_MEDIUM);
      seq_item_port.item_done();

    end
  endtask : run_phase

endclass

