import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_sequencer extends uvm_sequencer #(cascaded_alu_transaction);
    `uvm_component_utils(cascaded_alu_sequencer)

    // Constructor
    function new(string name = "cascaded_alu_sequencer", uvm_component parent);
        super.new(name, parent);
        `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_DEBUG);
    endfunction : new

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Building %s", get_full_name()), UVM_DEBUG);
    endfunction : build_phase

    // Connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Connecting %s", get_full_name()), UVM_DEBUG);
    endfunction : connect_phase    
    
endclass
