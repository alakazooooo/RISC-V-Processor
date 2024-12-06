module FunctionalUnit(
  input wire clk,
  input wire reset,
  // Issue interface
  input wire write_enable,
  input wire [3:0] ALUControl,
  input wire ALUSrc, // 0 means (rs1 OPERATION rs2), 1 means (rs1 OPERATION imm)
  input wire [31:0] imm, rs1_value, rs2_value,
  input wire [5:0] tag_to_output,
  input wire [5:0] rob_index,

  output wire is_available,
  // Wakeup interface
  output wire wakeup_active,
  output wire [5:0] wakeup_rob_index,
  output wire [5:0] wakeup_tag,
  output reg [31:0] wakeup_value,
);
	reg has_operation;
	reg [3:0] internal_ALUControl;
	reg internal_ALUSrc;
	reg [31:0] internal_imm, internal_rs1_value, internal_rs2_value;
	reg [5:0] internal_tag_to_output;
	reg [5:0] internal_rob_index;
	
	// It's OK to do this unconditionally since the values only matter when
	// wakeup_active is 1.
	assign wakeup_rob_index = internal_rob_index;
	assign wakeup_tag = internal_tag_to_output;
	
	// wakeup_active goes high for only the cycle that it completes. I considered going
	// high until a new  operation arrives, but that feels potentially problematic
	// if there's a "forgotten" FU broadcasting really old tags to the rest of the system.
	assign wakeup_active = has_operation && cycles_waited_so_far == cycles_for_operation(internal_ALUControl);
	assign is_available = !has_operation || cycles_waited_so_far == cycles_for_operation(internal_ALUControl);
	
	// These are used to simulate different operations taking different amounts of time
	// (essentially testing that the rest of the system handles that robustly).
	reg [2:0] cycles_waited_so_far;
	function [2:0] cycles_for_operation;
		input [3:0] ALUControl;
	begin
		case (ALUControl)
			4'b0000: cycles_for_operation = 1; // NONE
			4'b0001: cycles_for_operation = 1; // OR
			4'b0010: cycles_for_operation = 2; // ADD
			4'b0011: cycles_for_operation = 1; // XOR
			4'b1011: cycles_for_operation = 4; // SRA (right arithmetic shift)
			4'b1111: cycles_for_operation = 1; // also NONE
			// TODO code for LUI
			default: $fatal("Invalid ALUControl");
		endcase
	end
	endfunction
	
	function [31:0] compute_operation;
		input [3:0] ALUControl;
		input [31:0] lhs;
		input [31:0] rhs;
	begin
		case (ALUControl)
			4'b0000: compute_operation = -1; // NONE
			4'b0001: compute_operation = lhs | rhs; // OR
			4'b0010: compute_operation = lhs + rhs; // ADD
			4'b0011: compute_operation = lhs ^ rhs; // XOR
			4'b1011: compute_operation = lhs >>> rhs; // SRA (right arithmetic shift)
			4'b1111: compute_operation = -1; // also NONE
			// TODO code for LUI
			default: $fatal("Invalid ALUControl");
		endcase
	end
	endfunction
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			has_operation <= 0;
			wakeup_rob_index <= -1;
			wakeup_rob_tag <= -1;
			wakeup_value <= -1;
			internal_ALUControl <= 0;
			internal_ALUSrc <= 0;
			internal_imm <= -1;
			internal_rs1_value <= -1;
			internal_rs2_value <= -1;
			internal_tag_to_output <= 0;
			internal_rob_index <= -1;
			// TODO initialize other variables as needed
		end else begin
			if (write_enable) begin
				if (!is_available) begin
					$fatal("It is not allowed to write to an unavailable FU");
				end
				internal_ALUControl <= ALUControl;
				internal_ALUSrc <= ALUSrc;
				internal_imm <= imm;
				internal_rs1_value <= rs1_value;
				internal_rs2_value <= rs2_value;
				internal_tag_to_output <= tag_to_output;
				internal_rob_index <= rob_index;
				cycles_waited_so_far <= 0;
			end else if (has_operation) begin
				// Processing logic
				if (cycles_waited_so_far < cycles_for_operation(internal_ALUControl)) begin
					cycles_waited_so_far <= cycles_waited_so_far + 3'd1;
				end else if (cycles_waited_so_far == cycles_for_operation(internal_ALUControl)) begin
					has_operation <= 0;
				end
				wakeup_value <= compute_operation(internal_ALUControl, internal_rs1_value, internal_ALUSrc ? internal_imm : internal_rs2_value);
			end
		end
	end
endmodule