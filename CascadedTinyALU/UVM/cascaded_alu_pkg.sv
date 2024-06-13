package cascaded_alu_pkg;
	import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Parameters for FIFO configuration
	parameter DATA_WIDTH = 16, RESULT_WIDTH = 32;
	parameter CYCLE_TIME = 12.5;  // 80 MHz
	
	// Parameters for the testbench	
	parameter TX_COUNT = 10000;
	parameter IDLE_CYCLES = 2;

	`include "transaction.sv"
	`include "sequence.sv"
	`include "sequencer.sv"
	`include "driver.sv"
	`include "monitor.sv"
    `include "agent.sv"
	`include "scoreboard.sv"
	`include "coverage.sv"
    `include "environment.sv"
	`include "test.sv"

endpackage : cascaded_alu_pkg
