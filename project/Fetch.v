module Fetch (
	input wire clk,
	input wire reset,
	input wire [31:0] pc,
	input wire [31:0] rom_size,
	input wire [8191:0] instr_rom, // The entire instruction memory as a single 8192-bit array
	output reg [31:0] instruction,
	output reg fetch_complete
);

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			instruction <= 32'b0;
			fetch_complete <= 1'b0;
		end else if (pc < rom_size) begin
			// Fetch instruction from ROM
			instruction <= instr_rom[pc * 8 +: 32];
			fetch_complete <= 1'b0;
		end else begin
			instruction <= 32'b0;
			fetch_complete <= 1'b1;
		end
	end

endmodule
