
`timescale 1ns / 1ps

module ReservationStation_TB(output reg test);

    // Inputs
    reg clk = 0;
    reg reset;
    reg [5:0] physical_rd, physical_rs1, physical_rs2;
    reg rs1_ready, rs2_ready;
    reg [31:0] rs1_value, rs2_value;
    reg [5:0] ROB_num;
    reg [3:0] ALUControl;
    reg [31:0] imm;
    reg LoadStore, ALUSrc, RegWrite, BMS;

    // Outputs
    wire [1:0] FU_num;
    wire load_store_valid;
    wire [31:0] issue_rs1_value_0, issue_rs1_value_1, issue_rs1_value_2;
    wire [31:0] issue_rs2_value_0, issue_rs2_value_1, issue_rs2_value_2;
    wire [2:0] issue_alu_type_0, issue_alu_type_1, issue_alu_type_2;
    wire [128:0] current_RS_entry;

    // Instantiate the Unit Under Test (UUT)
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
        .RegWrite(RegWrite),
        .BMS(BMS),
        .FU_num(FU_num),
        .load_store_valid(load_store_valid),
        .issue_rs1_value_0(issue_rs1_value_0),
        .issue_rs1_value_1(issue_rs1_value_1),
        .issue_rs1_value_2(issue_rs1_value_2),
        .issue_rs2_value_0(issue_rs2_value_0),
        .issue_rs2_value_1(issue_rs2_value_1),
        .issue_rs2_value_2(issue_rs2_value_2),
        .issue_alu_type_0(issue_alu_type_0),
        .issue_alu_type_1(issue_alu_type_1),
        .issue_alu_type_2(issue_alu_type_2),
        .current_RS_entry(current_RS_entry)
    );

	 
	 always begin
		  #5 clk = ~clk;
	 end
	 

    // Test scenario
    initial begin
        // Initialize inputs
        reset = 0;
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
        RegWrite = 0;
        BMS = 0;

        // Apply reset
        #10 reset = 1;
        #10 reset = 0;

        // Test case 1
        #10;
        physical_rd = 6'd1;
        physical_rs1 = 6'd2;
        physical_rs2 = 6'd3;
        rs1_ready = 1;
        rs2_ready = 1;
        rs1_value = 32'hAAAAAAAA;
        rs2_value = 32'hBBBBBBBB;
        ROB_num = 6'd1;
        ALUControl = 4'b0001;
        imm = 32'h12345678;
		  $display("case 1");

        // Test case 2
        #10;
        physical_rd = 6'd4;
        physical_rs1 = 6'd5;
        physical_rs2 = 6'd6;
        rs1_ready = 0;
        rs2_ready = 1;
        rs1_value = 32'hCCCCCCCC;
        rs2_value = 32'hDDDDDDDD;
        ROB_num = 6'd2;
        ALUControl = 4'b0010;
        imm = 32'h87654321;

        // Test case 3
        #10;
        physical_rd = 6'd7;
        physical_rs1 = 6'd8;
        physical_rs2 = 6'd9;
        rs1_ready = 1;
        rs2_ready = 0;
        rs1_value = 32'hEEEEEEEE;
        rs2_value = 32'hFFFFFFFF;
        ROB_num = 6'd3;
        ALUControl = 4'b0011;
        imm = 32'hABCDEF01;

        // Add more test cases as needed

        // End simulation
        #100 $stop;
    end

    // Monitor changes
	 initial begin
		  $monitor("Time=%0t, entry", $time, uut.current_RS_entry);
	 end

endmodule
