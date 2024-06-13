module top;

   // Parameters of the ALU
   localparam DATA_WIDTH = 16;
   localparam RESULT_WIDTH = 32;

   typedef enum bit[2:0] {mul_op  = 3'b000,
                          add_op  = 3'b001,
                          sub_op  = 3'b010,
                          addincr_op = 3'b011,
                          or_op   = 3'b100,
                          and_op  = 3'b101,
                          xor_op  = 3'b110,
                          not_op  = 3'b111} operation_t;

   bit [DATA_WIDTH-1:0] A;
   bit [DATA_WIDTH-1:0] B;
   bit          clk;
   bit          rst;
   wire [2:0]   op_sel;
   bit          start_op;
   wire         end_op;
   wire [RESULT_WIDTH-1:0] result;
   operation_t  op_set;

   assign op_sel = op_set;

    // Instantiate the ALU
    cascaded_ece593_alu #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESULT_WIDTH(RESULT_WIDTH)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .start_op(start_op),
        .op_sel(op_sel),
        .A1(A),
        .B1(B),
        .result(result),
        .end_op(end_op)
    );

   covergroup op_cov;

      coverpoint op_set {
         bins single_cycle[] = {[add_op : not_op]};
         bins multi_cycle = {mul_op};

         bins opn_rst[] = ([mul_op : not_op] => not_op);

         bins sngl_mul[] = ([add_op : not_op] => mul_op);
         bins mul_sngl[] = (mul_op => [add_op : not_op]);

         bins twoops[] = ([add_op : not_op] [* 2]);
         bins manymult = (mul_op [* 3:5]);

         bins add_sub_mix[] = (add_op => sub_op => add_op);
         bins logical_ops[] = ([or_op : not_op] [* 2]);
         bins not_after_logical[] = ([or_op : xor_op] => not_op);
         bins sequential_ops[] = ([add_op : addincr_op] => [or_op : not_op]);
         bins add_or_sub[] = ([add_op : sub_op] [* 2]);
         bins logical_then_arith[] = ([or_op : not_op] => [add_op : addincr_op]);
         bins arith_then_logical[] = ([add_op : sub_op] => [or_op : not_op]);
         bins not_to_logical[] = (not_op => [or_op : xor_op]);
         bins cycle_4_ops[] = ([add_op : or_op] [* 4]);
      }

   endgroup

   covergroup zeros_or_ones_on_ops;

      all_ops : coverpoint op_set {
         bins mul_op = {mul_op};
         bins add_op = {add_op};
         bins sub_op = {sub_op};
         bins addincr_op = {addincr_op};
         bins or_op = {or_op};
         bins and_op = {and_op};
         bins xor_op = {xor_op};
         bins not_op = {not_op};
      }

      a_leg: coverpoint A {
         bins zeros = {0};
         bins others= {[1:2**DATA_WIDTH-2]};
         bins ones  = {2**DATA_WIDTH-1};
      }

      b_leg: coverpoint B {
         bins zeros = {0};
         bins others= {[1:2**DATA_WIDTH-2]};
         bins ones  = {2**DATA_WIDTH-1};
      }

      op_00_FF:  cross a_leg, b_leg, all_ops {
         bins mul_00 = binsof (all_ops) intersect {mul_op} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins mul_FF = binsof (all_ops) intersect {mul_op} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));
         bins mul_max = binsof (all_ops) intersect {mul_op} &&
                        (binsof (a_leg.ones) && binsof (b_leg.ones));

         bins add_00 = binsof (all_ops) intersect {add_op} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins add_FF = binsof (all_ops) intersect {add_op} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins sub_00 = binsof (all_ops) intersect {sub_op} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins sub_FF = binsof (all_ops) intersect {sub_op} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins addincr_00 = binsof (all_ops) intersect {addincr_op} &&
                           (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins addincr_FF = binsof (all_ops) intersect {addincr_op} &&
                           (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins or_00 = binsof (all_ops) intersect {or_op} &&
                     (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins or_FF = binsof (all_ops) intersect {or_op} &&
                     (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins and_00 = binsof (all_ops) intersect {and_op} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins and_FF = binsof (all_ops) intersect {and_op} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins xor_00 = binsof (all_ops) intersect {xor_op} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins xor_FF = binsof (all_ops) intersect {xor_op} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins not_00 = binsof (all_ops) intersect {xor_op} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));
         bins not_FF = binsof (all_ops) intersect {xor_op} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         ignore_bins others_only =
                                  binsof(a_leg.others) && binsof(b_leg.others);
      }

   endgroup

   initial begin
      clk = '0;
      forever begin
         #10;
         clk = ~clk;
      end
   end
   
   op_cov oc;
   zeros_or_ones_on_ops c_00_FF;

   initial begin
   
      oc = new();
      c_00_FF = new();
   
      forever begin @(negedge clk);
         oc.sample();
         c_00_FF.sample();
      end
   end

   function operation_t get_op();
      bit [2:0] op_choice;
      op_choice = $random;
      unique case (op_choice)
        3'b000 : return mul_op;
        3'b001 : return add_op;
        3'b010 : return sub_op;
        3'b011 : return addincr_op;
        3'b100 : return or_op;
        3'b101 : return and_op;
        3'b110 : return xor_op;
        3'b111 : return not_op;
      endcase
   endfunction

   function bit [DATA_WIDTH-1:0] get_data();
      bit [$clog2(DATA_WIDTH)-1:0] zero_ones;
      zero_ones = $random;
      if (zero_ones == '0)
        return '0;
      else if (zero_ones == '1)
        return '1;
      else
        return $random;
   endfunction

   always @(posedge end_op) begin
      bit [RESULT_WIDTH-1:0] predicted_result;
      #1;
      unique case (op_set)
         mul_op: predicted_result = A * B;
         add_op: predicted_result = A + B;
         sub_op: predicted_result = A - B;
         addincr_op: predicted_result = A + B + 1;
         or_op: predicted_result = A | B;
         and_op: predicted_result = A & B;
         xor_op: predicted_result = A ^ B;
         not_op: predicted_result = {~A, ~B};
      endcase // case (op_set)

      if (predicted_result !== result)
         $error ("FAILED: A: %0h  B: %0h  op_sel: %s got: %0h expected: %0h",
               A, B, op_set.name(), result, predicted_result);

   end
   
   initial begin
      repeat (10) begin
         rst = '1;
         @(negedge clk);
         @(negedge clk);
         rst = '0;
         start_op = '0;
         repeat (10000) begin
            @(negedge clk);
            op_set = get_op();
            A = get_data();
            B = get_data();
            start_op = '1;
            case (op_set) // handle the start_op signal
            default: begin 
               wait(end_op);
               start_op = '0;
            end
            endcase // case (op_set)
         end
      end
      $stop;
   end
endmodule



