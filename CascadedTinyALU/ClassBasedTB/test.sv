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

    $display("Transactions checked: %0d, errors: %0d", env.scb.no_trans, env.scb.errors);
    if (env.scb.errors == 0)
      $display("No errors -- passed testbench");
    else
      $display("Failed testbench");

    $finish;

  end

endprogram

