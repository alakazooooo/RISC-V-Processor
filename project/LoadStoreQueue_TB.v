`timescale 1ns/1ps

module LoadStoreQueue_TB(
	output [31:0] forward_rd_value,
	output [5:0] forward_rd_tag,
    output forward_rd_valid,

    output [5:0] completed_ROB_index,
    output completed_valid
);

    // Testbench variables and signals
    reg clk;
	 reg reset;
    reg LoadStore;
    reg RegWrite;
    reg [5:0] ROB_index;
    reg [5:0] store_rs2_tag;
    reg store_rs2_ready;
    reg [31:0] store_rs2_value;
    reg [5:0] load_rd_tag;
    reg BMS;
	 
	 reg [5:0] retire_ROB_index_1;
	 reg [5:0] retire_ROB_index_2;
	 
	 reg FU_1_valid, FU_2_valid, FU_3_valid; //if FU has an output for LSQ (one-hot encoding)
	reg [31:0] FU_1_address; //address output by FU
	reg [31:0] FU_2_address;
	reg [31:0] FU_3_address;
	reg [5:0] FU_1_ROB_index; //ROB index corresponding to FU output
	reg [5:0] FU_2_ROB_index;
	reg [5:0] FU_3_ROB_index;

    reg wakeup_1_valid, wakeup_2_valid, wakeup_3_valid;
    reg [5:0] wakeup_1_tag, wakeup_2_tag, wakeup_3_tag;
    reg [31:0] wakeup_1_val, wakeup_2_val, wakeup_3_val;
    reg [5:0] wakeup_1_ROB_index, wakeup_2_ROB_index, wakeup_3_ROB_index;

 
    // Instantiate the DUT
    LoadStoreQueue uut (
        .clk(clk),
        .LoadStore(LoadStore),
        .RegWrite(RegWrite),
        .ROB_index(ROB_index),
        .store_rs2_tag(store_rs2_tag),
        .store_rs2_ready(store_rs2_ready),
        .store_rs2_value(store_rs2_value),
        .load_rd_tag(load_rd_tag),
        .BMS(BMS),
		  .retire_ROB_index_1(retire_ROB_index_1),
		  .retire_ROB_index_2(retire_ROB_index_2),
		  .FU_1_valid(FU_1_valid),
		  .FU_2_valid(FU_2_valid),
		  .FU_3_valid(FU_3_valid),
		  .FU_1_address(FU_1_address),
		  .FU_2_address(FU_2_address),
		  .FU_3_address(FU_3_address),
		  .FU_1_ROB_index(FU_1_ROB_index),
		  .FU_2_ROB_index(FU_2_ROB_index),
		  .FU_3_ROB_index(FU_3_ROB_index),
        .wakeup_1_valid(wakeup_1_valid),
        .wakeup_2_valid(wakeup_2_valid),
        .wakeup_3_valid(wakeup_3_valid),
        .wakeup_1_tag(wakeup_1_tag),
        .wakeup_2_tag(wakeup_2_tag),
        .wakeup_3_tag(wakeup_3_tag),
        .wakeup_1_val(wakeup_1_val),
        .wakeup_2_val(wakeup_2_val),
        .wakeup_3_val(wakeup_3_val),
        .wakeup_1_ROB_index(wakeup_1_ROB_index),
        .wakeup_2_ROB_index(wakeup_2_ROB_index),
        .wakeup_3_ROB_index(wakeup_3_ROB_index),
        .forward_rd_value(forward_rd_value),
        .forward_rd_tag(forward_rd_tag),
        .forward_rd_valid(forward_rd_valid),
        .completed_ROB_index(completed_ROB_index),
        .completed_valid(completed_valid)
    );

    // Clock generation
    always begin
		#5 clk = ~clk;
	 end

    // Test sequence
    initial begin
        // Initialize inputs
		  clk = 0;
		  reset = 0;
        LoadStore = 0;
        RegWrite = 0;
        ROB_index = 0;
        store_rs2_tag = 0;
        store_rs2_ready = 0;
        store_rs2_value = 0;
        load_rd_tag = 0;
        BMS = 0;
		  
		  retire_ROB_index_1 = 0;
		  retire_ROB_index_2 = 0;

		  FU_1_valid = 0;
		  FU_2_valid = 0;
		  FU_3_valid = 0;
		  FU_1_address = 0;
		  FU_2_address = 0;
		  FU_3_address = 0;
		  FU_1_ROB_index = 0;
		  FU_2_ROB_index = 0;
		  FU_3_ROB_index = 0;
		  
        wakeup_1_valid = 0;
        wakeup_2_valid = 0;
        wakeup_3_valid = 0;
        wakeup_1_tag = 0;
        wakeup_2_tag = 0;
        wakeup_3_tag = 0;
        wakeup_1_val = 0;
        wakeup_2_val = 0;
        wakeup_3_val = 0;
        wakeup_1_ROB_index = 0;
        wakeup_2_ROB_index = 0;
        wakeup_3_ROB_index = 0;

        // Wait for reset
        #20;

        // Test case 1: Add a store instruction to the LSQ
		  //SW x3, 4(x0)
        LoadStore = 1;
        RegWrite = 0; // Store
        ROB_index = 6'd4;
        store_rs2_tag = 6'd3;
        store_rs2_ready = 0;
        store_rs2_value = 32'h0;
		  BMS = 0;
        #10;

        //SW x4, 4(x1)
		  //x3 ready
        LoadStore = 1;
        RegWrite = 0; // Store
        ROB_index = 6'd5;
        store_rs2_tag = 6'd4;
        store_rs2_ready = 0;
        store_rs2_value = 32'h0;
		  BMS = 0;
			wakeup_1_valid = 1;
			wakeup_1_val = 32'd10;
			wakeup_1_tag = 6'd3;
			#10;
			
			//LW x2 4(x0)
			LoadStore = 1;
        RegWrite = 1; // Load
        ROB_index = 6'd6;
        store_rs2_tag = 6'd0;
        store_rs2_ready = 0;
        store_rs2_value = 32'h0;
		  load_rd_tag = 6'd2;
		  BMS = 0;
		  wakeup_1_valid = 0;
			wakeup_2_valid = 1;
			wakeup_2_val = 32'd4096;
			wakeup_2_tag = 6'd4;
			FU_3_valid = 1;
			FU_3_address = 32'd4;
			FU_3_ROB_index = 6'd4;
        // Finish simulation
		  #10;
		  
		  //give load it's address (should automatically find store value)
		  LoadStore = 0;
		  FU_1_valid = 1;
			FU_1_address = 32'd4;
			FU_1_ROB_index = 6'd6;
			wakeup_2_valid = 0;
			wakeup_3_valid = 0;
			FU_3_valid = 0;
		 #10
			FU_1_valid = 0;
		  
		  
		  #10;
		  
		  retire_ROB_index_1 = 6'd4;
		  
		  #10;
		  retire_ROB_index_1 = 6'd0;
		  retire_ROB_index_2 = 6'd6;
		  
		  #10;
		  
		  //SB x6, 12(x0)
        LoadStore = 1;
        RegWrite = 0; // Store
        ROB_index = 6'd8;
        store_rs2_tag = 6'd6;
        store_rs2_ready = 0;
        store_rs2_value = 32'h0;
		  BMS = 1;
		  
		  
		  #20;
		  
        $stop;
    end

endmodule
