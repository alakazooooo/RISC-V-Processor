
module TopLevel(
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
    //$readmemh("r-test-hex.txt", hex_data);
	 $readmemh("C:/Users/Public/try/r-test-hex.txt", hex_data);
    
    instruction_count = 0;
    
    // Process the data
    for (i = 0; i < 1024; i = i + 4) begin
      if (hex_data[i] === 8'h00 && hex_data[i+1] === 8'h00 && hex_data[i+2] === 8'h00 && hex_data[i+3] === 8'h00) begin
        i = 1024;  // Break the loop
      end else begin
        // Invert byte order and convert to binary
        instr_rom[instruction_count*32 +: 32] = {
          hex_data[i+0], hex_data[i+1], hex_data[i+2], hex_data[i+3]
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

  // Update PC and run fetch on each positive clock edge until fetch_complete
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pc <= 32'h0; // Reset PC to 0
    end else if (!fetch_complete) begin
      // Increment PC by 4 (assuming 32-bit instructions)
      pc <= pc + 32'd4;
    end
  end

endmodule
