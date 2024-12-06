module ReservationStation_TB(
	input wire test1,
	output reg test
);
    // Clock and reset signals
    reg clk = 0;
    reg reset;
    
    // Input signals
    reg [5:0] physical_rd, physical_rs1, physical_rs2;
    reg rs1_ready, rs2_ready;
    reg [31:0] rs1_value, rs2_value;
    reg [5:0] ROB_num;
    reg [3:0] ALUControl;
    reg [31:0] imm;
    reg LoadStore;
    reg ALUSrc;
    reg FU1_ready, FU2_ready, FU3_ready;
    
    // Output signals
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
    
    // Instantiate the ReservationStation
    ReservationStation rs (
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
    
    // Clock generation
  always begin
    #5 clk = ~clk; 
  end
    
    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        physical_rd = 0;
        physical_rs1 = 0;
        physical_rs2 = 0;
        rs1_ready = 0;
        rs2_ready = 0;
        rs1_value = 0;
        rs2_value = 0;
        ROB_num = 0;
        ALUControl = 0;
        imm = 0;
        LoadStore = 0;
        ALUSrc = 0;
        FU1_ready = 0;
        FU2_ready = 0;
        FU3_ready = 0;
        
        // Wait for 2 clock cycles and release reset
        #20;
        reset = 0;
        
        // Test Case 1: Add instruction
        #10;
        physical_rd = 6'd1;
        physical_rs1 = 6'd2;
        physical_rs2 = 6'd3;
        rs1_ready = 1;
        rs2_ready = 1;
        rs1_value = 32'd10;
        rs2_value = 32'd20;
        ROB_num = 6'd1;
        ALUControl = 4'b0001;  // ADD
        imm = 32'd0;
        LoadStore = 0;
        ALUSrc = 0;
        FU1_ready = 1;
        
        // Test Case 2: Load instruction
        #10;
        physical_rd = 6'd4;
        physical_rs1 = 6'd5;
        rs1_ready = 1;
        rs2_ready = 1;
        rs1_value = 32'd100;
        ROB_num = 6'd2;
        ALUControl = 4'b0010;  // LOAD
        imm = 32'd4;
        LoadStore = 1;
        ALUSrc = 1;
        FU2_ready = 1;
        
        // Test Case 3: Multiple instructions ready to issue
        #10;
        FU1_ready = 1;
        FU2_ready = 1;
        FU3_ready = 1;
        
        // Run for a few more cycles
        #50;
        
        // End simulation
        $finish;
    end
    

    
endmodule
