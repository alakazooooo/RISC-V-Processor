
`timescale 1ns/1ns // Tell Questa what time scale to run at

`define assert(condition) \
if (!(condition)) begin \
  $fatal(1, "ASSERTION FAILED in %m"); \
end #0

module ReorderBuffer_TB(clk);
	
	output reg clk = 0;
	reg wakeup_active = 0;
	reg enqueue_enable = 0;
	reg [5:0] wakeup_rob_index = 0;
	reg [5:0] enqueue_old_tag = 0;
	
	wire [5:0] next_rob_index;
	wire [5:0] freed_tag_1, freed_tag_2;
	
	ReorderBuffer #(.ROB_SIZE(4)) uut(
		.clk(clk),
		.enqueue_enable(enqueue_enable), .enqueue_old_tag(enqueue_old_tag),
		.wakeup_active(wakeup_active),
		.wakeup_rob_index(wakeup_rob_index),
		.next_rob_index(next_rob_index),
		.freed_tag_1(freed_tag_1), .freed_tag_2(freed_tag_2)
	);
	
	initial begin
		reg [5:0] rob_indices [4];
		integer i, j;
	
		clk = 0;
		#1;
		clk = 1;
		#1;
		`assert(freed_tag_1 == 0 && freed_tag_2 == 0);
		
		clk = 0;
		#1;
		
		// Fill up the ROB with 4 entries.
		for (i = 0; i < 4; i = i + 1) begin
			rob_indices[i] = next_rob_index;
			enqueue_enable = 1;
			enqueue_old_tag = i+1;
			clk = 1;
			#1;
			`assert(freed_tag_1 == 0 && freed_tag_2 == 0);
			
			clk = 0;
			#1;
		end
		
		// Those entries must have gone to distinct indices.
		for (i = 0; i < 4; i = i + 1) begin
			for (j = i + 1; j < 4; j = j + 1) begin
				`assert(rob_indices[i] != rob_indices[j]);
			end
		end
		
		enqueue_enable = 0;
		wakeup_rob_index = rob_indices[1];
		clk = 1;
		#1;
		
		// TODO assert no frees
		clk = 0;
		#1;
		
		// Entries can only be retired in order.
		// TODO wakeup 3, and assert no frees, then 0 + two frees, then nothing + one free, then nothing + no frees, then enqueue, then 4 + one free
		
		$stop;
	end
endmodule