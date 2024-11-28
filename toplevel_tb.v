`timescale 1ns / 1ps

module toplevel_tb(
	input wire test1,
	output reg test
);

  // Testbench signals
  reg clk = 0;
  reg reset;
  wire [31:0] a0;
  wire [31:0] a1;

  // Instantiate the uut
  toplevel uut (
    .clk(clk),
    .reset(reset),
    .a0(a0),
    .a1(a1)
  );


  always begin
    #5 clk = ~clk; 
  end
 
  initial begin
    // Initialize inputs
    reset = 1;
    #100 reset = 0; 

    // Wait for instruction fetch to complete
    wait(uut.fetch_complete);

    // End simulation
    #100;
    $display("Simulation completed");
    $stop;
  end

  // Monitor important signals
  initial begin
    $monitor("Time=%0t, PC=%h, Instruction=%h, Fetch Complete=%b",
             $time, uut.pc, uut.fetch_instruction, uut.fetch_complete);
  end

  // Timeout to prevent infinite simulation
  initial begin
    #1000 $display("Timeout reached"); $finish;
  end

endmodule