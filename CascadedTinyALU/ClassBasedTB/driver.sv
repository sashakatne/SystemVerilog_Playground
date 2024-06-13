import pkg::*;

class driver;
    
	int no_trans;

	generator gen;
	virtual intf drv_if;
	mailbox gen2driv;

	//this function allows for communcation with mailbox and creates an interface
	function new(virtual intf drv_if, mailbox gen2driv);
		this.drv_if = drv_if;
		this.gen2driv = gen2driv;
	endfunction

	task reset;
		$display("Reset Initiated");
		wait(drv_if.rst);
		drv_if.A <= '0;
		drv_if.B <= '0;
		drv_if.op_sel <= '0;
		drv_if.start_op <= '0;
		wait(!drv_if.rst);
		$display("Reset is Complete");
	endtask

	virtual task drive();
	begin 

		transaction trans1;
		drv_if.start_op <= '0;
		gen2driv.get(trans1);
	
		@(posedge drv_if.clk);
		drv_if.A <= trans1.A;
		drv_if.B <= trans1.B;
		drv_if.op_sel <= trans1.op_sel;

		$display("DRIVER: Transaction Received from Generator");
		$display ("\t A = %0h \t B = %0h \t op_sel = %0b", trans1.A, trans1.B, trans1.op_sel);

		drv_if.start_op <= '1;

	end
	endtask

	task  main();
		drive();
	endtask
         
endclass
