`timescale 1ns / 1ps

module TopLevel_TB(
	input wire test1,
	output reg test
);

  // Testbench signals
  reg clk = 0;
  reg reset;
  wire a0_ready, a1_ready;
  wire [31:0] a0_value, a1_value;

  // Instantiate the uut
  TopLevel uut (
    .clk(clk),
    .reset(reset),
    .a0_ready(a0_ready),
	 .a1_ready(a1_ready),
	 .a0_value(a0_value),
    .a1_value(a1_value)
  );


  always begin
    #5 clk = ~clk; 
  end
 
  initial begin
    reset = 1;
    #10 reset = 0; 

    // Wait for instruction fetch to complete
    wait(uut.fetch_complete);

    // End simulation
    #500;
    $display("Simulation completed");
    $stop;
  end

  // Monitor important signals
  initial begin
    $monitor("Time=%0t, PC(after current insruction done)=%h, Instruction=%h, Fetch Complete=%b",
             $time, uut.pc, uut.fetch_instruction, uut.fetch_complete);
  end

  // Timeout to prevent infinite simulation
  initial begin
    #1000 $display("Timeout reached"); 
	 $stop;
  end

endmodule
