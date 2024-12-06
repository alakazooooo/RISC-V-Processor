`timescale 1ns/1ps


module LoadStoreQueue (
	input clk,
	input LoadStore, //1=Load/Store, 0=other
	input RegWrite, //1=load, 0=store
	input [5:0] ROB_index, //ROB index of input instruction
	input [31:0] store_rs2_value, //rs1 value of store instr
	input [5:0] load_rd_tag, //rd tag of load instr
	input BMS, //1=byte, 0=word
	
	input FU_output, //if FU has an output for LSQ
	input [31:0] FU_address, //address output by FU
	input [5:0] FU_ROB_index, //ROB index corresponding to FU output
	
	input [5:0] retire_ROB_index, //ROB index of retired
	
	output [31:0] forward_rd_value, //load rd value being forwarded
	output [5:0] forward_rd_tag //load rd tag being forwarded
);

	
	parameter LSQ_SIZE = 16;
	parameter LSQ_WIDTH = 112; //todo
	
	reg [LSQ_WIDTH-1:0] LSQ [LSQ_SIZE-1:0];
	reg [4:0] LSQ_count = 0;
	reg [3:0] LSQ_tail = 0;
	wire [3:0] LSQ_head = LSQ_tail >= LSQ_count ? (LSQ_tail - LSQ_count) : (LSQ_SIZE - LSQ_count + LSQ_tail);
	
	reg [LSQ_WIDTH-1:0] LSQ_input = (LSQ_WIDTH)'d0;
	reg [3:0] LSQ_update_index; //index of LSQ instruction begin updated
	reg [3:0] index;
	reg [4:0] search_size;
	
	integer i, j;
	
	always @ (posedge clk) begin
		if (LoadStore) begin //add new instruction into LSQ
			LSQ[LSQ_tail][0] <= RegWrite; //Load or Store
			LSQ[LSQ_tail][1] <= BMS; //Byte or Word
			LSQ[LSQ_tail][2] <= 0; //memory ready
			LSQ[LSQ_tail][34:3] <= 32'd0; //memory address
			LSQ[LSQ_tail][40:35] <= ROB_index;
			LSQ[LSQ_tail][72:41] <= store_rs2_value;
			LSQ[LSQ_tail][78:73] <= load_rd_tag;
			LSQ[LSQ_tail][79] <= 0; //rd ready
			LSQ[LSQ_tail][111:80] <= 32'd0; //rd value (load)
			
			LSQ_tail <= (LSQ_tail < LSQ_SIZE - 1) ? (LSQ_tail + 4'd1) : 4'd0;
			LSQ_count <= LSQ_count + 1;
		end
		
		if (FU_output) begin //if FU has address for LSQ
			LSQ_update_index = 0;
			for (i = 0; i < LSQ_SIZE; i = i + 1) begin //search entire LSQ
				if (LSQ[i][40:35] == FU_ROB_index && LSQ_update_index == 0) begin //Find the right instruction
					LSQ[i][34:3] <= FU_address;
					LSQ[i][2] <= 1; //address now valid
					LSQ_update_index = i;
					
					if (LSQ[i][0]) begin //Load
						for (j = 0; j < LSQ_SIZE; j = j + 1) begin //search for matching address
							index = (LSQ_head + j) % LSQ_SIZE;
							search_size = (LSQ_head < i) ? (i - LSQ_head) : (i + LSQ_size - LSQ_head);
							if(j < search_size) begin //search from LSQ_head to i
								if (LSQ[j][34:3] == FU_address && ~LSQ[j][0]) begin //found matching address store
									LSQ[i][111:80] = LSQ[j][72:41]; //forward value from store to load
									LSQ[i][79] = 1; //rd ready
									
									forward_rd_value = LSQ[j][72:41]; //forwarded rd value
									forward_rd_tag = LSQ[i][78:73]; //forwarded rd tag
								end
							end
						end
					end
				end
			end
		end
	
	end
	
	
	

endmodule