interface simplebus_if #(
    parameter int ADDR_WIDTH = 24,
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic reset
);

    logic                  Strobe;
    logic                  Read;
    logic                  Write;
    logic [ADDR_WIDTH-1:0] Addr;
    tri   [DATA_WIDTH-1:0] Data;
    tri0                   Ack;

    modport processor (
        input  clk,
        input  reset,
        input  Ack,
        inout  Data,
        output Strobe,
        output Read,
        output Write,
        output Addr
    );

    modport memory (
        input  clk,
        input  reset,
        input  Strobe,
        input  Read,
        input  Write,
        input  Addr,
        inout  Data,
        output Ack
    );

endinterface

module processor_interface #(
    parameter int ADDR_WIDTH = 24,
    parameter int DATA_WIDTH = 8,
    parameter int TIMEOUT_CYCLES = 16
) (
    simplebus_if.processor bus
);

    typedef enum logic [2:0] {
        PROC_IDLE,
        PROC_REQUEST,
        PROC_WAIT_ACK,
        PROC_COMPLETE,
        PROC_TIMEOUT
    } processor_state_t;

    processor_state_t      state;
    logic                  drive_data;
    logic [DATA_WIDTH-1:0] data_drive;

    assign bus.Data = drive_data ? data_drive : {DATA_WIDTH{1'bz}};

    initial begin
        state      = PROC_IDLE;
        drive_data = 1'b0;
        data_drive = '0;
        bus.Strobe = 1'b0;
        bus.Read   = 1'b0;
        bus.Write  = 1'b0;
        bus.Addr   = '0;
    end

    task automatic finish_cycle();
        bus.Strobe = 1'b0;
        bus.Read   = 1'b0;
        bus.Write  = 1'b0;
        bus.Addr   = '0;
        drive_data = 1'b0;
        data_drive = '0;

        @(posedge bus.clk);
        #1;
        state = PROC_IDLE;
    endtask

    task automatic ReadMem(
        input  logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data,
        output bit                    ok
    );
        int cycles;

        @(posedge bus.clk);
        state      = PROC_REQUEST;
        bus.Addr   = addr;
        bus.Read   = 1'b1;
        bus.Write  = 1'b0;
        drive_data = 1'b0;
        data_drive = '0;
        bus.Strobe = 1'b1;

        state = PROC_WAIT_ACK;
        ok = 1'b0;
        cycles = 0;
        while (!ok && (cycles < TIMEOUT_CYCLES)) begin
            @(posedge bus.clk);
            #1;
            ok = bus.Ack;
            cycles++;
        end

        if (ok) begin
            data = bus.Data;
            state = PROC_COMPLETE;
        end else begin
            data = 'x;
            state = PROC_TIMEOUT;
        end

        finish_cycle();
    endtask

    task automatic WriteMem(
        input  logic [ADDR_WIDTH-1:0] addr,
        input  logic [DATA_WIDTH-1:0] data,
        output bit                    ok
    );
        int cycles;

        @(posedge bus.clk);
        state      = PROC_REQUEST;
        bus.Addr   = addr;
        bus.Read   = 1'b0;
        bus.Write  = 1'b1;
        data_drive = data;
        drive_data = 1'b1;
        bus.Strobe = 1'b1;

        state = PROC_WAIT_ACK;
        ok = 1'b0;
        cycles = 0;
        while (!ok && (cycles < TIMEOUT_CYCLES)) begin
            @(posedge bus.clk);
            #1;
            ok = bus.Ack;
            cycles++;
        end

        state = ok ? PROC_COMPLETE : PROC_TIMEOUT;
        finish_cycle();
    endtask

endmodule

module memory_interface #(
    parameter int ADDR_WIDTH = 24,
    parameter int DATA_WIDTH = 8,
    parameter int LOCAL_ADDR_WIDTH = 16,
    parameter int unsigned BASE_ADDR = 0
) (
    simplebus_if.memory bus
);

    localparam int BASE_ADDR_WIDTH = ADDR_WIDTH - LOCAL_ADDR_WIDTH;

    typedef enum logic [1:0] {
        MEM_IDLE,
        MEM_RESPOND
    } memory_state_t;

    memory_state_t                  state;
    logic                           ack_drive;
    logic                           data_drive;
    logic                           pending_read;
    logic [DATA_WIDTH-1:0]          read_data;
    logic [DATA_WIDTH-1:0]          memory [0:(1 << LOCAL_ADDR_WIDTH)-1];
    logic [LOCAL_ADDR_WIDTH-1:0]    local_addr;
    logic [BASE_ADDR_WIDTH-1:0]     request_base;
    logic [BASE_ADDR_WIDTH-1:0]     base_address;
    logic                           selected_request;

    assign local_addr = bus.Addr[LOCAL_ADDR_WIDTH-1:0];
    assign request_base = bus.Addr[ADDR_WIDTH-1:LOCAL_ADDR_WIDTH];
    assign base_address = BASE_ADDR[BASE_ADDR_WIDTH-1:0];
    assign selected_request = bus.Strobe &&
                              (bus.Read ^ bus.Write) &&
                              (request_base == base_address);

    assign bus.Ack = ack_drive ? 1'b1 : 1'bz;
    assign bus.Data = data_drive ? read_data : {DATA_WIDTH{1'bz}};

    always_ff @(posedge bus.clk or posedge bus.reset) begin
        if (bus.reset) begin
            state        <= MEM_IDLE;
            ack_drive    <= 1'b0;
            data_drive   <= 1'b0;
            pending_read <= 1'b0;
            read_data    <= '0;
        end else begin
            case (state)
                MEM_IDLE: begin
                    ack_drive  <= 1'b0;
                    data_drive <= 1'b0;
                    if (selected_request) begin
                        pending_read <= bus.Read;
                        if (bus.Write) begin
                            memory[local_addr] <= bus.Data;
                        end else begin
                            read_data <= memory[local_addr];
                        end
                        state <= MEM_RESPOND;
                    end
                end

                MEM_RESPOND: begin
                    ack_drive  <= 1'b1;
                    data_drive <= pending_read;
                    if (!bus.Strobe) begin
                        ack_drive    <= 1'b0;
                        data_drive   <= 1'b0;
                        pending_read <= 1'b0;
                        state        <= MEM_IDLE;
                    end
                end

                default: begin
                    ack_drive  <= 1'b0;
                    data_drive <= 1'b0;
                    state      <= MEM_IDLE;
                end
            endcase
        end
    end

endmodule

module top;

    parameter int unsigned NUMMEM = 4;

    localparam int ADDR_WIDTH = 24;
    localparam int DATA_WIDTH = 8;

    logic clk;
    logic reset;

    int checks;
    int errors;

    simplebus_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) bus (
        .clk(clk),
        .reset(reset)
    );

    processor_interface #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TIMEOUT_CYCLES(16)
    ) cpu (
        .bus(bus.processor)
    );

    generate
        for (genvar mem_index = 0; mem_index < NUMMEM; mem_index++) begin : g_memory
            memory_interface #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .LOCAL_ADDR_WIDTH(16),
                .BASE_ADDR(mem_index)
            ) mem (
                .bus(bus.memory)
            );
        end
    endgenerate

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        repeat (3) @(posedge clk);
        reset = 1'b0;
    end

    function automatic logic [ADDR_WIDTH-1:0] make_addr(
        input int unsigned base,
        input logic [15:0] offset
    );
        make_addr = {base[7:0], offset};
    endfunction

    task automatic record_pass(input string label);
        checks++;
        $display("PASS [%0d]: %s", checks, label);
    endtask

    task automatic record_fail(input string label);
        checks++;
        errors++;
        $display("FAIL [%0d]: %s", checks, label);
    endtask

    task automatic expect_write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input string                 label
    );
        bit ok;

        cpu.WriteMem(addr, data, ok);
        if (ok) begin
            record_pass($sformatf("%s write addr=0x%06h data=0x%02h", label, addr, data));
        end else begin
            record_fail($sformatf("%s write timed out addr=0x%06h data=0x%02h", label, addr, data));
        end
    endtask

    task automatic expect_read(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] expected,
        input string                 label
    );
        bit ok;
        logic [DATA_WIDTH-1:0] actual;

        cpu.ReadMem(addr, actual, ok);
        if (!ok) begin
            record_fail($sformatf("%s read timed out addr=0x%06h", label, addr));
        end else if (actual !== expected) begin
            record_fail($sformatf(
                "%s read mismatch addr=0x%06h actual=0x%02h expected=0x%02h",
                label,
                addr,
                actual,
                expected
            ));
        end else begin
            record_pass($sformatf("%s read addr=0x%06h data=0x%02h", label, addr, actual));
        end
    endtask

    task automatic expect_read_timeout(
        input logic [ADDR_WIDTH-1:0] addr,
        input string                 label
    );
        bit ok;
        logic [DATA_WIDTH-1:0] actual;

        cpu.ReadMem(addr, actual, ok);
        if (ok) begin
            record_fail($sformatf("%s unexpected read acknowledge addr=0x%06h data=0x%02h", label, addr, actual));
        end else begin
            record_pass($sformatf("%s read timeout addr=0x%06h", label, addr));
        end
    endtask

    task automatic expect_write_timeout(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input string                 label
    );
        bit ok;

        cpu.WriteMem(addr, data, ok);
        if (ok) begin
            record_fail($sformatf("%s unexpected write acknowledge addr=0x%06h data=0x%02h", label, addr, data));
        end else begin
            record_pass($sformatf("%s write timeout addr=0x%06h data=0x%02h", label, addr, data));
        end
    endtask

    initial begin
        if ((NUMMEM < 1) || (NUMMEM > 256)) begin
            $display("FAIL: NUMMEM must be in the range 1..256, got %0d", NUMMEM);
            $fatal(1);
        end
    end

    initial begin
        logic [DATA_WIDTH-1:0] expected;
        logic [ADDR_WIDTH-1:0] addr;
        int unsigned last_base;

        checks = 0;
        errors = 0;

        wait (reset == 1'b0);
        #1;

        $display("Starting SimpleBus multi-memory self-check with NUMMEM=%0d", NUMMEM);

        for (int unsigned base = 0; base < NUMMEM; base++) begin
            expected = 8'h40 + base[7:0];
            addr = make_addr(base, 16'h0100);
            expect_write(addr, expected, $sformatf("base %0d directed", base));
            expect_read(addr, expected, $sformatf("base %0d directed", base));
        end

        expect_write(make_addr(0, 16'h0000), 8'ha5, "base 0 low boundary");
        expect_read(make_addr(0, 16'h0000), 8'ha5, "base 0 low boundary");

        expect_write(make_addr(0, 16'hfffe), 8'h5a, "base 0 high-1 boundary");
        expect_read(make_addr(0, 16'hfffe), 8'h5a, "base 0 high-1 boundary");

        last_base = NUMMEM - 1;
        expect_write(make_addr(last_base, 16'hffff), 8'hc3, "last base high boundary");
        expect_read(make_addr(last_base, 16'hffff), 8'hc3, "last base high boundary");

        for (int unsigned base = 0; base < NUMMEM; base++) begin
            expected = 8'h80 ^ base[7:0];
            expect_write(make_addr(base, 16'h1234), expected, $sformatf("base %0d isolated offset", base));
        end

        for (int unsigned base = 0; base < NUMMEM; base++) begin
            expected = 8'h80 ^ base[7:0];
            expect_read(make_addr(base, 16'h1234), expected, $sformatf("base %0d isolated offset", base));
        end

        if (NUMMEM < 256) begin
            expect_read_timeout(make_addr(NUMMEM, 16'h00aa), "unmapped base");
            expect_write_timeout(make_addr(NUMMEM, 16'h00aa), 8'h99, "unmapped base");
        end else begin
            record_pass("unmapped timeout skipped because every base address is populated");
        end

        repeat (4) @(posedge clk);

        if (errors == 0) begin
            $display("Completed %0d self-checks with 0 errors", checks);
            $display("No errors -- passed testbench");
        end else begin
            $display("Failed testbench with %0d errors across %0d checks", errors, checks);
            $fatal(1);
        end

        $finish;
    end

endmodule
