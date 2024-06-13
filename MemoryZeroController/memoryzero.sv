module Memory64x8(clock, addr, din, we, dout);
parameter ADDRWIDTH = 0;
parameter DATAWIDTH = 0;

input clock;
input [ADDRWIDTH-1:0] addr;
input [DATAWIDTH-1:0] din;
input we;
output [DATAWIDTH-1:0] dout;

reg [DATAWIDTH-1:0] m [(1 << ADDRWIDTH)-1:0];

assign dout = m[addr];

always @(posedge clock)
	if (we) m[addr] <= din;
endmodule

// Latch
module Register(load, din, dout);
parameter WIDTH = 0;
input load;
input [WIDTH-1:0] din;
output [WIDTH-1:0] dout;

reg [WIDTH-1:0] m;

assign dout = m;
always_latch
	if (load) m <= din;
endmodule

module UpCounter(clock, din, load, enable, dout);
parameter WIDTH = 0;
input clock;
input [WIDTH-1:0] din;
input load;
input enable;
output [WIDTH-1:0] dout;

reg [WIDTH-1:0] m;

assign dout = m;
always_ff @(posedge clock)
	begin
	if (load)
		m <= din;
	else if (enable)
		m <= m + '1;
	else
		m <= m;
	end
endmodule

module Mux2x1(d1, d0, select, dout);
parameter WIDTH = 0;
input [WIDTH-1:0] d1, d0;
input select;
output [WIDTH-1:0] dout;

assign dout = select ? d1 : d0;
endmodule

module JKFF(clock, j, k, q);
input clock;
input j, k;
output q;

reg q;

always_ff @(posedge clock)
	begin
	if ({j,k} == 2'b11)
		q <= ~q;
	else if ({j,k} == 2'b10)
		q <= 1;
	else if ({j,k} == 2'b01)
		q <= '0;
	else
		q <= q;
	end
endmodule

module Comparator(dina, dinb, aEQb);
parameter WIDTH = 0;
input [WIDTH-1:0] dina, dinb;
output aEQb;

assign aEQb = (dina == dinb);
endmodule

module DataPath(clock, ld_high, ld_low, addr, din, write, set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we, cnt_eq, dout, busy);
parameter ADDRWIDTH = 0;
parameter DATAWIDTH = 0;

input clock;
input ld_high, ld_low;
input [ADDRWIDTH-1:0] addr;
input [DATAWIDTH-1:0] din;
input write;
input set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we;
output cnt_eq;

output [DATAWIDTH-1:0] dout;
output busy;

wire [ADDRWIDTH-1:0] dina, dinb, dcnt;
wire [ADDRWIDTH-1:0] addrm;
wire [DATAWIDTH-1:0] dinm;

Register #(ADDRWIDTH) R1 (ld_high,  addr, dina);
Register #(ADDRWIDTH) R2 (ld_low,	addr, dcnt);

UpCounter #(ADDRWIDTH) UC (clock, dcnt, ld_cnt, cnt_en, dinb);
JKFF BusyFF (clock, set_busy, clr_busy, busy);

Mux2x1 #(ADDRWIDTH) AddrMux(dinb, addr, addr_sel, addrm);
Mux2x1 #(DATAWIDTH) DataMux('0,    din, addr_sel, dinm);

Comparator #(ADDRWIDTH) C (dina, dinb, cnt_eq);

Memory64x8 #(ADDRWIDTH, DATAWIDTH) Mem (clock, addrm, dinm, write | zero_we, dout);

endmodule

module MemoryZeroController(clock, reset, zero, cnt_eq, set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we);
input clock, reset;
input zero;
input cnt_eq;
output set_busy;
output clr_busy;
output ld_cnt;
output cnt_en;
output addr_sel;
output zero_we;

reg set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we;

enum logic [1:0] {Init, Load, Write} State, NextState;


// Sequential block: reset and update state register
always_ff @(posedge clock)
begin
if (reset)
	State <= Init;
else
	State <= NextState;
end


// Output logic
always_comb
begin
{set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we} = '0;
case (State) 
	Init:
		begin
		clr_busy = '1;
		end
		
	Load:
		begin			
		set_busy = '1;
		ld_cnt = '1;
		end
		
	Write:
		begin
		zero_we = '1;		
		set_busy = '1;
		cnt_en = '1;
		addr_sel = '1;
		end
endcase
end

// Next state logic
always_comb
begin
NextState = State;
case (State)
	Init:
		if (zero)
			NextState = Load;
			
	Load:
		NextState = Write;
		
	Write:
		if (cnt_eq)
			NextState = Init;
endcase
end
endmodule

module mz(clock, reset, ld_high, addr, ld_low, din, write, zero, dout, busy);

parameter ADDRWIDTH = 8;
parameter DATAWIDTH = 8;

input clock;
input reset;
input ld_high, ld_low;
input [ADDRWIDTH-1:0] addr;
input [DATAWIDTH-1:0] din;
input write;
input zero;
output [DATAWIDTH-1:0] dout;
output busy;

wire set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we, cnt_eq;

DataPath #(ADDRWIDTH, DATAWIDTH) DP(clock, ld_high, ld_low, addr, din, write, set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we, cnt_eq, dout, busy);
MemoryZeroController FSM(clock, reset, zero, cnt_eq, set_busy, clr_busy, ld_cnt, cnt_en, addr_sel, zero_we);
endmodule
