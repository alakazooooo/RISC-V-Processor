module ReservationStation_TB(
	input wire test1,
	output reg test
);
    // Clock and reset signals
  reg clk = 0;
  reg reset;

  // Inputs
  reg [5:0] physical_rd;
  reg [5:0] physical_rs1;
  reg [5:0] physical_rs2;
  reg rs1_ready;
  reg rs2_ready;
  reg [31:0] rs1_value;
  reg [31:0] rs2_value;
  reg [5:0] ROB_num;
  reg [3:0] ALUControl;
  reg [31:0] imm;
  reg LoadStore;
  reg ALUSrc;
  reg FU1_ready, FU2_ready, FU3_ready;
  reg [5:0] wakeup_tag;
  reg [31:0] wakeup_val;

  // Outputs
  wire [1:0] FU_num;
  wire issue_0_is_LS, issue_1_is_LS, issue_2_is_LS;
  wire issue_FU1_valid, issue_FU2_valid, issue_FU3_valid;
  wire [5:0] issue_0_rd_tag, issue_1_rd_tag, issue_2_rd_tag;
  wire issue_0_alusrc, issue_1_alusrc, issue_2_alusrc;
  wire [5:0] issue_0_rob_num, issue_1_rob_num, issue_2_rob_num;
  wire [31:0] issue_0_rs1_val, issue_1_rs1_val, issue_2_rs1_val;
  wire [31:0] issue_0_rs2_val, issue_1_rs2_val, issue_2_rs2_val;
  wire [31:0] issue_0_imm, issue_1_imm, issue_2_imm;
  wire [3:0] issue_0_alu_type, issue_1_alu_type, issue_2_alu_type;

  // Instantiate the Reservation Station module
  ReservationStation uut (
    .clk(clk),
    .reset(reset),
    .physical_rd(physical_rd),
    .physical_rs1(physical_rs1),
    .physical_rs2(physical_rs2),
    .rs1_ready(rs1_ready),
    .rs2_ready(rs2_ready),
    .rs1_value(rs1_value),
    .rs2_value(rs2_value),
    .ROB_num(ROB_num),
    .ALUControl(ALUControl),
    .imm(imm),
    .LoadStore(LoadStore),
    .ALUSrc(ALUSrc),
    .FU1_ready(FU1_ready),
    .FU2_ready(FU2_ready),
    .FU3_ready(FU3_ready),
    .wakeup_tag(wakeup_tag),
    .wakeup_val(wakeup_val),

    // Outputs
    .FU_num(FU_num),
    .issue_0_is_LS(issue_0_is_LS), 
    .issue_1_is_LS(issue_1_is_LS), 
    .issue_2_is_LS(issue_2_is_LS), 
    .issue_FU1_valid(issue_FU1_valid), 
    .issue_FU2_valid(issue_FU2_valid), 
    .issue_FU3_valid(issue_FU3_valid), 
    .issue_0_rd_tag(issue_0_rd_tag), 
    .issue_1_rd_tag(issue_1_rd_tag), 
    .issue_2_rd_tag(issue_2_rd_tag), 
    .issue_0_alusrc(issue_0_alusrc), 
    .issue_1_alusrc(issue_1_alusrc), 
    .issue_2_alusrc(issue_2_alusrc), 
    .issue_0_rob_num(issue_0_rob_num), 
    .issue_1_rob_num(issue_1_rob_num), 
    .issue_2_rob_num(issue_2_rob_num), 
    .issue_0_rs1_val(issue_0_rs1_val), 
    .issue_1_rs1_val(issue_1_rs1_val), 
    .issue_2_rs1_val(issue_2_rs1_val), 
    .issue_0_rs2_val(issue_0_rs2_val), 
    .issue_1_rs2_val(issue_1_rs2_val), 
    .issue_2_rs2_val(issue_2_rs2_val), 
    .issue_0_imm(issue_0_imm), 
    .issue_1_imm(issue_1_imm), 
    .issue_2_imm(issue_2_imm), 
  	 .issue_0_alu_type(issue_0_alu_type),
	 .issue_1_alu_type(issue_1_alu_type),
	 .issue_2_alu_type(issue_2_alu_type)
  	);

   always begin
     #5 clk = ~clk; 
   end
	

   // Test procedure
   initial begin
     // Initialize inputs
     reset = 1; // Assert reset
     #10; // Wait one clock cycle

     reset = 0; // Deassert reset

     // Test Case 1 - Issue an ALU operation
     physical_rd = 6'd10; // Destination register tag
     physical_rs1 = 6'd11; // Source register tag (RS1)
     physical_rs2 = 6'd12; // Source register tag (RS2)
     rs1_ready = 1; // RS1 is ready
     rs2_ready = 1; // RS2 is ready
     rs1_value = 32'h00000001; // Value of RS1
     rs2_value = 32'h00000002; // Value of RS2
     ROB_num = 6'd15; // ROB entry number
     ALUControl = 4'b0010; // ALU operation code (e.g., ADD)
     imm = 32'h00000000; // No immediate value used here
     LoadStore = 0; // Not a load/store operation
     ALUSrc = 0; // Use registers as sources
     FU1_ready = 1; FU2_ready = 0; FU3_ready = 0; // Only FU1 is ready

     #10; // Wait for one clock cycle

     // Test Case - Issue a Load operation
     physical_rd = 6'd20; // Destination register tag for load
     physical_rs1 = 6'd21; // Source register tag (RS)
     rs1_ready = 1; // RS is ready for load operation
     rs1_value = 32'h00000003; // Value of RS for load operation
     LoadStore = 1; // This is a load operation
	  FU1_ready = 0; FU2_ready = 0; FU3_ready = 1;

     #10;

     // Test Case - Issue another ALU operation with different values
     physical_rd = 6'd30; 
     physical_rs1 = 6'd31; 
     rs1_ready = 0; // RS is not ready to simulate dependency
     rs2_ready = 1; 
     rs2_value =32'h00000004;  
	  FU1_ready = 1; FU2_ready = 1; FU3_ready = 1;
     
      #20;

      $finish; // End simulation after tests are done.
   end

endmodule
