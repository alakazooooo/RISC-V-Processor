module ReservationStation (
    input wire clk,
    input wire reset,
    
    // inputs to RS
    input wire [5:0] physical_rd, physical_rs1, physical_rs2,
    input wire rs1_ready, rs2_ready,
    input wire [31:0] rs1_value, rs2_value,
    input wire [5:0] ROB_num,
    input wire load_into_RS,

    //from decode
    input wire [3:0] ALUControl,
    input wire [31:0] imm,
    input wire LoadStore,
    input wire ALUSrc,
    // input wire RegWrite,
    // input wire BMS,

    //from FU
    input wire FU1_ready, FU2_ready, FU3_ready,

    //forward inputs and wakeup
    input wire wakeup_1_valid, wakeup_2_valid, wakeup_3_valid, wakeup_4_valid,
	input wire [5:0] wakeup_1_tag, wakeup_2_tag, wakeup_3_tag, wakeup_4_tag,
	input wire [31:0] wakeup_1_val, wakeup_2_val, wakeup_3_val, wakeup_4_val,

    // Issue interface
    output reg [1:0] FU_num,
    output reg issue_0_is_LS, issue_1_is_LS, issue_2_is_LS,
    output reg issue_FU1_valid, issue_FU2_valid, issue_FU3_valid,
    output reg [5:0] issue_0_rd_tag, issue_1_rd_tag, issue_2_rd_tag,
    output reg issue_0_alusrc, issue_1_alusrc, issue_2_alusrc,
    output reg [5:0] issue_0_rob_num, issue_1_rob_num, issue_2_rob_num,
    output reg [31:0] issue_0_rs1_val, issue_1_rs1_val, issue_2_rs1_val,
    output reg [31:0] issue_0_rs2_val, issue_1_rs2_val, issue_2_rs2_val,
    output reg [31:0] issue_0_imm, issue_1_imm, issue_2_imm,
    output reg [3:0] issue_0_alu_type, issue_1_alu_type, issue_2_alu_type
);

    parameter RS_SIZE = 64;
    parameter ENTRY_WIDTH = 131;

    reg [ENTRY_WIDTH-1:0] reservation_station [RS_SIZE-1:0];
    reg [RS_SIZE-1:0] valid_bitmap;
    reg [5:0] count;
    reg [5:0] free_slot;
    reg [ENTRY_WIDTH-1:0] entry;
    reg [1:0] issue_counter;
    reg [2:0] fu_ready; //problems?
    reg entry_fu_ready;
    reg [2:0] issue_FU_valid;
	 reg [23:0] wakeup_tags;
    reg [127:0] wakeup_vals;
    reg [3:0] wakeup_valids;

    integer i, j, k, m;

    // Find first empty slot in reservation station
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

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            {FU_num, count, valid_bitmap, issue_counter} <= 0;
            {issue_FU1_valid, issue_FU2_valid, issue_FU3_valid} <= 0;
            issue_FU_valid <= 0;
				fu_ready <= 3'b000;
				wakeup_tags <= 0;
            wakeup_vals <= 0;
				wakeup_valids <= 0;
            
            for (j = 0; j < RS_SIZE; j = j + 1) begin
                reservation_station[j] <= 0;
            end

        end else begin
				
            fu_ready = {FU3_ready, FU2_ready, FU1_ready};

            // Add new instruction
	    if (count < RS_SIZE && ALUControl != 0 && load_into_RS) begin
                free_slot = find_free_slot(valid_bitmap);
                
                // Update FU_num based on ready status

                // old implementation (flawed)
                // If FU1 is ready, assign FU_num = 0
                // Else if FU2 is ready, assign FU_num = 1
                // Else if FU3 is ready, assign FU_num = 2
                // Else increment FU_num (with wraparound at 2)
                // FU_num <= FU1_ready ? 2'd0 :
                //          FU2_ready ? 2'd1 :
                //          FU3_ready ? 2'd2 :
                //          (FU_num == 2'd2) ? 2'd0 : FU_num + 2'd1;

                // FU assignment logic with priority-based skipping
                // For each current FU, try to assign to next sequential FU, unless it's occupied
                // If next FU not ready, try the one after, if none ready, assign the next one
                case (FU_num)
                    2'd0: FU_num = (FU2_ready) ? 2'd1 : (FU3_ready) ? 2'd2 : (FU1_ready) ? 2'd0 : 2'd1;
                    2'd1: FU_num = (FU3_ready) ? 2'd2 : (FU1_ready) ? 2'd0 : (FU2_ready) ? 2'd1 : 2'd2;
                    2'd2: FU_num = (FU1_ready) ? 2'd0 : (FU2_ready) ? 2'd1 : (FU3_ready) ? 2'd2 : 2'd0;
                endcase

                // Create new reservation station entry
                reservation_station[free_slot] = {
                    1'b1,           // valid 130
                    LoadStore,      // is load/store 129
                    ALUSrc,         // alu_src 128
                    ALUControl,     // alu_control 127:124
                    physical_rd,    // rd_tag 123:118
                    physical_rs1,   // rs1_tag 117:112
                    rs1_value,      // rs1_value 111:80
                    rs1_ready,      // rs1_ready 79
                    physical_rs2,   // rs2_tag 78:73
                    rs2_value,      // rs2_value 72:41
                    rs2_ready,      // rs2_ready 40
                    imm,            // immediate 39:8
                    FU_num,         // FU_num 7:6
                    ROB_num         // ROB_num 5:0
                };

                valid_bitmap[free_slot] = 1'b1;
                count = count + 1;
					 
            end

            $display("Adding new instruction:");
			$display("  Free slot: %0d", free_slot);
            $display("  ALUControl: %0h", ALUControl);
            $display("  FU_num: %0d", FU_num);
            $display("  RS1: tag=%0d value=%0h ready=%0b", physical_rs1, rs1_value, rs1_ready);
            $display("  RS2: tag=%0d value=%0h ready=%0b", physical_rs2, rs2_value, rs2_ready);
					 
            $display("before issue");
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
				

            // Wakeup logic
            for (m = 0; m < RS_SIZE; m = m + 1) begin
                entry = reservation_station[m];
                
                
                // Assign values
                wakeup_tags = {wakeup_1_tag, wakeup_2_tag, wakeup_3_tag, wakeup_4_tag};
                wakeup_vals = {wakeup_1_val, wakeup_2_val, wakeup_3_val, wakeup_4_val};
                wakeup_valids = {wakeup_1_valid, wakeup_2_valid, wakeup_3_valid, wakeup_4_valid};
                
                // Check all wakeup tags for both rs1 and rs2
                for (i = 0; i < 4; i = i + 1) begin
                    // RS2 wakeup
		    if (entry[40] == 0 && entry[78:73] == wakeup_tags[i*6 +: 6] && wakeup_valids[i]) begin
                        //if (entry[40]) $fatal("Waking up a register marked ready, something is wrong!");
                        reservation_station[m] = {
                            entry[130:73],    // Keep other fields intact
                            wakeup_vals[i*32 +: 32],   // Update rs2_value
                            1'b1,             // Set rs2_ready to 1
                            entry[39:0]       // Keep remaining fields intact
                        };
                    end
                    
                    // RS1 wakeup
		    if (entry[79] == 0 && entry[117:112] == wakeup_tags[i*6 +: 6] && wakeup_valids[i]) begin
                        //if (entry[79]) $fatal("Waking up a register marked ready, something is wrong!");
                        reservation_station[m] = {
                            entry[130:112],   // Keep other fields intact for rs1
                            wakeup_vals[i*32 +: 32],   // Update rs1_value
                            1'b1,             // Set rs1_ready to 1
                            entry[78:0]      // Keep remaining fields intact
                        };
                    end
                end
            end
				

            // Issue logic
            issue_counter = 0;
            issue_FU_valid = 0;

            for (k = 0; k < RS_SIZE; k = k + 1) begin
                entry = reservation_station[k];
                entry_fu_ready = fu_ready[entry[7:6]];

                if (entry[130] && entry[79] && entry[40] && entry_fu_ready) begin  // Valid entry with ready operands
						  case(entry[7:6]) // issue based on FU_num
								2'd0: begin
                            {issue_0_is_LS, issue_0_alusrc, issue_0_alu_type, issue_0_rd_tag,
                             issue_0_rs1_val, issue_0_rs2_val, issue_0_imm, issue_0_rob_num} = {
                                entry[129], entry[128], entry[127:124], entry[123:118],
                                entry[111:80], entry[72:41], entry[39:8], entry[5:0]
                            };
                            reservation_station[k] = 0; // delete issued instructions
                            valid_bitmap[k] = 0;
                            count = count - 1;
                            issue_FU_valid[entry[7:6]] = 1; //indicate new FU execution needed
									 fu_ready[entry[7:6]] = 0; //newly issued instruction FU no longer ready
                        end
                        2'd1: begin
                            {issue_1_is_LS, issue_1_alusrc, issue_1_alu_type, issue_1_rd_tag,
                             issue_1_rs1_val, issue_1_rs2_val, issue_1_imm, issue_1_rob_num} = {
                                entry[129], entry[128], entry[127:124], entry[123:118],
                                entry[111:80], entry[72:41], entry[39:8], entry[5:0]
                            };
                            reservation_station[k] = 0; // delete issued instructions
                            valid_bitmap[k] = 0;
                            count = count - 1;
                            fu_ready[entry[7:6]] = 0; //newly issued instruction FU no longer ready
                            issue_FU_valid[entry[7:6]] = 1; //indicate new FU execution needed
                        end
                        2'd2: begin
                            {issue_2_is_LS, issue_2_alusrc, issue_2_alu_type, issue_2_rd_tag,
                             issue_2_rs1_val, issue_2_rs2_val, issue_2_imm, issue_2_rob_num} = {
                                entry[129], entry[128], entry[127:124], entry[123:118],
                                entry[111:80], entry[72:41], entry[39:8], entry[5:0]
                            };
                            reservation_station[k] = 0; // delete issued instructions
                            valid_bitmap[k] = 0;
                            count = count - 1;
                            fu_ready[entry[7:6]] = 0; //newly issued instruction FU no longer ready
                            issue_FU_valid[entry[7:6]] = 1; //indicate new FU execution needed
                        end
                        // if more than three valid instructions to issue, ignore the rest
                    endcase
                end
            end

            {issue_FU3_valid, issue_FU2_valid, issue_FU1_valid} = issue_FU_valid;
            // 0 doens't necessarily means the FU is free (could be in process of previous long execution) just means no new issue
			// 1 means it should be used next CC  
			// there might be some junk issue values but it should only be considered if valid is flagged 1



            $display("after issue");
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
				
			// debug
            $display("\n=== Output Signals at Time %0t ===", $time);
            
            $display("\nFunctional Unit Status:");
            $display("  FU_num: %0d", FU_num);
            $display("  FU Valid: FU1=%b FU2=%b FU3=%b", issue_FU1_valid, issue_FU2_valid, issue_FU3_valid);
            
            $display("\nIssue Slot 0:");
            $display("  Load/Store: %b", issue_0_is_LS);
            $display("  RD Tag: %0d", issue_0_rd_tag);
            $display("  ALU Src: %b", issue_0_alusrc);
            $display("  ROB Num: %0d", issue_0_rob_num);
            $display("  RS1 Value: %h", issue_0_rs1_val);
            $display("  RS2 Value: %h", issue_0_rs2_val);
            $display("  Immediate: %h", issue_0_imm);
            $display("  ALU Type: %h", issue_0_alu_type);
				  
            $display("\nIssue Slot 1:");
            $display("  Load/Store: %b", issue_1_is_LS);
            $display("  RD Tag: %0d", issue_1_rd_tag);
            $display("  ALU Src: %b", issue_1_alusrc);
            $display("  ROB Num: %0d", issue_1_rob_num);
            $display("  RS1 Value: %h", issue_1_rs1_val);
            $display("  RS2 Value: %h", issue_1_rs2_val);
            $display("  Immediate: %h", issue_1_imm);
            $display("  ALU Type: %h", issue_1_alu_type);
            
            $display("\nIssue Slot 2:");
            $display("  Load/Store: %b", issue_2_is_LS);
            $display("  RD Tag: %0d", issue_2_rd_tag);
            $display("  ALU Src: %b", issue_2_alusrc);
            $display("  ROB Num: %0d", issue_2_rob_num);
            $display("  RS1 Value: %h", issue_2_rs1_val);
            $display("  RS2 Value: %h", issue_2_rs2_val);
            $display("  Immediate: %h", issue_2_imm);
            $display("  ALU Type: %h", issue_2_alu_type);
            
            $display("\n==============================\n");
				
        end
    end
endmodule
