
`timescale 1ns/1ns

`define assert(condition) \
if (!(condition)) begin \
  $fatal(1, "ASSERTION FAILED in %m"); \
end #0

`define wait_until_available \
for (c = 0; !is_available && c < COMPUTATION_CYCLES_BOUND; c = c + 1) begin \
	clk = 0; \
	#1; \
	write_enable = 0; \
	clk = 1; \
	#1; \
	if (!is_available) begin \
		`assert(!wakeup_active); \
		`assert(!lsq_wakeup_active); \
	end \
end \
`assert(c < COMPUTATION_CYCLES_BOUND)

module FunctionalUnit_TB(clk);
	// An (exclusive) maximum for the number of cycles we allow
	// an FU to be computing something. If the FU goes this
	// number of cycles without completing we assume it has a bug.
	parameter COMPUTATION_CYCLES_BOUND = 10;
	
	output reg clk = 0;
	reg reset = 0;
	reg write_enable = 0;
	reg [3:0] ALUControl = 0;
	// 0 means (rs1 OPERATION rs2), 1 means (rs1 OPERATION imm)
	reg ALUSrc = 0;
	reg is_for_lsq = 0;
	reg [31:0] imm = 0, rs1_value = 0, rs2_value = 0;
	reg [5:0] tag_to_output = 0;
	reg [5:0] rob_index = 0;
	
	wire is_available;
	wire wakeup_active;
	wire [5:0] wakeup_rob_index;
	wire [5:0] wakeup_tag;
	wire [31:0] wakeup_value;
	wire lsq_wakeup_active;
	wire [5:0] lsq_wakeup_rob_index;
	wire [31:0] lsq_wakeup_value;
	
	FunctionalUnit uut(
		.clk(clk),
		.reset(reset),
		.write_enable(write_enable),
		.ALUControl(ALUControl),
		.ALUSrc(ALUSrc),
		.is_for_lsq(is_for_lsq),
		.imm(imm),
		.rs1_value(rs1_value),
		.rs2_value(rs2_value),
		.tag_to_output(tag_to_output),
		.rob_index(rob_index),
		
		.is_available(is_available),
		.wakeup_active(wakeup_active),
		.wakeup_rob_index(wakeup_rob_index),
		.wakeup_tag(wakeup_tag),
		.wakeup_value(wakeup_value),
		.lsq_wakeup_active(lsq_wakeup_active),
		.lsq_wakeup_rob_index(lsq_wakeup_rob_index),
		.lsq_wakeup_value(lsq_wakeup_value)
	);
	
	initial begin : tb
		integer c;
		
		reset = 1;
		#1;
		reset = 0;
		#1;
		
		clk = 0;
		#1;
		clk = 1;
		#1;
		`assert(is_available);
		`assert(!wakeup_active && !lsq_wakeup_active);
		
		clk = 0;
		#1;
		write_enable = 1;
		ALUControl = 4'b0000; // NOP
		tag_to_output = 6'd0;
		rob_index = 2;
		is_for_lsq = 0;
		clk = 1;
		#1;
		`assert(is_available); // NOPs should complete in under a cycle
		`assert(wakeup_active && !lsq_wakeup_active && wakeup_tag == 6'd0 && wakeup_rob_index == 2);
		
		clk = 0;
		#1;
		write_enable = 0;
		clk = 1;
		#1;
		`assert(is_available);
		`assert(!wakeup_active && !lsq_wakeup_active);
		
		clk = 0;
		#1;
		write_enable = 1;
		imm = 1; rs1_value = 2; rs2_value = 3;
		ALUControl = 4'b0010; ALUSrc = 0; // compute rs1 + rs2
		tag_to_output = 4;
		rob_index = 3;
		is_for_lsq = 0;
		clk = 1;
		#1;
		`assert(!is_available); // ADD should take more than a cycle
		
		`wait_until_available;
		`assert(is_available && wakeup_active && !lsq_wakeup_active && wakeup_tag == 4 && wakeup_rob_index == 3);
		`assert(wakeup_value == 5);
		
		clk = 0;
		#1;
		write_enable = 1;
		imm = 1; rs1_value = -5; rs2_value = 3;
		ALUControl = 4'b1011; ALUSrc = 1; // compute rs1 >>> imm
		tag_to_output = 3;
		rob_index = 6;
		is_for_lsq = 1;
		clk = 1;
		#1;
		`assert(!is_available); // SRA should take more than a cycle
		
		`wait_until_available;
		`assert(is_available && !wakeup_active && lsq_wakeup_active && lsq_wakeup_rob_index == 6);
		`assert(lsq_wakeup_value == -3); // SRA by 1 is division by 2 rounding towards -infinity
		
		clk = 0;
		#1;
		write_enable = 1;
		imm = 1; rs1_value = 13; rs2_value = 2;
		ALUControl = 4'b1011; ALUSrc = 0; // compute rs1 >>> rs2
		tag_to_output = 3;
		rob_index = 2;
		is_for_lsq = 1;
		clk = 1;
		#1;
		`assert(!is_available); // SRA should take more than a cycle
		
		`wait_until_available;
		`assert(is_available && !wakeup_active && lsq_wakeup_active && lsq_wakeup_rob_index == 2);
		`assert(lsq_wakeup_value == 3); // SRA by 2 is division by 4 rounding towards -infinity
		
		clk = 0;
		#1;
		write_enable = 1;
		imm = 456; rs1_value = 1; rs2_value = 2;
		ALUControl = 4'b1111; ALUSrc = 1; // pass through imm
		tag_to_output = 3;
		rob_index = 9;
		is_for_lsq = 0;
		clk = 1;
		#1;
		
		`wait_until_available;
		`assert(is_available && wakeup_active && !lsq_wakeup_active && wakeup_tag == 3 && wakeup_rob_index == 9);
		`assert(wakeup_value == 456);
		
		$stop;
	end
endmodule