import pkg::*;

class environment;
    
    //Instantiate Generator and Driver
    generator gen;
    driver driv;
    monitor mon;
    scoreboard scb;
    
    //Instantiate Communication between Generator and Driver
    mailbox gen2driv;
    mailbox mon2scb;
    
    event driv2gen;
    
    virtual intf vif;

    int no_of_transactions;
    int no_of_iterations;

    function new(virtual intf vif);
        this.vif = vif;
        gen2driv = new();
        mon2scb	= new();
        gen	= new(gen2driv, driv2gen);
        driv = new (vif, gen2driv);
        mon = new (vif, mon2scb);
        scb	= new (mon2scb);
    endfunction
    
    //reset task
    task pre_env();
        driv.reset();
    endtask
        
    //Generate and Drive
    task test();
        $display("********************************");
        gen.main();
        $display("DRIVER STARTED");
        driv.main();
        $display("MONITOR STARTED");
        mon.main();
        $display("SCOREBOARD STARTED");
        scb.main();
        $display("********************************");
    endtask
        
    task run();

        repeat(no_of_iterations) begin
            pre_env();

            $display("------Simulation iterations requested %0d-------", no_of_transactions);
            for (int i = 0; i < no_of_transactions; i++) 
                begin
                    test();
                end
        end

        $stop;
    endtask
        
endclass
