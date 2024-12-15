
`timescale 1ns/1ns // Tell Questa what time scale to run at

`define assert(condition) \
if (!(condition)) begin \
  $fatal(1, "ASSERTION FAILED in %m"); \
end #0

module Rename_TB(clk);
	
	output reg clk = 0;
	reg reset = 0;
	reg wakeup_0_active = 0;
	reg [5:0] wakeup_0_tag = 0;
	reg [31:0] wakeup_0_value = 0;
	reg [4:0] architectural_rd = 0, architectural_rs1 = 0, architectural_rs2 = 0;
	
	wire [5:0] physical_rd, physical_rs1, physical_rs2, old_physical_rd;
	wire rs1_ready, rs2_ready;
	wire [31:0] rs1_value, rs2_value;
	
	Rename uut(
		.clk(clk),
		.reset(reset),
		.wakeup_0_active(wakeup_0_active),
		.wakeup_0_tag(wakeup_0_tag),
		.wakeup_0_value(wakeup_0_value),
		.wakeup_1_active(0), .wakeup_1_tag(0), .wakeup_1_value(0),
		.wakeup_2_active(0), .wakeup_2_tag(0), .wakeup_2_value(0),
		.wakeup_3_active(0), .wakeup_3_tag(0), .wakeup_3_value(0),
		.freed_tag_1(6'd0),
		.freed_tag_2(6'd0),
		.is_instruction_valid(1),
		.architectural_rd(architectural_rd),
		.architectural_rs1(architectural_rs1),
		.architectural_rs2(architectural_rs2),
		.physical_rd(physical_rd),
		.physical_rs1(physical_rs1),
		.physical_rs2(physical_rs2),
		.old_physical_rd(old_physical_rd),
		.rs1_ready(rs1_ready),
		.rs2_ready(rs2_ready),
		.rs1_value(rs1_value),
		.rs2_value(rs2_value)
	);
	
	initial begin : tb
		reg [5:0] first_x1_tag;
		reg [5:0] second_x1_tag;
		
		reset = 1;
		#1;
		reset = 0;
		#1;
	
		clk = 0;
		#1;
		clk = 1;
		#1;
		// add x1, x0, x1
		// We'll consider the destination here to be the "first" x1,
		// which I guess makes its initial value of p1 the 0th x1.
		architectural_rd = 1;
		architectural_rs1 = 0;
		architectural_rs2 = 1;
		#1;
		first_x1_tag = physical_rd;
		`assert(rs1_ready && rs1_value == 0);
		`assert(rs2_ready && rs2_value == 0);
		
		clk = 0;
		#1;
		clk = 1;
		#1;
		// add x1, x0, x1
		architectural_rd = 1;
		architectural_rs1 = 0;
		architectural_rs2 = 1;
		#1;
		second_x1_tag = physical_rd;
		// The x1 rd on the previous cycle is the x1 source for the current one.
		`assert(physical_rs2 == first_x1_tag);
		`assert(physical_rd != first_x1_tag);
		`assert(old_physical_rd == first_x1_tag);
		`assert(rs1_ready && rs1_value == 0);
		`assert(!rs2_ready);
		
		clk = 0;
		#1;
		clk = 1;
		#1;
		// add x0, x0, x1
		architectural_rd = 0;
		architectural_rs1 = 0;
		architectural_rs2 = 1;
		// Simulate the computation of the first add (generating the first x1) completing.
		wakeup_0_active = 1;
		wakeup_0_tag = first_x1_tag;
		wakeup_0_value = 123;
		#1;
		`assert(physical_rs2 == second_x1_tag);
		`assert(old_physical_rd == 0);
		`assert(rs1_ready && rs1_value == 0);
		`assert(!rs2_ready); // rs2 will be ready when the *second* add completes.
		
		clk = 0;
		#1;
		clk = 1;
		#1;
		// add x0, x0, x1
		architectural_rd = 0;
		architectural_rs1 = 0;
		architectural_rs2 = 1;
		// Simulate the computation of the second add (generating the second x1) completing.
		wakeup_0_active = 1;
		wakeup_0_tag = second_x1_tag;
		wakeup_0_value = 456;
		#1;
		`assert(physical_rs2 == second_x1_tag);
		`assert(old_physical_rd == 0);
		`assert(rs1_ready && rs1_value == 0);
		`assert(rs2_ready && rs2_value == 456); // The value should be ready even on the same cycle the wakeup is happening.
		
		clk = 0;
		#1;
		clk = 1;
		#1;
		// add x0, x0, x1
		architectural_rd = 0;
		architectural_rs1 = 0;
		architectural_rs2 = 1;
		wakeup_0_active = 0;
		#1;
		`assert(physical_rs2 == second_x1_tag);
		`assert(old_physical_rd == 0);
		`assert(rs1_ready && rs1_value == 0);
		`assert(rs2_ready && rs2_value == 456); // It should remain ready thereafter.
		
		$stop;
	end
endmodule