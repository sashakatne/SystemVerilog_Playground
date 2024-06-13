import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_monitor extends uvm_monitor;
  `uvm_component_utils(cascaded_alu_monitor) // Register the component with the factory
  
  virtual cascaded_alu_bfm bfm;
  cascaded_alu_transaction mon_tx;

  // Declare a single analysis port
  uvm_analysis_port #(cascaded_alu_transaction) monitor_port;

  // Constructor
  function new(string name = "cascaded_alu_monitor", uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_DEBUG);
  endfunction : new

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    `uvm_info(get_type_name(), $sformatf("Building %s", get_full_name()), UVM_DEBUG);
    if(!uvm_config_db #(virtual cascaded_alu_bfm)::get(this, "", "bfm", bfm))
      `uvm_fatal("NOBFM", {"bfm not defined for ", get_full_name(), "."});
    // Use new constructor to create the analysis port
    monitor_port = new("monitor_port", this);
  endfunction : build_phase
  
  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Connecting %s", get_full_name()), UVM_DEBUG);
  endfunction : connect_phase

  // Run Phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase); 
    `uvm_info(get_type_name(), $sformatf("Running %s", get_full_name()), UVM_DEBUG);
    
    forever begin
      mon_tx = cascaded_alu_transaction::type_id::create("mon_tx");
      @(posedge bfm.end_op);
      mon_tx.start_op = bfm.start_op;
      mon_tx.A = bfm.A;
      mon_tx.B = bfm.B;
      mon_tx.op_sel = bfm.op_sel;
      mon_tx.end_op = bfm.end_op;
      mon_tx.result = bfm.result;

      assert(!$isunknown(mon_tx.result)) else begin
        `uvm_error(get_type_name(), "Result has unknowns");
      end

      `uvm_info(get_type_name(), $sformatf("Monitor mon_tx \t| start_op: %b | A: %h | B: %h | op_sel: %h | end_op: %b | result: %h", mon_tx.start_op, mon_tx.A, mon_tx.B, mon_tx.op_sel, mon_tx.end_op, mon_tx.result), UVM_HIGH);
      monitor_port.write(mon_tx);
    end
  endtask : run_phase
endclass : cascaded_alu_monitor
