
module Fetch(
    input wire clk,                  // Clock input
    input wire reset,                // Reset signal
    input wire [31:0] pc,            // PC (changed to wire)
    input wire [31:0] rom_size,      // Size of the instruction memory (changed to wire)
    input wire [8191:0] instr_rom,   // The entire instruction memory as a single 8192-bit array
    output reg [31:0] instruction,   // Fetched instruction
    output reg fetch_complete 
);

    always @(posedge clk) begin
        if (pc < (rom_size-4)) begin
            // Fetch instruction from ROM
            instruction <= instr_rom[pc +: 32];
            fetch_complete <= 1'b0;
        end else begin
            // No more instructions to fetch
            fetch_complete <= 1'b1;
        end
    end

endmodule
