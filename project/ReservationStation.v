module ReservationStation (
    input wire clk,
	 input wire reset,
    
    // inputs to RS
    input wire [5:0] physical_rd, physical_rs1, physical_rs2,
    input wire rs1_ready, rs2_ready,
    input wire [31:0] rs1_value, rs2_value,
    input wire [5:0] ROB_num,

    //from decode
    input wire [3:0] ALUControl,
    input wire [31:0] imm,
    input wire LoadStore,
    input wire ALUSrc,
    input wire RegWrite,
    input wire BMS,
    
    //forward inputs TODO 
    

    // Issue interface
    output reg [1:0] FU_num,
    output reg load_store_valid,
    output reg [31:0] issue_rs1_value_0, issue_rs1_value_1, issue_rs1_value_2,
    output reg [31:0] issue_rs2_value_0, issue_rs2_value_1, issue_rs2_value_2,
    output reg [2:0] issue_alu_type_0, issue_alu_type_1, issue_alu_type_2,
	 
	 output reg [128:0] current_RS_entry
);

    // Constants
    parameter RS_SIZE = 64;
    parameter ENTRY_WIDTH = 129; 

    // Reservation station
    reg [ENTRY_WIDTH-1:0] reservation_station [RS_SIZE-1:0];
    reg [RS_SIZE-1:0] valid_bitmap;  // Bitmap to track valid entries
    reg [5:0] count;

    integer i, j;
	 
	function [5:0] find_free_slot;
		 input [RS_SIZE-1:0] bitmap;
		 reg [5:0] index;
		 integer i;
	begin
		 index = 6'd63; //assume RS will never be full
		 for (i = 0; i < 64; i = i + 1) begin
			  if (!bitmap[i] && index == 6'd63) begin //if current entry is empty and index has not been assigned yet
					index = i[5:0];
					$display("i=%0d", i);
			  end
		 end
		 find_free_slot = index;
	end
	endfunction
	
	 reg [5:0] free_slot;

    // Reservation station loading and management
    always @(posedge clk or posedge reset) begin
		 if (reset) begin
			  FU_num <= 2'b0;
			  count <= 6'b0;
			  valid_bitmap <= {RS_SIZE{1'b0}};
			  
			  for (j = 0; j < RS_SIZE; j = j + 1) begin
				   reservation_station[j] = 129'b0; // Initialize all entries to zero
			  end
			  
			  // Initialize other variables as needed
		 end else begin		 
			  // Add new instruction 
			  if (count < RS_SIZE && ALUControl != 0) begin
                free_slot = find_free_slot(valid_bitmap);
					 $display("free slot=%0d", free_slot);
                
                reservation_station[free_slot][128] <= 1'b1; // valid
                reservation_station[free_slot][127:124] <= ALUControl;
                reservation_station[free_slot][123:118] <= physical_rd;
                reservation_station[free_slot][117:112] <= physical_rs1;
                reservation_station[free_slot][111:80] <= rs1_value;
                reservation_station[free_slot][79] <= rs1_ready;
                reservation_station[free_slot][78:73] <= physical_rs2;
                reservation_station[free_slot][72:41] <= rs2_value;
                reservation_station[free_slot][40] <= rs2_ready;
                reservation_station[free_slot][39:8] <= imm;
                reservation_station[free_slot][7:6] <= FU_num; //if ls
                reservation_station[free_slot][5:0] <= ROB_num;
					 
					 $display("ALUControl", ALUControl);

                valid_bitmap[free_slot] <= 1'b1;  // Mark the entry as valid
                count <= count + 1;

					
					if(FU_num == 2'd2) begin
						 FU_num =  2'd0;
					end else begin
						 FU_num = FU_num + 2'd1;
					end
					
					
					$display("Reservation Station Entry 0: %0b", reservation_station[0]);
					$display("Reservation Station Entry 1: %0b", reservation_station[1]);
					$display("Reservation Station Entry 2: %0b", reservation_station[2]);
					$display("Reservation Station Entry 3: %0b", reservation_station[3]);
					$display("Reservation Station Entry 4: %0b", reservation_station[4]);
					$display("Reservation Station Entry 5: %0b", reservation_station[5]);
					$display("Reservation Station Entry 6: %0b", reservation_station[6]);
					$display("Reservation Station Entry 7: %0b", reservation_station[7]);
					$display("Reservation Station Entry 8: %0b", reservation_station[8]);
					$display("Reservation Station Entry 9: %0b", reservation_station[9]);
			
			
					//$display("Reservation Station Entry 63: %0b", reservation_station[63]);
					//$display("Reservation Station Entry 62: %0b", reservation_station[62]);
					//$display("Reservation Station Entry 61: %0b", reservation_station[61]);
					
					current_RS_entry <= reservation_station[free_slot];
					
			  end

			  // TODO Remove issued instructions
			  
			  
			  
			  
			  
		 end
	 
	 

    end

    // FU_num and load_store_valid logic (TODO)



endmodule
