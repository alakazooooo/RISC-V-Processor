module TopLevel (
  input wire clk,
  input wire reset,
  output wire [31:0] a0,
  output wire [31:0] a1
);


  reg [31:0] pc;
  wire [31:0] fetch_instruction;
  wire fetch_complete;

  // Initialize the instruction ROM
  reg [8191:0] instr_rom;  // 8192-bit array (256 x 32-bit instructions)
  reg [7:0] hex_data [0:1023];   // Assuming max 1024 bytes in the file
  reg [31:0] rom_size;

  integer i, instruction_count;

  initial begin
    // Initialize instr_rom and hex_data
    instr_rom = 8192'h0;
    for (i = 0; i < 1024; i = i + 1) begin
      hex_data[i] = 8'h0;
    end

    // Read the hex file
    //$readmemh("demo.txt", hex_data);
	 //$readmemh("C:/Users/lydia/RISC-V-Processor/project/final-inst.txt", hex_data);
    $readmemh("c:/Users/Zhang/Documents/School/ECE M116C/Honors Seminar/RISC-V-Processor/project/final-inst.txt", hex_data);
	 
    instruction_count = 0;
    
    // Process the data
    for (i = 0; i < 1024; i = i + 4) begin
      if (hex_data[i] === 8'h00 && hex_data[i+1] === 8'h00 && hex_data[i+2] === 8'h00 && hex_data[i+3] === 8'h00) begin
        i = 1024;  // Break the loop
      end else begin
        // Invert byte order and convert to binary
        instr_rom[instruction_count*32 +: 32] = {
          hex_data[i+3], hex_data[i+2], hex_data[i+1], hex_data[i+0]
        };
		  
        instruction_count = instruction_count + 1;
      end
    end
    
    rom_size = instruction_count * 4; //each instruction is 4 bytes
  end

  // Instantiate fetch_stage module
  Fetch fetch (
    .clk(clk),
    .reset(reset),
    .pc(pc),
    .rom_size(rom_size),
    .instr_rom(instr_rom),
    .instruction(fetch_instruction),
    .fetch_complete(fetch_complete)
  );

   wire is_issue_instruction_valid;
   wire [6:0] opcode;
	wire [4:0] rd;
	wire [4:0] rs1;            
	wire [4:0] rs2;         
	wire [2:0] func3;
	wire [31:0] imm;
	wire BMS;
	wire LoadStore;
	wire ALUSrc;
	wire RegWrite;
	wire [3:0] ALUControl;
  
  //decode stage
  Decode decode (
  .clk(clk),
  .is_input_valid(!fetch_complete),
  .instruction(fetch_instruction),
  .is_instruction_valid(is_issue_instruction_valid),
  .opcode(opcode),
  .rd(rd),
  .rs1(rs1),
  .rs2(rs2),
  .func3(func3),
  .imm(imm),
  .LoadStore(LoadStore),
  .ALUSrc(ALUSrc),
  .RegWrite(RegWrite),
  .ALUControl(ALUControl),
  .BMS(BMS)
  );
  
  wire [5:0] freed_tag_1, freed_tag_2;
  wire [5:0] physical_rd, physical_rs1, physical_rs2;
  wire [5:0] old_physical_rd;
  wire rs1_ready, rs2_ready;
  wire [31:0] rs1_value, rs2_value;
  wire wakeup_1_valid; 
  wire wakeup_2_valid;
  wire wakeup_3_valid;
  wire wakeup_0_valid;
  wire [5:0] wakeup_1_tag; 
  wire [5:0] wakeup_2_tag;
  wire [5:0] wakeup_3_tag;
  wire [5:0] wakeup_0_tag;
  wire [31:0] wakeup_1_val;
  wire [31:0] wakeup_2_val;
  wire [31:0] wakeup_3_val;
  wire [31:0] wakeup_0_val;
  
  //Rename stage
  Rename rename (
    .clk(clk),
	 .reset(reset),
	 .wakeup_0_active(wakeup_0_valid), .wakeup_0_tag(wakeup_0_tag), .wakeup_0_value(wakeup_0_val),
	 .wakeup_1_active(wakeup_1_valid), .wakeup_1_tag(wakeup_1_tag), .wakeup_1_value(wakeup_1_val),
	 .wakeup_2_active(wakeup_2_valid), .wakeup_2_tag(wakeup_2_tag), .wakeup_2_value(wakeup_2_val),
	 .wakeup_3_active(wakeup_3_valid), .wakeup_3_tag(wakeup_3_tag), .wakeup_3_value(wakeup_3_val),
	 .freed_tag_1(freed_tag_1),
	 .freed_tag_2(freed_tag_2),
	 .is_instruction_valid(is_issue_instruction_valid),
	 .architectural_rd(rd),
	 .architectural_rs1(rs1),
	 .architectural_rs2(rs2),
	 .physical_rd(physical_rd),
	 .physical_rs1(physical_rs1),
	 .physical_rs2(physical_rs2),
	 .old_physical_rd(old_physical_rd),
	 .rs1_ready(rs1_ready),
	 .rs2_ready(rs2_ready),
	 .rs1_value(rs1_value),
	 .rs2_value(rs2_value)

  );
  
  wire [5:0] ROB_num;
  wire [1:0] FU_num;
  wire FU1_ready, FU2_ready, FU3_ready;
  wire issue_0_is_LS, issue_1_is_LS, issue_2_is_LS;
  wire issue_FU1_valid, issue_FU2_valid, issue_FU3_valid;
  wire [5:0] issue_0_rd_tag, issue_1_rd_tag, issue_2_rd_tag;
  wire issue_0_alusrc, issue_1_alusrc, issue_2_alusrc;
  wire [5:0] issue_0_rob_num, issue_1_rob_num, issue_2_rob_num;
  wire [31:0] issue_0_rs1_val, issue_1_rs1_val, issue_2_rs1_val;
  wire [31:0] issue_0_rs2_val, issue_1_rs2_val, issue_2_rs2_val;
  wire [31:0] issue_0_imm, issue_1_imm, issue_2_imm;
  wire [3:0] issue_0_alu_type, issue_1_alu_type, issue_2_alu_type;
  
  //Reservation Station:
  ReservationStation RS (
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
    .load_into_RS(is_issue_instruction_valid),
    .ALUControl(ALUControl),
    .imm(imm),
    .LoadStore(LoadStore),
    .ALUSrc(ALUSrc),
    .FU1_ready(FU1_ready),
    .FU2_ready(FU2_ready),
    .FU3_ready(FU3_ready),
    .wakeup_1_valid(wakeup_0_valid), 
    .wakeup_2_valid(wakeup_1_valid), 
    .wakeup_3_valid(wakeup_2_valid), 
    .wakeup_4_valid(wakeup_3_valid),
	 .wakeup_1_tag(wakeup_0_tag), 
    .wakeup_2_tag(wakeup_1_tag), 
    .wakeup_3_tag(wakeup_2_tag), 
    .wakeup_4_tag(wakeup_3_tag),
	 .wakeup_1_val(wakeup_0_val), 
    .wakeup_2_val(wakeup_1_val), 
    .wakeup_3_val(wakeup_2_val), 
    .wakeup_4_val(wakeup_3_val),

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
  
  wire [5:0] wakeup_0_rob_index, wakeup_1_rob_index, wakeup_2_rob_index;
  wire [5:0] enqueue_old_tag;
  wire [31:0] lsq_wakeup_0_val, lsq_wakeup_1_val, lsq_wakeup_2_val;
  wire [5:0] lsq_wakeup_0_rob_index, lsq_wakeup_1_rob_index, lsq_wakeup_2_rob_index;
  wire lsq_wakeup_0_valid, lsq_wakeup_1_valid, lsq_wakeup_2_valid;
	
	// Reorder Buffer:
	ReorderBuffer rob(
		.clk(clk),
		.enqueue_enable(is_issue_instruction_valid),
		.enqueue_old_tag(old_physical_rd),
		.wakeup_0_active(wakeup_0_valid), .wakeup_0_rob_index(wakeup_0_rob_index),
		.wakeup_1_active(wakeup_1_valid), .wakeup_1_rob_index(wakeup_1_rob_index),
		.wakeup_2_active(wakeup_2_valid), .wakeup_2_rob_index(wakeup_2_rob_index),
		// TODO wire up this fourth wakeup input to outputs of the LSQ
		.wakeup_3_active(0), .wakeup_3_rob_index(0),

		.next_rob_index(ROB_num),
		.freed_tag_1(freed_tag_1),
		.freed_tag_2(freed_tag_2)
	);
	
	FunctionalUnit fu1(
		.clk(clk),
		.reset(reset),
		.write_enable(issue_FU1_valid),
		.ALUControl(issue_0_alu_type),
		.ALUSrc(issue_0_alusrc),
		.is_for_lsq(issue_0_is_LS),
		.imm(issue_0_imm),
		.rs1_value(issue_0_rs1_val),
		.rs2_value(issue_0_rs2_val),
		.tag_to_output(issue_0_rd_tag),
		.rob_index(issue_0_rob_num),
		
		.is_available(FU1_ready),
		.wakeup_active(wakeup_0_valid),
		.wakeup_rob_index(wakeup_0_rob_index),
		.wakeup_tag(wakeup_0_tag),
		.wakeup_value(wakeup_0_val),
		.lsq_wakeup_active(lsq_wakeup_0_valid),
		.lsq_wakeup_rob_index(lsq_wakeup_0_rob_index),
		.lsq_wakeup_value(lsq_wakeup_0_val)
	);
	
	FunctionalUnit fu2(
		.clk(clk),
		.reset(reset),
		.write_enable(issue_FU2_valid),
		.ALUControl(issue_1_alu_type),
		.ALUSrc(issue_1_alusrc),
		.is_for_lsq(issue_1_is_LS),
		.imm(issue_1_imm),
		.rs1_value(issue_1_rs1_val),
		.rs2_value(issue_1_rs2_val),
		.tag_to_output(issue_1_rd_tag),
		.rob_index(issue_1_rob_num),
		
		.is_available(FU2_ready),
		.wakeup_active(wakeup_1_valid),
		.wakeup_rob_index(wakeup_1_rob_index),
		.wakeup_tag(wakeup_1_tag),
		.wakeup_value(wakeup_1_val),
		.lsq_wakeup_active(lsq_wakeup_1_valid),
		.lsq_wakeup_rob_index(lsq_wakeup_1_rob_index),
		.lsq_wakeup_value(lsq_wakeup_1_val)
	);
	
	FunctionalUnit fu3( //TODO: test/make fu1,2,3 parallel
		.clk(clk),
		.reset(reset),
		.write_enable(issue_FU3_valid),
		.ALUControl(issue_2_alu_type),
		.ALUSrc(issue_2_alusrc),
		.is_for_lsq(issue_2_is_LS),
		.imm(issue_2_imm),
		.rs1_value(issue_2_rs1_val),
		.rs2_value(issue_2_rs2_val),
		.tag_to_output(issue_2_rd_tag),
		.rob_index(issue_2_rob_num),
		
		.is_available(FU3_ready),
		.wakeup_active(wakeup_2_valid),
		.wakeup_rob_index(wakeup_2_rob_index),
		.wakeup_tag(wakeup_2_tag),
		.wakeup_value(wakeup_2_val),
		.lsq_wakeup_active(lsq_wakeup_2_valid),
		.lsq_wakeup_rob_index(lsq_wakeup_2_rob_index),
		.lsq_wakeup_value(lsq_wakeup_2_val)
	);
  
  
 
  LoadStoreQueue LSQ (
	.clk(clk),
	.reset(reset),
	.LoadStore(LoadStore && is_issue_instruction_valid),
	.RegWrite(RegWrite),
	.ROB_index(ROB_num),
	.store_rs2_tag(physical_rs2),
	.store_rs2_ready(rs2_ready),
	.store_rs2_value(rs2_value),
	.load_rd_tag(physical_rd),
	.BMS(BMS),
	.FU_1_valid(lsq_wakeup_0_active),
	.FU_2_valid(lsq_wakeup_1_active),
	.FU_3_valid(lsq_wakeup_2_active),
	.FU_1_address(lsq_wakeup_0_val),
	.FU_2_address(lsq_wakeup_1_val),
	.FU_3_address(lsq_wakeup_2_val),
	.FU_1_ROB_index(lsq_wakeup_0_rob_index),
	.FU_2_ROB_index(lsq_wakeup_1_rob_index),
	.FU_3_ROB_index(lsq_wakeup_2_rob_index),
	.wakeup_1_valid(lsq_wakeup_0_valid),
	.wakeup_2_valid(lsq_wakeup_1_valid),
	.wakeup_3_valid(lsq_wakeup_2_valid),
	.wakeup_1_tag(wakeup_0_tag),
	.wakeup_2_tag(wakeup_1_tag),
	.wakeup_3_tag(wakeup_2_tag),
	.wakeup_1_val(lsq_wakeup_0_val), //or not? idk
	.wakeup_2_val(lsq_wakeup_1_val),
	.wakeup_3_val(lsq_wakeup_2_val),
	.forward_rd_value(wakeup_3_val),
	.forward_rd_tag(wakeup_3_tag),
	.forward_rd_valid(wakeup_3_valid)
	//.completed_ROB_index(),
	//.completed_valid()
  );
  
  
  
  // Update PC and run fetch on each positive clock edge until fetch_complete
  always @(posedge clk or posedge reset) begin
  
    if (reset) begin
      pc <= 32'h0;
    end else if (!fetch_complete) begin
      // Increment PC by 4
      pc <= pc + 32'd4;
    end
  end


endmodule
