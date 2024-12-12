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
	 //$readmemh("C:/Users/Public/try/demo.txt", hex_data);
    $readmemh("c:/Users/Zhang/Documents/School/ECE M116C/Honors Seminar/RISC-V-Processor/project/demo.txt", hex_data);
	 
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
  .instruction(fetch_instruction),
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
  wire rs1_ready, rs2_ready;
  wire [31:0] rs1_value, rs2_value;
  
  //Rename stage
  Rename rename (
    .clk(clk),
	 .reset(reset),
	 .wakeup_0_active(0), .wakeup_0_tag(0), .wakeup_0_value(0),
	 .wakeup_1_active(0), .wakeup_1_tag(0), .wakeup_1_value(0),
	 .wakeup_2_active(0), .wakeup_2_tag(0), .wakeup_2_value(0),
	 .wakeup_3_active(0), .wakeup_3_tag(0), .wakeup_3_value(0),
	 .freed_tag_1(freed_tag_1),
	 .freed_tag_2(freed_tag_2),
	 .architectural_rd(rd),
	 .architectural_rs1(rs1),
	 .architectural_rs2(rs2),
	 .physical_rd(physical_rd),
	 .physical_rs1(physical_rs1),
	 .physical_rs2(physical_rs2),
	 .rs1_ready(rs1_ready),
	 .rs2_ready(rs2_ready),
	 .rs1_value(rs1_value),
	 .rs2_value(rs2_value)
  );
  
  
  wire [5:0] ROB_num;
  
  wire [1:0] FU_num;
  wire load_store_valid;
  wire [31:0] issue_rs1_value_0, issue_rs1_value_1, issue_rs1_value_2;
  wire [31:0] issue_rs2_value_0, issue_rs2_value_1, issue_rs2_value_2;
  wire [2:0] issue_alu_type_0, issue_alu_type_1, issue_alu_type_2;
  wire [128:0] current_RS_entry;
  
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
	 .imm(imm),
	 .LoadStore(LoadStore),
	 .ALUSrc(ALUSrc),
	 .RegWrite(RegWrite),
	 .ALUControl(ALUControl),
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
  
  // Reorder buffer:
  ReorderBuffer rob(
	 .clk(clk),
	 .enqueue_enable(0),
	 .enqueue_old_tag(0),
	 .wakeup_active(0),
	 .wakeup_rob_index(0),

    .next_rob_index(ROB_num),
	 .freed_tag_1(freed_tag_1),
	 .freed_tag_2(freed_tag_2)
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
