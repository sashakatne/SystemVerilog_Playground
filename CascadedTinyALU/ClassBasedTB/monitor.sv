import pkg::*;

class monitor;

	virtual intf mon_if;
	mailbox mon2scb;
	
	function new(virtual intf mon_if, mailbox mon2scb);
		this.mon_if = mon_if;
		this.mon2scb = mon2scb;
	endfunction
	
	virtual task drive();
		begin
			
			transaction trans_mon;
			trans_mon = new();
			@(posedge mon_if.end_op);

			$display("MONITOR: Transaction Received from the DUT");
			trans_mon.A = mon_if.A;
			trans_mon.B = mon_if.B;
			trans_mon.op_sel = mon_if.op_sel;
			trans_mon.start_op = mon_if.start_op;
			trans_mon.end_op = mon_if.end_op;
			trans_mon.result = mon_if.result;

			mon2scb.put(trans_mon);
			
		end
	endtask

	task  main();
		drive(); 
	endtask

endclass
  
