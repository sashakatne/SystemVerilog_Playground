import pkg::*;

program test(intf in);

  environment env;
  
  initial begin
  
    $display("ALU TEST START");

    env = new(in);
    env.gen.trans_count = 1;
    env.no_of_transactions = 4200;
    env.no_of_iterations = 8;

    env.run();
    $display("ALU TEST FINISH");
    $stop;

  end

endprogram

