import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_test extends uvm_test;

    // Register the class with the factory 
    `uvm_component_utils(cascaded_alu_test);

    // Declare handles to the components
    cascaded_alu_environment environment_h;
    cascaded_alu_sequence sequence_h;

    // Define the constructor
    function new(string name = "cascaded_alu_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_HIGH);
    endfunction : new
  
    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Building %s", get_full_name()), UVM_HIGH);
        environment_h = cascaded_alu_environment::type_id::create("environment_h", this);
    endfunction : build_phase
  
    // End of elab phase for topology setup
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_type_name(), $sformatf("End of Elaboration %s", get_full_name()), UVM_HIGH);
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    // Run phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Running %s", get_full_name()), UVM_HIGH);
        sequence_h = cascaded_alu_sequence::type_id::create("sequence_h");
        phase.raise_objection(this);

        if (!sequence_h.randomize())
            `uvm_error("RANDOMIZE", "Failed to randomize sequence")

        fork
            sequence_h.start(environment_h.agent_h.sequencer_h);
        join

        phase.drop_objection(this); 
    endtask
  
endclass
