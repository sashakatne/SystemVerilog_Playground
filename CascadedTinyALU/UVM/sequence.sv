import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_sequence extends uvm_sequence #(cascaded_alu_transaction);
  `uvm_object_utils(cascaded_alu_sequence) // Register the class with the factory

  // Declare handles to the transaction packet
  cascaded_alu_transaction tx;
  
  // Constructor 
  function new(string name="cascaded_alu_sequence");
    super.new(name);
  endfunction
  
  task body();
    if (starting_phase != null)
      starting_phase.raise_objection(this);
    `uvm_info("CASCADED_ALU_WRITE_SEQ", "Starting write sequence", UVM_MEDIUM)
    // generate some transactions
    tx = cascaded_alu_transaction::type_id::create("tx");
    repeat(TX_COUNT) begin
      start_item(tx);
      assert(tx.randomize());
      `uvm_info("GENERATE", tx.convert2string(), UVM_HIGH)
      finish_item(tx);
    end
    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask : body
  
endclass
