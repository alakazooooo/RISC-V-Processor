
module decode_TB(
	output wire [6:0] opcode,
	output wire [4:0] rd,
	output wire [4:0] rs1,            
	output wire [4:0] rs2,          
	output wire [31:0] imm,
	output wire [2:0] func3,
	output wire LoadStore,
	output wire ALUSrc,
	output wire RegWrite,
	output wire [3:0] ALUControl,
	output wire BMS 
);



reg clk = 1;
reg [31:0] instruction;

decode UUT (.clk(clk), .instruction(instruction), .opcode(opcode), 
.rd(rd), .rs1(rs1), .rs2(rs2), .imm(imm), .func3(func3), .LoadStore(LoadStore), 
.ALUSrc(ALUSrc), .RegWrite(RegWrite), .ALUControl(ALUControl), .BMS(BMS));



reg [31:0] instruction_memory [0:4]; // Array to hold 8 instructions
    integer i;

    // Initialize instructions
    initial begin
        instruction_memory[0] = 32'h00000000; // NOP
        instruction_memory[1] = 32'h09a06293;
		  instruction_memory[2] = 32'h00106313;
        instruction_memory[3] = 32'h00730e33; 
        instruction_memory[4] = 32'h01ce0eb3; 
		  
		  clk = 1;
    end

    // Apply instructions sequentially
    initial begin
        instruction = 32'h0;
        #10

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            instruction = instruction_memory[i]; // Load instruction
        end

        @(posedge clk);
        instruction = 32'h0; // Send no instruction (NOP or idle)

        #20 $stop;          // End simulation
    end


always begin
	
	#5 clk = ~clk;

end





endmodule