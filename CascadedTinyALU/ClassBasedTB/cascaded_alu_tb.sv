import pkg::*;

module top;

    // Parameters of the ALU
    parameter DATA_WIDTH = 16;
    parameter RESULT_WIDTH = 32;
    parameter CLK_PERIOD = 12.5;

    bit          clk;
    bit          rst;
    
    always #(CLK_PERIOD/2) clk = ~clk;

    typedef enum bit[2:0] {mul_op  = 3'b000,
                            add_op  = 3'b001,
                            sub_op  = 3'b010,
                            addincr_op = 3'b011,
                            or_op   = 3'b100,
                            and_op  = 3'b101,
                            xor_op  = 3'b110,
                            not_op  = 3'b111} operation_t;
    operation_t  op_set;

    assign in.op_sel = op_set;
    
    initial 
    begin
        clk = '0;
        rst = '1;
        
        repeat (2) @(posedge clk);
        rst = '0;

        repeat (8) begin
            repeat (4200*3) @(posedge clk);
            rst = '1;
            repeat (2) @(posedge clk);
            rst = '0;
        end
    end

    intf in (clk, rst);
    test t1 (in);

    // Instantiate the ALU
    cascaded_alu #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESULT_WIDTH(RESULT_WIDTH)
    ) DUT (
        .clk(in.clk),
        .rst(in.rst),
        .start_op(in.start_op),
        .op_sel(in.op_sel),
        .A1(in.A),
        .B1(in.B),
        .result(in.result),
        .end_op(in.end_op)
    );

    covergroup op_cov;

        coverpoint in.op_sel {
            bins single_cycle[] = {[add_op : not_op]};
            bins multi_cycle = {mul_op};

            bins opn_rst[] = ([mul_op : not_op] => not_op);

            bins sngl_mul[] = ([add_op : not_op] => mul_op);
            bins mul_sngl[] = (mul_op => [add_op : not_op]);

            bins twoops[] = ([add_op : not_op] [* 2]);
            bins manymult = (mul_op [* 3:5]);

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

        all_ops : coverpoint in.op_sel {
            bins mul_op = {mul_op};
            bins add_op = {add_op};
            bins sub_op = {sub_op};
            bins addincr_op = {addincr_op};
            bins or_op = {or_op};
            bins and_op = {and_op};
            bins xor_op = {xor_op};
            bins not_op = {not_op};
        }

        a_leg: coverpoint in.A {
            bins zeros = {0};
            bins others= {[1:2**DATA_WIDTH-2]};
            bins ones  = {2**DATA_WIDTH-1};
        }

        b_leg: coverpoint in.B {
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

    op_cov oc;
    zeros_or_ones_on_ops c_00_FF;

    initial begin

        oc = new();
        c_00_FF = new();

        forever begin @(posedge clk);
            oc.sample();
            c_00_FF.sample();
        end

    end

endmodule
