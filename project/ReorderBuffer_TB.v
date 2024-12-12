
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
	
	initial begin : tb
		reg [5:0] rob_indices [3:0];
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
		wakeup_active = 1;
		wakeup_rob_index = rob_indices[1];
		clk = 1;
		#1;
		// We woke up the second ROB entry, so the ROB shouldn't retire
		// anything because the first entry is still not woken up.
		`assert(freed_tag_1 == 0 && freed_tag_2 == 0);
		clk = 0;
		#1;
		
		wakeup_active = 1;
		wakeup_rob_index = rob_indices[2];
		clk = 1;
		#1;
		// Same thing. The first entry is still not woken up.
		`assert(freed_tag_1 == 0 && freed_tag_2 == 0);
		clk = 0;
		#1;
		
		wakeup_active = 1;
		wakeup_rob_index = rob_indices[0];
		clk = 1;
		#1;
		// Now we have woken up entries 0, 1 and 2 so the ROB should free the tags of
		// both 0 and 1.
		`assert(freed_tag_1 == 1 && freed_tag_2 == 2);
		clk = 0;
		#1;
		
		wakeup_active = 0;
		clk = 1;
		#1;
		// And on this cycle the ROB should free the tag of 2.
		`assert((freed_tag_1 == 3 && freed_tag_2 == 0) || (freed_tag_1 == 0 && freed_tag_2 == 3));
		clk = 0;
		#1;
		
		clk = 1;
		#1;
		`assert(freed_tag_1 == 0 && freed_tag_2 == 0);
		clk = 0;
		#1;
		
		wakeup_active = 1;
		wakeup_rob_index = rob_indices[3];
		clk = 1;
		#1;
		`assert((freed_tag_1 == 4 && freed_tag_2 == 0) || (freed_tag_1 == 0 && freed_tag_2 == 4));
		clk = 0;
		#1;
		
		wakeup_active = 0;
		clk = 1;
		#1;
		`assert(freed_tag_1 == 0 && freed_tag_2 == 0);
		clk = 0;
		#1;
		
		$stop;
	end
endmodule