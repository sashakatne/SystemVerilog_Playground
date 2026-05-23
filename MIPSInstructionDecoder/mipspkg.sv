package mipspkg;

    typedef struct packed {
        logic [5:0]  opcode;
        logic [25:0] payload;
    } mips_generic_format_t;

    typedef struct packed {
        logic [5:0] opcode;
        logic [4:0] rs;
        logic [4:0] rt;
        logic [4:0] rd;
        logic [4:0] shamt;
        logic [5:0] funct;
    } mips_r_format_t;

    typedef struct packed {
        logic [5:0]  opcode;
        logic [4:0]  rs;
        logic [4:0]  rt;
        logic [15:0] immediate;
    } mips_i_format_t;

    typedef struct packed {
        logic [5:0]  opcode;
        logic [25:0] address;
    } mips_j_format_t;

    typedef union packed {
        logic [31:0]          raw;
        mips_generic_format_t generic;
        mips_r_format_t       r;
        mips_i_format_t       i;
        mips_j_format_t       j;
    } mips_instruction_t;

    function void DecodeInstruction(input mips_instruction_t instruction);
        logic [5:0] opcode;
        opcode = instruction.generic.opcode;

        $display("Instruction 0x%08h", instruction.raw);

        if (opcode == 6'h00) begin
            $display("  Format: R");
            $display("  opcode=0x%02h rs=%0d rt=%0d rd=%0d shamt=%0d funct=0x%02h",
                     instruction.r.opcode,
                     instruction.r.rs,
                     instruction.r.rt,
                     instruction.r.rd,
                     instruction.r.shamt,
                     instruction.r.funct);
        end else if ((opcode == 6'h02) || (opcode == 6'h03)) begin
            $display("  Format: J");
            $display("  opcode=0x%02h address=0x%07h",
                     instruction.j.opcode,
                     instruction.j.address);
        end else begin
            $display("  Format: I");
            $display("  opcode=0x%02h rs=%0d rt=%0d immediate=0x%04h",
                     instruction.i.opcode,
                     instruction.i.rs,
                     instruction.i.rt,
                     instruction.i.immediate);
        end

        $display("");
    endfunction

endpackage
