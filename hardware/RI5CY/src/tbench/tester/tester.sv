
//------------------------------------------------------------------------------
//
// "tester.sv" - "Pix Racer" dedicated tester : SystemVerilog implementation
//
// Authors: 
//  - Initial SystemC version: F. Stas, L. Moreau, 09/2014 (UCL)
//  - Current SystemVerilog version: C. Frenkel, 09/2015 (UCL)
//
//------------------------------------------------------------------------------

`timescale 1ps / 1fs
`define 	HCLK_HALF_PERIOD	6250   // PixRacer: [ps] -> 80Mhz

module tester (
	
	// CLK & RESET
	output logic        CLK,
	output logic        RSTn,
	
	// SPI ports
	input  logic        MOSI,
	input  logic        SCK,
	output logic        MISO,
	input  logic        SSn,
	
	// GPIO
	input  logic [15:0] GPOUT,
	output logic [15:0] GPIN
);
    
	/***************************
			REGISTERS
	***************************/ 

	logic RST;
	
	
	/***************************
			CLOCK GENERATION
	***************************/ 
    
	clock_gen clock_gen0(
		.CLK(CLK),
		.TCK(TCK)
	);
	
	/***************************
			RESET
	***************************/ 
	
	reset reset_0(
		.RST(RST)
	);
	assign RSTn = !RST;

	assign GPIN[15:1] = 14'b0;
	

	
	
	/***************************
			SPI
	***************************/
	
	/*spi_slave spi_slave_0(
		.RST(RST),
		.SCK(SCK),
		.MOSI(MOSI),
		.SSn(SSn),
		.MISO(MISO)
	);*/
	
	
	
	/***************************
			DISPLAY
	***************************/
	
	display display_0(
		.RST(RST),
		.CLK(CLK),
		.IN(GPOUT)
	);
	
    /***********************************************************************
						    TASK IMPLEMENTATIONS
    ************************************************************************/ 

    /***************************
	 SIMPLE TIME-HANDLING TASKS
	***************************/
	
	// These routines are based on a correct definition of the simulation timescale.
	task wait_ns;
		input   tics_ns;
		integer tics_ns;
		repeat (tics_ns) wait_ps(1000);
	endtask
	
	task wait_ps;
		input   tics_ps;
		integer tics_ps;
		#tics_ps;
	endtask
	
endmodule

// ---------------- CLOCK GEN -------------------
module clock_gen(
	output logic	CLK,
	output logic	TCK
);
	// cfr. tester.h for clock period definition
	// Main clock
	initial begin
		wait_ps(`HCLK_HALF_PERIOD);
		CLK = 1'b1; 
		forever begin
			wait_ps(`HCLK_HALF_PERIOD);
			CLK = ~CLK; 
	    end
	end 
	
	
endmodule

// ---------------- RESET -------------------
module reset(
	output logic	RST
);

	initial begin 
		RST = 1'b1;
		wait_ns(4000);
		RST = 1'b0;
	end
	
endmodule
// ---------------- DISPLAY -------------------
module display(
	input logic 	CLK,
	input logic 	RST,
	input logic[15:0]	IN
);

	always @(posedge CLK) begin
     if(IN[8]) begin
		    $write("%d @ %d ps\n", IN[7:0], $time );
     end
     else if(IN[10]) begin
       $finish;
     end
 end
 	
endmodule