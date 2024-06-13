import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_environment extends uvm_env;

    // Register the class with the factory
    `uvm_component_utils(cascaded_alu_environment)

    // Declare handles to the components
    cascaded_alu_agent  agent_h;
    cascaded_alu_scoreboard scoreboard_h;
    cascaded_alu_coverage coverage_h;

    // Constructor 
    function new(string name = "cascaded_alu_environment", uvm_component parent);
        super.new(name, parent);
        `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_DEBUG);
    endfunction : new

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Building %s", get_full_name()), UVM_DEBUG); 
        agent_h         = cascaded_alu_agent::type_id::create("agent_h", this);
        scoreboard_h    = cascaded_alu_scoreboard::type_id::create("scoreboard_h", this);
        coverage_h      = cascaded_alu_coverage::type_id::create("coverage_h", this);
    endfunction : build_phase

    // Connect the driver to the sequencer
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Connecting %s", get_full_name()), UVM_DEBUG);
        // Connect the analysis port to the scoreboard
        agent_h.monitor_h.monitor_port.connect(scoreboard_h.scoreboard_port);
        agent_h.monitor_h.monitor_port.connect(coverage_h.analysis_export);

    endfunction : connect_phase

    // Run phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Running %s", get_full_name()), UVM_DEBUG);
    endtask : run_phase

endclass
