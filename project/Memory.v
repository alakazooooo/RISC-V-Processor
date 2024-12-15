`timescale 1ns/1ps


module Memory (
	input clk,
	input reset,
	input [31:0] address,
	input [31:0] store_value,
	input BMS,
	input load_store, //load = 1, store = 0
	input valid_in,
	
	output reg [31:0] address_out,
	output reg [31:0] load_value_out,
	output reg load_store_out,
	output reg valid_out

);

	parameter MEMORY_SIZE = 1024;
	
	reg [7:0] main_memory [MEMORY_SIZE - 1:0]; //4 GB memory
	
	reg [31:0] address_pipe [0:9];      // Pipeline for delayed addresses
    reg [31:0] store_data_pipe [0:9];   // Pipeline for delayed write data
    reg load_store_pipe [0:9];
	 reg BMS_pipe [0:9];
	 reg valid_pipe [0:9];

    integer i;
	 
	 initial begin
		for (i = 0; i < 10; i = i + 1) begin
			address_pipe[i] <= 0;
			store_data_pipe[i] <= 0;
			load_store_pipe[i] <= 0;
			BMS_pipe[i] <= 0;
			valid_pipe[i] <= 0;
		end
	 end
	
	
	always @ (posedge clk) begin
		//shift pipeline 
		for (i = 9; i > 0; i = i - 1) begin
			address_pipe[i] <= address_pipe[i-1];
			store_data_pipe[i] <= store_data_pipe[i-1];
			load_store_pipe[i] <= load_store_pipe[i-1];
			BMS_pipe[i] <= BMS_pipe[i-1];
			valid_pipe[i] <= valid_pipe[i-1];
	  end

	
		//add new load/store
		if (valid_in) begin
			address_pipe[0] <= address;
			load_store_pipe[0] <= load_store;
			BMS_pipe[0] <= BMS;
			valid_pipe[0] <= 1;
			if (load_store) begin //LOAD
				store_data_pipe[0] <= 0;
			end
			else if (~load_store) begin //STORE
				store_data_pipe[0] <= store_value;
			end
		end
		else if (~valid_in) begin
			address_pipe[0] <= 0;
			store_data_pipe[0] <= 0;
			load_store_pipe[0] <= 0;
			BMS_pipe[0] <= 0;
			valid_pipe[0] <= 0;
		end
		
		//perform actual memory action
		if(valid_pipe[9]) begin
			address_out <= address_pipe[9];
			load_store_out <= load_store_pipe[9];
			valid_out <= 1;
			if(load_store_pipe[9]) begin //perform LOAD
				$display("Memory READ");
				if(BMS_pipe[9]) begin
					load_value_out <= main_memory[address_pipe[9]];
				end else begin
					load_value_out <= {main_memory[address_pipe[9]+3], main_memory[address_pipe[9]+2], main_memory[address_pipe[9]+1], main_memory[address_pipe[9]]};
				end
				
			end
			else if (~load_store_pipe[9]) begin //perform STORE
				main_memory[address_pipe[9]] <= store_data_pipe[9][7:0];
				main_memory[address_pipe[9]+1] <= store_data_pipe[9][15:8];
				main_memory[address_pipe[9]+2] <= store_data_pipe[9][23:16];
				main_memory[address_pipe[9]+3] <= store_data_pipe[9][31:24];
				$display("Memory WRITE");
			end
		
		end
		else begin
			address_out <= 0;
			load_value_out <= 0;
			load_store_out <= 0;
			valid_out <= 0;
		end
	
	end

endmodule