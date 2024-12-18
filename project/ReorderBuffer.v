`define COMPLETED_PART(row) row[0]
`define OLD_TAG_PART(row) row[6:1]

/*
`define do_wakeup_for(wakeup_num) \
	if (rob_count < ROB_SIZE) begin \
		if (rob_head <= rob_tail) begin \
			if (!(rob_head <= wakeup_``wakeup_num``_rob_index && wakeup_``wakeup_num``_rob_index < rob_tail)) begin \
				$fatal("Got a wakeup at a ROB index outside of the queue bounds (case 1)"); \
			end \
		end else begin \
			if (rob_tail <= wakeup_``wakeup_num``_rob_index && wakeup_``wakeup_num``_rob_index < rob_head) begin \
				$fatal("Got a wakeup at a ROB index outside of the queue bounds (case 2)"); \
			end \
		end \
	end \
	if (`COMPLETED_PART(rob[wakeup_``wakeup_num``_rob_index])) begin \
		$fatal("Got a wakeup for an ROB entry that had already been completed; double-wakeup?"); \
	end \
	`COMPLETED_PART(rob[wakeup_``wakeup_num``_rob_index]) <= 1'b1;
*/
`define do_wakeup_for(wakeup_rob_index) \
	if (rob_count < ROB_SIZE) begin \
		if (rob_head <= rob_tail) begin \
			if (!(rob_head <= wakeup_rob_index && wakeup_rob_index < rob_tail)) begin \
				$fatal("Got a wakeup at a ROB index outside of the queue bounds (case 1)"); \
			end \
		end else begin \
			if (rob_tail <= wakeup_rob_index && wakeup_rob_index < rob_head) begin \
				$fatal("Got a wakeup at a ROB index outside of the queue bounds (case 2)"); \
			end \
		end \
	end \
	if (`COMPLETED_PART(rob[wakeup_rob_index])) begin \
		$fatal("Got a wakeup for an ROB entry that had already been completed; double-wakeup?"); \
	end \
	`COMPLETED_PART(rob[wakeup_rob_index]) <= 1'b1;


// This ROB is simplified compared to a full-featured speculative ROB
// because without jumps and branches, we're just writing values directly to the A-RAT.
// So this doesn't need to control anything about the register values and
// its main purpose is just tracking when we can return tags to the free pool.

// Per the spec, this can retire up to two instructions per cycle.

module ReorderBuffer(
  input clk,
  input reset,
  input enqueue_enable, input [5:0] enqueue_old_tag,
  input wakeup_0_active, wakeup_1_active, wakeup_2_active, wakeup_3_active,
  input [5:0] wakeup_0_rob_index, wakeup_1_rob_index, wakeup_2_rob_index, wakeup_3_rob_index,
  
  // The index where the next entry in the ROB will be located.
  output wire [5:0] next_rob_index,
  // For returning between zero and two tags to Rename's free pool.
  // These will be 0 if not applicable, because Rename should ignore tag p0 being freed anyway.
  output wire [5:0] freed_tag_1, freed_tag_2,
  output wire [5:0] freed_rob_1, freed_rob_2
);
	parameter ROB_SIZE = 7'd64; // per the spec
	
	// The ROB is a circular buffer-backed queue. Elements from head
	// (inclusive) to tail (exclusive), wrapping around, are valid.
	// ROB entries are tuples ([6:1] old destination tag of this instruction, [0:0] is completed)
	reg [6+1-1:0] rob [ROB_SIZE-1:0];
	reg [6:0] rob_count;
	reg [5:0] rob_tail;
	wire [5:0] rob_head = rob_tail >= rob_count ? (rob_tail - rob_count) : (ROB_SIZE - rob_count + rob_tail);
	
	assign next_rob_index = rob_tail;
	
	wire [5:0] rob_next_after_head = (rob_head < ROB_SIZE - 1) ? (rob_head + 6'd1) : 6'd0;
	
	wire [1:0] num_retirable_entries = count_retirable_entries(rob_count, rob[rob_head], rob[rob_next_after_head]);
	
	// Defining a function is a workaround to use case to assign to a wire.
	// https://stackoverflow.com/questions/50766295/using-verilog-case-statement-with-continuous-assignment
	function [1:0] count_retirable_entries(input [6:0] count, input [6+1-1:0] first, second);
	begin
		$display("count, first, second: %0d, %0d, %0d", count, first, second);
		case (count)
			7'd0: count_retirable_entries = 0;
			7'd1: count_retirable_entries = `COMPLETED_PART(first);
			// Entries are retired in order, so the first element must be completed for the second element to be considered.
			default: count_retirable_entries = `COMPLETED_PART(first) + (`COMPLETED_PART(first) && `COMPLETED_PART(second));
		endcase
		$display("Retirable entries: %0d", count_retirable_entries);
	end
	endfunction
	
	assign freed_tag_1 = num_retirable_entries >= 1 ? `OLD_TAG_PART(rob[rob_head]) : 6'd0;
	assign freed_tag_2 = num_retirable_entries >= 2 ? `OLD_TAG_PART(rob[rob_next_after_head]) : 6'd0;
	
	assign freed_rob_1 = num_retirable_entries >= 1 ? rob_head : 6'd0;
	assign freed_rob_2 = num_retirable_entries >= 2 ? rob_next_after_head : 6'd0;
	
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			rob_count <= 0;
			rob_tail <= 0;
			// Resetting the rob entries themselves is not needed because only elements
			// that are between rob_head and rob_tail are looked at.
		end else begin
			if (wakeup_0_active) begin
				`do_wakeup_for(wakeup_0_rob_index)
			end
			if (wakeup_1_active) begin
				`do_wakeup_for(wakeup_1_rob_index)
			end
			if (wakeup_2_active) begin
				`do_wakeup_for(wakeup_2_rob_index)
			end
			if (wakeup_3_active) begin
				`do_wakeup_for(wakeup_3_rob_index)
			end
			
			if (enqueue_enable) begin
				rob[rob_tail] <= {enqueue_old_tag, 1'b0};
				rob_tail <= (rob_tail < ROB_SIZE - 1) ? (rob_tail + 6'd1) : 6'd0;
			end
			rob_count <= rob_count - num_retirable_entries + enqueue_enable;
		end
	end
	
	// Invariants:
	//  - the rob can only have at most ROB_SIZE items.
	always @(posedge clk) begin : check_invariants
		if (rob_count > ROB_SIZE) begin
			$fatal("ROB count invariant failed");
		end
	end
endmodule
