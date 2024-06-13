import uvm_pkg::*;
`include "uvm_macros.svh"
import cascaded_alu_pkg::*;

class cascaded_alu_coverage extends uvm_subscriber #(cascaded_alu_transaction);
    `uvm_component_utils(cascaded_alu_coverage) // Register the component with the factory

    cascaded_alu_transaction tx;

    real cov_op_cov;
    real cov_zeros_or_ones_on_ops;

    covergroup op_cov;

        coverpoint tx.op_sel {
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

        all_ops : coverpoint tx.op_sel {
            bins mul_op = {mul_op};
            bins add_op = {add_op};
            bins sub_op = {sub_op};
            bins addincr_op = {addincr_op};
            bins or_op = {or_op};
            bins and_op = {and_op};
            bins xor_op = {xor_op};
            bins not_op = {not_op};
        }

        a_leg: coverpoint tx.A {
            bins zeros = {0};
            bins bin1 = {[1 : (2**DATA_WIDTH/8)-1]};
            bins bin2 = {[(2**DATA_WIDTH/8) : (2**DATA_WIDTH/4)-1]};
            bins bin3 = {[(2**DATA_WIDTH/4) : (3*2**DATA_WIDTH/8)-1]};
            bins bin4 = {[(3*2**DATA_WIDTH/8) : (2**DATA_WIDTH/2)-1]};
            bins bin5 = {[(2**DATA_WIDTH/2) : (5*2**DATA_WIDTH/8)-1]};
            bins bin6 = {[(5*2**DATA_WIDTH/8) : (3*2**DATA_WIDTH/4)-1]};
            bins bin7 = {[(3*2**DATA_WIDTH/4) : (7*2**DATA_WIDTH/8)-1]};
            bins ones  = {2**DATA_WIDTH-1};
        }

        b_leg: coverpoint tx.B {
            bins zeros = {0};
            bins bin1 = {[1 : (2**DATA_WIDTH/8)-1]};
            bins bin2 = {[(2**DATA_WIDTH/8) : (2**DATA_WIDTH/4)-1]};
            bins bin3 = {[(2**DATA_WIDTH/4) : (3*2**DATA_WIDTH/8)-1]};
            bins bin4 = {[(3*2**DATA_WIDTH/8) : (2**DATA_WIDTH/2)-1]};
            bins bin5 = {[(2**DATA_WIDTH/2) : (5*2**DATA_WIDTH/8)-1]};
            bins bin6 = {[(5*2**DATA_WIDTH/8) : (3*2**DATA_WIDTH/4)-1]};
            bins bin7 = {[(3*2**DATA_WIDTH/4) : (7*2**DATA_WIDTH/8)-1]};
            bins ones  = {2**DATA_WIDTH-1};
        }

        op_00_FF:  cross a_leg, b_leg, all_ops {
            bins mul_00 = binsof (all_ops) intersect {mul_op} &&
                        (binsof (a_leg.zeros) || binsof (b_leg.zeros));
            bins mul_FF = binsof (all_ops) intersect {mul_op} &&
                        (binsof (a_leg.ones) || binsof (b_leg.ones));
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

        }

    endgroup

    // Constructor
    function new(string name = "cascaded_alu_coverage", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info(get_type_name(), $sformatf("Constructing %s", get_full_name()), UVM_DEBUG);
        tx = cascaded_alu_transaction::type_id::create("tx");
        op_cov = new();
        zeros_or_ones_on_ops = new();
    endfunction : new

    virtual function void write(cascaded_alu_transaction t);
        `uvm_info(get_type_name(), $sformatf("Writing to %s", get_full_name()), UVM_DEBUG);
        tx = t;
        t.print();

        op_cov.sample();
        zeros_or_ones_on_ops.sample();

        cov_op_cov = op_cov.get_coverage();
        cov_zeros_or_ones_on_ops = zeros_or_ones_on_ops.get_coverage();

        `uvm_info(get_type_name(), $sformatf("Coverage op_cov: %f", cov_op_cov), UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("Coverage zeros_or_ones_on_ops: %f", cov_zeros_or_ones_on_ops), UVM_NONE);

    endfunction : write

endclass

