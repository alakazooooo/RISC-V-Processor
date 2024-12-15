`timescale 1ns/1ps


module LoadStoreQueue (
	input clk,
	input reset,
	input LoadStore, //1=Load/Store, 0=other
	input RegWrite, //1=load, 0=store
	input [5:0] ROB_index, //ROB index of input instruction
	input [5:0] store_rs2_tag, //rs2 tag
	input store_rs2_ready, //rs2 value ready?
	input [31:0] store_rs2_value, //rs2 value of store instr
	input [5:0] load_rd_tag, //rd tag of load instr
	input BMS, //1=byte, 0=word
	
	input [5:0] retire_ROB_index_1, //ROB index of retired instructions
	input [5:0] retire_ROB_index_2,
	
	input FU_1_valid, FU_2_valid, FU_3_valid, //if FU has an output for LSQ (one-hot encoding)
	input [31:0] FU_1_address, //address output by FU
	input [31:0] FU_2_address,
	input [31:0] FU_3_address,
	input [5:0] FU_1_ROB_index, //ROB index corresponding to FU output
	input [5:0] FU_2_ROB_index,
	input [5:0] FU_3_ROB_index,
	
	input wakeup_1_valid, wakeup_2_valid, wakeup_3_valid,
	input [5:0] wakeup_1_tag, wakeup_2_tag, wakeup_3_tag,
	input [31:0] wakeup_1_val, wakeup_2_val, wakeup_3_val,
	input [5:0] wakeup_1_ROB_index, //ROB index corresponding to FU output
	input [5:0] wakeup_2_ROB_index,
	input [5:0] wakeup_3_ROB_index,

	output reg [31:0] forward_rd_value, //load rd value being forwarded
	output reg [5:0] forward_rd_tag, //load rd tag being forwarded
	output reg forward_rd_valid,
	
	output reg [5:0] completed_ROB_index, //ROB index of L/S instructions that should be retired
	output reg completed_valid
	);
	
	//TODO:
	//Inputs and outputs to memory module
	//handling load instruction that can't find matching store value (need to access memory)
	//handling retiring DONE
	//handling LB and SB stuff
	//load LSQ miss (send to memory)
	
	
	parameter LSQ_SIZE = 16;
	parameter LSQ_WIDTH = 124;
	
	reg [LSQ_WIDTH-1:0] LSQ [LSQ_SIZE-1:0];
	reg [4:0] LSQ_count = 0;
	reg [3:0] LSQ_tail = 0;
	wire [3:0] LSQ_head = LSQ_tail >= LSQ_count ? (LSQ_tail - LSQ_count) : (LSQ_SIZE - LSQ_count + LSQ_tail);
	
	reg [3:0] LSQ_update_index; //index of LSQ instruction begin updated
	reg [3:0] index;
	reg [4:0] search_size;

	
	
	integer i, j, FU_num;
	
	
	//FU address forwarding stuff
	wire [2:0] FU_address_valids;
	wire [31:0] FU_addresses [2:0];
	wire [5:0] FU_ROBs [2:0];
	
	assign FU_address_valids[0] = FU_1_valid;
	assign FU_address_valids[1] = FU_2_valid;
	assign FU_address_valids[2] = FU_3_valid;
	
	assign FU_addresses[0] = FU_1_address;
	assign FU_addresses[1] = FU_2_address;
	assign FU_addresses[2] = FU_3_address;
	
	assign FU_ROBs[0] = FU_1_ROB_index;
	assign FU_ROBs[1] = FU_2_ROB_index;
	assign FU_ROBs[2] = FU_3_ROB_index;
	
	
	//wakeup stuff
	wire [5:0] wakeup_tags [2:0];
	wire [31:0] wakeup_vals [2:0];
	wire [2:0] wakeup_valids;
	wire [5:0] wakeup_ROBs [2:0];
	
	assign wakeup_tags[0] = wakeup_1_tag;
	assign wakeup_tags[1] = wakeup_2_tag;
	assign wakeup_tags[2] = wakeup_3_tag;
	
	assign wakeup_vals[0] = wakeup_1_val;
	assign wakeup_vals[1] = wakeup_2_val;
	assign wakeup_vals[2] = wakeup_3_val;
	
	assign wakeup_valids[0] = wakeup_1_valid;
	assign wakeup_valids[1] = wakeup_2_valid;
	assign wakeup_valids[2] = wakeup_3_valid;
	
	assign wakeup_ROBs[0] = wakeup_1_ROB_index;
	assign wakeup_ROBs[1] = wakeup_2_ROB_index;
	assign wakeup_ROBs[2] = wakeup_3_ROB_index;
	
	reg foundStore = 0; //found store that matches load address
	
	
	//memory stuff
	reg [31:0] mem_address;
	reg [31:0] mem_store_value;
	reg mem_BMS;
	reg mem_LS;
	reg mem_valid;
	
	wire [31:0] mem_addr_out;
	wire [31:0] mem_load_value_out;
	wire mem_LS_out;
	wire mem_valid_out;
	
	
	integer p;
	reg [3:0] index3;
	
	integer x, y;
	reg [3:0] index2;
	
	integer m, n, o;
	
	
	//clear LSQ on startup
	initial begin
		for (i = 0; i < LSQ_SIZE; i = i + 1) begin
			LSQ[i] = 0;
		end
	end
	
	
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			for (i = 0; i < LSQ_SIZE; i = i + 1) begin
				LSQ[i] = 0;
			end
			forward_rd_valid = 0;
			completed_valid = 0;
			foundStore = 0;
		end
		else begin
			forward_rd_valid = 0;
			completed_valid = 0;
			foundStore = 0;
			
			//new instruction
			if (LoadStore) begin //add new instruction into 
				LSQ[LSQ_tail][0] = RegWrite; //Load or Store
				LSQ[LSQ_tail][1] = BMS; //Byte or Word
				LSQ[LSQ_tail][2] = 1'b0; //memory ready
				LSQ[LSQ_tail][34:3] = 32'd0; //memory address
				LSQ[LSQ_tail][40:35] = ROB_index;
				LSQ[LSQ_tail][46:41] = store_rs2_tag;
				LSQ[LSQ_tail][47] = store_rs2_ready;
				LSQ[LSQ_tail][79:48] = store_rs2_value;
				LSQ[LSQ_tail][85:80] = load_rd_tag;
				LSQ[LSQ_tail][86] = 0; //rd ready
				LSQ[LSQ_tail][118:87] = 32'd0; //rd value (load)
				LSQ[LSQ_tail][119] = 1'b1; //valid entry
				LSQ[LSQ_tail][120] = 1'b0; //stall
				LSQ[LSQ_tail][121] = 1'b0; //forwarded
				LSQ[LSQ_tail][122] = 1'b0; //complete
				LSQ[LSQ_tail][123] = 1'b0; //complete sent to ROB
				
				LSQ_tail = (LSQ_tail < LSQ_SIZE - 1) ? (LSQ_tail + 4'd1) : 4'd0;
				LSQ_count = LSQ_count + 5'd1;
				
				$display("added instruction to LSQ");
			end
			
			
			//Input FU outputted addresses in LSQ, and search for load values from existing stores
			for (FU_num = 0; FU_num < 3; FU_num = FU_num + 1) begin //check outputs of each FU
				LSQ_update_index = 0;
				if(wakeup_valids[FU_num] || FU_address_valids[FU_num]) begin
					for (i = 0; i < LSQ_SIZE; i = i + 1) begin //search entire LSQ
						if (FU_address_valids[FU_num]) begin //if FU has address for LSQ
							if (LSQ[i][119]) begin
								if (LSQ[i][40:35] == FU_ROBs[FU_num] && LSQ_update_index == 0) begin //Find the right instruction
									LSQ[i][34:3] = FU_addresses[FU_num];
									LSQ[i][2] = 1; //address now valid
									LSQ_update_index = i;
									$display("FORWARDED address from FU to LSQ");
									if (~LSQ[i][0]) begin //STORE
										LSQ[i][122] = 1; //store complete
									end
									else if (LSQ[i][0]) begin //LOAD
										for (j = 0; j < LSQ_SIZE; j = j + 1) begin //search for matching address
											index = (LSQ_head + j) % LSQ_SIZE; //start at head index
											search_size = (LSQ_head < i) ? (i - LSQ_head) : (i + LSQ_SIZE - LSQ_head);
											if(~foundStore && j < search_size && LSQ[index][119]) begin //search from LSQ_head to i
												if (LSQ[index][34:3] == FU_addresses[FU_num] && ~LSQ[index][0]) begin //found matching address store
													if (LSQ[index][47]) begin//if store value ready
														LSQ[i][118:87] = LSQ[index][79:48]; //forward value from store to load
														LSQ[i][86] = 1; //rd ready
														foundStore = 1;
														
														forward_rd_value = LSQ[i][118:87];
														forward_rd_tag = LSQ[i][85:80];
														LSQ[i][121] = 1;
														forward_rd_valid = 1;
														LSQ[i][122] = 1; //load complete
														$display("found matching store, FORWARDING from store to load");
													end
													else begin //need to stall load until value ready
														LSQ[i][120] = 1; //stall flag
														$display("found matching store, STALLING");
													end
													
												end
											end
										end
										if (~foundStore) begin //couldn't find matching store for load
											//SEND TO MEMORY TODO
											$display("LSQ miss, LOAD sent to mem");
										end
									end
								end //end address ROB hit
							end //end if valid
						end //end if wakeup_valid
						//wakeup store rs2 value 
						if (wakeup_valids[FU_num]) begin 
							if (LSQ[i][46:41] == wakeup_tags[FU_num] && LSQ_update_index == 0 && ~LSQ[i][0] && ~LSQ[i][47]) begin
								LSQ_update_index = i;
								LSQ[i][79:48] = wakeup_vals[FU_num];
								LSQ[i][47] = 1;
								$display("WAKEUP store rs2 value");
								for (o = 0; o < LSQ_SIZE; o = o + 1) begin //search for stalled loads
									if (LSQ[o][119] && LSQ[o][0] && LSQ[o][120] && LSQ[o][34:3] == LSQ[m][34:3]) begin
										LSQ[o][118:87] = wakeup_vals[n];
										LSQ[o][86] = 1;
										if (~forward_rd_valid) begin
											forward_rd_value = LSQ[o][118:87];
											forward_rd_tag = LSQ[o][85:80];
											LSQ[o][121] = 1;
											forward_rd_valid = 1;
											LSQ[o][123] = 1; //load complete
											$display("FORWARDING store rs2 to STALLED load");
										end
									end
								end
							end
						end
					end
				end
			end
			
			
			//forward logic
			if (~forward_rd_valid) begin //if haven't forwarded anything yet
			
				for (p = 0; p < LSQ_SIZE; p = p + 1) begin
					index3 = (LSQ_head + p) % LSQ_SIZE; //start at head index
					if (~forward_rd_valid && LSQ[p][119] && LSQ[p][0] && ~LSQ[p][121] && LSQ[p][86]) begin
						forward_rd_value = LSQ[p][118:87];
						forward_rd_tag = LSQ[p][85:80];
						LSQ[p][121] = 1;
						LSQ[p][122] = 1;
					end
				end
			end
			
			
			//completing/retiring instructions

			for (x = 0; x < LSQ_SIZE; x = x + 1) begin //search for matching address
				index2 = (LSQ_head + x) % LSQ_SIZE; //start at head index
				if (x < LSQ_count && LSQ[index2][119]) begin
					if (LSQ[index2][40:35] == retire_ROB_index_1 || LSQ[index2][40:35] == retire_ROB_index_2) begin //found retired LS
						if (LSQ[index2][0]) begin //LOAD
							LSQ[index2] = 0;
							LSQ_count = LSQ_count - 5'd1;
							$display("Retired LOAD");
						end
						else if (~LSQ[index2][0]) begin //STORE
							//SEND TO MEMORY TODO
							$display("Retired STORE and sent to mem");
						end
					end
					if (~completed_valid && LSQ[index2][122] && ~LSQ[index2][123]) begin //found LS that can be completed
						completed_valid = 1;
						completed_ROB_index = LSQ[index2][40:35];
						LSQ[index2][123] = 1;
						$display("sent COMPLETED LS to ROB");
					end
				end
			end
			
			
			
			$display("LSQ Entry 0: %0b", LSQ[0]);
			$display("LSQ Entry 1: %0b", LSQ[1]);
			$display("LSQ Entry 2: %0b", LSQ[2]);
			$display("LSQ Entry 3: %0b", LSQ[3]);
			$display("LSQ Entry 4: %0b", LSQ[4]);
		
		end //not reset end
		
	
	end
	
	
	
	
	
	//Memory access
	
	
	//Memory main_memory(clk, mem_address, mem_store_value, mem_BMS, 
	//						mem_LS, mem_valid, mem_addr_out, mem_load_value_out, 
	//						mem_LS_out, mem_valid_out);
	
	
	
	
	

endmodule