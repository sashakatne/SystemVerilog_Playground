import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_agent extends uvm_agent;

    // Register the class with the factory
    `uvm_component_utils(cascaded_alu_agent)

    // Declare handles to the components
    cascaded_alu_sequencer sequencer_h;
    cascaded_alu_monitor monitor_h;
    cascaded_alu_driver driver_h;

    // Constructor
    function new(string name = "cascaded_alu_agent", uvm_component parent);
        super.new(name, parent);
        `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_DEBUG);
    endfunction : new

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Building %s", get_full_name()), UVM_DEBUG);

        // Create and configure the components
        sequencer_h = cascaded_alu_sequencer::type_id::create("sequencer_h", this);
        monitor_h = cascaded_alu_monitor::type_id::create("monitor_h", this);
        driver_h = cascaded_alu_driver::type_id::create("driver_h", this);

    endfunction : build_phase

    // Connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Connecting %s", get_full_name()), UVM_DEBUG);
        
        // Connect the driver to the sequencer
        driver_h.seq_item_port.connect(sequencer_h.seq_item_export);
        
    endfunction : connect_phase

endclass
