`timescale 1ns / 1ps
//--------------------------------------------------------------------------------------
//
// "pcb.v"
//
// Authors : D. Bol, 11/2015 (UCL)
// Delays are modeled as transport delays (i.e. not inertial delays)
//--------------------------------------------------------------------------------------

module pcb_delay (
	
	// IN FROM TESTER
		// CM0 : CLOCK AND RESET ------------
		input wire 			iCLK,
		input wire 			iRSTn,
		// SPI ------------------------------
		input wire 			iMISO,
		// GPIN -----------------------------
		input wire [15:0] 	iGPIN,
		
	// IN FROM PIXRACER
		// SPI ------------------------------
		input wire 			iSCK,
		input wire 			iMOSI,
		input wire 			iSSn,
		// GPOUT ----------------------------
		input wire [15:0]	iGPOUT,
		
	// OUT TO TESTER
		// SPI ------------------------------
		output reg 			oSCK,
		output reg 			oMOSI,
		output reg 			oSSn,
		// GPOUT ----------------------------
		output reg [15:0]	oGPOUT,
		
	// OUT TO PIXRACER					
		// CM0 : CLOCK AND RESET ------------
		output reg			oCLK,
		output reg 			oRSTn,
		// SPI ------------------------------
		output reg 			oMISO,
		// GPIN -----------------------------
		output reg [15:0]	oGPIN
);
	
	// OUT TO TESTER

		
		// SPI ------------------------------
		always @(*) oSCK	<=  #5 iSCK;	
		always @(*) oMOSI	<=  #5 iMOSI;	
		always @(*) oSSn	<=  #5 iSSn;	
		
		// GPOUT ----------------------------
		always @(*) oGPOUT	<=  #5 iGPOUT;	
		
	// OUT TO PIXRACER	
	
		// CM0 : CLOCK AND RESET ------------
		always @(*) oCLK	<= #5 iCLK;
		always @(*) oRSTn	<=  #5 iRSTn;
		
		
		// SPI ------------------------------
		always @(*) oMISO	<=  #5 iMISO;
		
		// GPIN -----------------------------
		always @(*) oGPIN	<=  #5 iGPIN;
	

endmodule