

module decode(
	input wire clk,
	input wire [31:0] instruction,
	output reg [6:0] opcode,
	output reg[4:0] rd,
	output reg [4:0] rs1,            
	output reg [4:0] rs2,          
	output reg [31:0] imm,
	output reg [2:0] func3,
	output reg LoadStore,
	output reg ALUSrc,
	output reg RegWrite,
	output reg [3:0] ALUControl,
	output reg BMS 
	
);

	wire [6:0] opcode_next;
	wire [4:0] rd_next;
	wire [4:0] rs1_next;            
	wire [4:0] rs2_next;         
	wire [2:0] func3_next;
	reg [31:0] imm_next;
	reg BMS_next;
	
	wire [11:0] imm_i = instruction[31:20]; //i-type/load immediate
	wire [19:0] imm_u = instruction[31:12]; //LUI immediate
 	wire [11:0] imm_s = {instruction[31:25], instruction[11:7]}; //store immediate
	
	reg LoadStore_next;
	reg ALUSrc_next;
	reg RegWrite_next;
	reg [3:0] ALUControl_next;
	
	
	assign opcode_next = instruction[6:0];
	assign rd_next = instruction[11:7];
	assign rs1_next = instruction[19:15];
	assign rs2_next = instruction[24:20];
	assign func3_next = instruction[14:12];
	

always @(posedge clk) begin
	opcode <= opcode_next;
	rd <= rd_next;
	rs1 <= rs1_next;
	rs2 <= rs2_next;
	func3 <= func3_next;
	imm <= imm_next;
	LoadStore <= LoadStore_next;
	ALUSrc <= ALUSrc_next;
	RegWrite <= RegWrite_next;
	ALUControl <= ALUControl_next;
	BMS <= BMS_next;
end


//immediate generator, control signals
always @(*) begin

	case (opcode_next)
	
		7'b0000000: begin //NOP
			imm_next = 0;
			
			LoadStore_next = 0;
			ALUSrc_next = 0;
			RegWrite_next = 0;
			BMS_next = 0;
			
			ALUControl_next = 4'b0000; //NONE
		end
		
		7'b0110011: begin //R-type (ADD, XOR)
			imm_next = 0;
			
			LoadStore_next = 0;
			ALUSrc_next = 0;
			RegWrite_next = 1;
			BMS_next = 0;
			
			if(func3_next == 000) 
				ALUControl_next = 4'b0010; //ADD
			else
				ALUControl_next = 4'b0011; //XOR
		end
		
		7'b0010011: begin //i-type
			if(func3_next == 101) //SRAI
				imm_next = {27'b0, imm_i[4:0]}; 
			else //ADDI, ORI, LB, LW
				imm_next = {{20{imm_i[11]}}, imm_i};
				
			LoadStore_next = 0;
			ALUSrc_next = 1;
			RegWrite_next = 1;
			BMS_next = 0;

			
			if(func3_next == 000) begin
				ALUControl_next = 4'b0010; //ADDI
			end else if(func3_next == 110) begin
				ALUControl_next = 4'b0001; //ORI
			end else begin
				ALUControl_next = 4'b1011; //SRAI
			end
		end
		
		7'b0000011: begin //LOAD
			imm_next = {{20{imm_i[11]}}, imm_i};
			
			LoadStore_next = 1;
			ALUSrc_next = 1;
			RegWrite_next = 1;
			
			if(func3 == 000) begin
				BMS_next = 1;
			end else begin
				BMS_next = 0;
			end
			
			ALUControl_next = 4'b0010; //ADD
		end
		
		7'b0100011: begin //STORE
			imm_next = {{20{imm_s[11]}}, imm_s};
			
			LoadStore_next = 1;
			ALUSrc_next = 1;
			RegWrite_next = 0;
			
			if(func3 == 000) begin
				BMS_next = 1;
			end else begin
				BMS_next = 0;
			end
			
			ALUControl_next = 4'b0010; //ADD
		end
		
		7'b0110111: begin //LUI
			imm_next = {imm_u, 12'b0};
			
			LoadStore_next = 0;
			ALUSrc_next = 1;
			RegWrite_next = 1;
			BMS_next = 0;
			
			ALUControl_next = 4'b0000; //NONE
		end
		
		default: begin
			imm_next = 0;
			
			LoadStore_next = 0;
			ALUSrc_next = 0;
			RegWrite_next = 0;
			BMS_next = 0;
			
			ALUControl_next = 4'b0000; //NONE
		end
		
	endcase

end




endmodule