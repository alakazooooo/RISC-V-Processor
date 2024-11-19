module toplevel (
  input wire clk,
  input wire reset,
  // Memory interface
  output wire [31:0] a0,
  output wire [31:0] a1
);

  // Internal wires
  wire [31:0] pc;
  wire [31:0] instruction;

  // Pipeline stage interfaces
  wire [31:0] fetch_instruction;
  wire fetch_complete;


//   Initialize the instruction ROM
//
//
//   Instruction ROM 
  reg [31:0] instr_rom [0:255];  // 256 x 32-bit ROM

  // Declare a memory array to store the input hex values
  reg [7:0] hex_data [0:1023];  // Assuming max 1024 bytes in the file
  
  integer i, instruction_count;
  
  initial begin
    // Read the hex file
    $readmemh("r-test-hex.txt", hex_data);
    
    instruction_count = 0;
    
    // Process the data
    for (i = 0; i < 1024; i = i + 4) begin
      
		
		//if (hex_data[i] === 8'h00 && hex_data[i+1] === 8'h00 && hex_data[i+2] === 8'h00 && hex_data[i+3] === 8'h00) begin
		//	$display("nothing");
		//end
      
      // Invert byte order and convert to binary
      instr_rom[instruction_count] = {
        {hex_data[i+0]},
        {hex_data[i+1]},
        {hex_data[i+2]},
        {hex_data[i+3]}
      };
      
      // Display the result
      //$display("Instruction %0d: %h -> %b", instruction_count, 
      //         {hex_data[i+3], hex_data[i+2], hex_data[i+1], hex_data[i+0]},
      //         instr_rom[instruction_count]);
      
      instruction_count = instruction_count + 1;
    end
    
  end

//
//
//
// Proceed to the sub-modules




endmodule