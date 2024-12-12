`define PHYSICAL_REGISTER_PART(row) row[38:33]
`define READY_PART(row) row[0]
`define VALUE_PART(row) row[32:1]

module Rename(
  input clk,
  input reset,
  input wakeup_active,
  input [5:0] wakeup_tag,
  input [31:0] wakeup_value,
  // These inputs are ignored if they are 0. First because we want tag 0 to be exclusively
  // mapped-to by x0, and second because ReorderBuffer uses 0 to mean "not applicable" i.e.
  // not actually freed on this cycle.
  input [5:0] freed_tag_1, freed_tag_2,
  input [4:0] architectural_rd, architectural_rs1, architectural_rs2,

  output wire [5:0] physical_rd, physical_rs1, physical_rs2,
  // The values of rs1 and rs2, if they are present in the ARAT.
  // If rs1_ready (resp. rs2_ready) is 0, its value is not known by Rename yet;
  // it should be broadcasted from the FUs on a future cycle.
  output wire rs1_ready, rs2_ready,
  output wire [31:0] rs1_value, rs2_value
);
	parameter FREE_POOL_SIZE = 6'd32;
	parameter NUM_ARCHITECTURAL_REGISTERS = 6'd32;
	
   // The free pool is a stack of between 0 and 32 physical register names.
	// Initially it holds all 32 physical register names that are not in the initial A-RAT.
	reg [5:0] free_pool [FREE_POOL_SIZE-1:0];
	reg [$clog2(FREE_POOL_SIZE+1)-1:0] free_pool_count;
	
	// The A-RAT maps each architectural register to the tuple
	// ([38:33] most recent physical register, [32:1] value, [0:0] is ready)
	// where "is ready" means whether the value is up-to-date or if it's still pending broadcast from a FU.
	reg [6+32+1-1:0] arat [31:0];
	
	assign physical_rs1 = `PHYSICAL_REGISTER_PART(arat[architectural_rs1]);
	assign physical_rs2 = `PHYSICAL_REGISTER_PART(arat[architectural_rs2]);
	assign physical_rd = architectural_rd == 0 ? 6'd0 : free_pool[free_pool_count - 6'd1];
	
	wire wakeup_is_rs1 = wakeup_active && wakeup_tag == physical_rs1;
	wire wakeup_is_rs2 = wakeup_active && wakeup_tag == physical_rs2;
	
	assign rs1_ready = `READY_PART(arat[architectural_rs1]) || wakeup_is_rs1;
	assign rs2_ready = `READY_PART(arat[architectural_rs2]) || wakeup_is_rs2;
	assign rs1_value = !rs1_ready
	                     ? 32'hffffffff
								: (wakeup_is_rs1
								    ? wakeup_value
									 : `VALUE_PART(arat[architectural_rs1]));
	assign rs2_value = !rs2_ready
	                     ? 32'hffffffff
								: (wakeup_is_rs2
								    ? wakeup_value
									 : `VALUE_PART(arat[architectural_rs2]));
	
	always @(posedge clk or posedge reset) begin : clk_handler
		integer j;
		
		if (reset) begin : reset_handler
			reg [5:0] i;
			reg [5:0] j;
			for (i = 0; i < FREE_POOL_SIZE; i = i + 6'd1) begin
				// The initial A-RAT maps xN to pN for all 0 <= N <= 31, so the free pool starts at 32.
				free_pool[i] = NUM_ARCHITECTURAL_REGISTERS + i;
			end
			free_pool_count = FREE_POOL_SIZE;
			
			for (j = 0; j < NUM_ARCHITECTURAL_REGISTERS; j = j + 6'd1) begin
				arat[j] = {j, 32'd0, 1'b1};
			end
		end else begin
			// Invariant check: you can't double-free a tag.
			// The i < FREE_POOL_SIZE is to pass synthesis because it thinks free_pool_count could
			// range to larger than the size of free_pool.
			for (j = 0; j < free_pool_count && j < FREE_POOL_SIZE; j = j + 1) begin
				if (free_pool[j] == freed_tag_1 && freed_tag_1 != 0) begin
					$fatal("freed_tag_1 was already freed; cannot double-free a tag.");
				end
				if (free_pool[j] == freed_tag_2 && freed_tag_2 != 0) begin
					$fatal("freed_tag_2 was already freed; cannot double-free a tag.");
				end
			end
			
			// An optimization (irrelevant to the project) would be to count the effect of adding freed tags
			// *before* allocating a free tag for architectural_rd in the same cycle.
			if (architectural_rd != 0) begin
				if (free_pool_count == 0) begin
					// The spec tells us we can assume rename never stalls. So if the free pool
					// gets empty, we were either fed a bad instruction sequence or there's a bug.
					$fatal("Rename needs a physical register but the free pool is empty.");
				end
				`PHYSICAL_REGISTER_PART(arat[architectural_rd]) <= free_pool[free_pool_count - 1];
				`READY_PART(arat[architectural_rd]) <= 1'b0;
			end
			
			if (freed_tag_1 != 0) begin
				// Be careful to count the effect of a possible previous pop from the free pool.
				free_pool[free_pool_count - (architectural_rd != 0)] <= freed_tag_1;
			end
			if (freed_tag_2 != 0) begin
				// Here too; there was a possible previous pop and a possible previous push.
				free_pool[free_pool_count + (freed_tag_1 != 0) - (architectural_rd != 0)] <= freed_tag_2;
			end
			free_pool_count <= free_pool_count + (freed_tag_1 != 0) + (freed_tag_2 != 0) - (architectural_rd != 0);
			
			if (wakeup_active) begin : handle_wakeup
				integer i;
				// Be careful to start the for-loop at 1 because we want x0 to always have a value of 0.
				// Broadcasts to register p0 should have no effect.
				for (i = 1; i < NUM_ARCHITECTURAL_REGISTERS; i = i + 1) begin
					if (`PHYSICAL_REGISTER_PART(arat[i]) == wakeup_tag) begin
						if (`READY_PART(arat[i])) begin
							$fatal("Got a wakeup for a register that had already been woken up; double-wakeup?");
						end
						`VALUE_PART(arat[i]) <= wakeup_value;
						`READY_PART(arat[i]) <= 1'b1;
					end
				end
				// It's OK if no A-RAT entry gets updated; the broadcast might be for a
				// physical register that we already have moved past in the A-RAT. In that case all
				// instructions that would reference the old tag have already left Rename and
				// are waiting in the reservation station, so when the reservation station
				// picks up the broadcast everyone who needs the value will get it.
			end
		end
	end
	
	// Invariants:
	//  - no physical register should be mapped-to in the A-RAT and also be in the free pool.
	//  - the free pool stack can only have at most FREE_POOL_SIZE items.
	//  - p0 is not in the free pool.
	always @(posedge clk) begin : check_invariants
		integer i;
		integer j;
		if (free_pool_count > FREE_POOL_SIZE) begin
			$fatal("Free pool count invariant failed");
		end
		// The i < FREE_POOL_SIZE is to pass synthesis because it thinks free_pool_count could
		// range to larger than the size of free_pool.
		for (i = 0; i < free_pool_count && i < FREE_POOL_SIZE; i = i + 1) begin
			for (j = 0; j < NUM_ARCHITECTURAL_REGISTERS; j = j + 1) begin
				if (free_pool[i] == `PHYSICAL_REGISTER_PART(arat[j])) begin
					$fatal("Rename invariant failed: a physical register is in both the RAT and the free pool.");
				end
			end
			if (free_pool[i] == 0) begin
				$fatal("Rename invariant failed: tag 0 should not be in the free pool");
			end
		end
	end
	
endmodule
