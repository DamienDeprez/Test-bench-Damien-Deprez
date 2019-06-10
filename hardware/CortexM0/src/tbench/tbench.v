
//--------------------------------------------------------------------------------------
//	Testbench
// Authors : T. Haine, L. Moreau, F. Stas, C. Frenkel, D. Bol, 09/2015 (UCL)
//--------------------------------------------------------------------------------------

module tbench();

	//----------------------------------------------------------------------------------
	//	WIRES FROM EXT WORLD :
	//----------------------------------------------------------------------------------
	
	// AHB :
	wire 	    CLK_EXT;		// AHB-Lite interface and CPU master clock
	wire 	   	RSTn_EXT;		// AHB-Lite active-low reset signal
	

	// SPI :
	wire		SCK_EXT;		// SPI clock
	wire		MISO_EXT;		// Master input / Slave output
	wire		MOSI_EXT;		// Master output / Slave input
	wire		SSn_EXT;		// Slave select (active low)

	// GPIN :
	wire [15:0] GPIN_EXT;		// General purpose inputs
	
	// GPOUT :
	wire [15:0] GPOUT_EXT;		// General purpose outputs
	
	//----------------------------------------------------------------------------------
	//	WIRES :
	//----------------------------------------------------------------------------------

	// AHB :
	wire 	    CLK;			// AHB-Lite interface and CPU master clock
	wire 	   	RSTn;			// AHB-Lite active-low reset signal

	// SPI :
	wire		SCK;			// SPI clock
	wire		MISO;			// Master input / Slave output
	wire		MOSI;			// Master output / Slave input
	wire		SSn;			// Slave select (active low)

	// GPIN :
	wire [15:0] GPIN;			// General purpose inputs
	
	// GPOUT :
	wire [15:0] GPOUT;			// General purpose outputs

	//----------------------------------------------------------------------------------
	//	TESTER :
	//----------------------------------------------------------------------------------

	tester tester_0 (
		.CLK		(CLK_EXT),			// System clock
		.RSTn		(RSTn_EXT),			// System reset	 (active low)
		.SCK		(SCK_EXT),			// SPI clock
		.MISO		(MISO_EXT),			// Master-input-slave-output
		.MOSI		(MOSI_EXT),			// Master-output-slave-input
		.SSn		(SSn_EXT),			// Slave select
		.GPOUT		(GPOUT_EXT),
		.GPIN		(GPIN_EXT)
	);
	
	//----------------------------------------------------------------------------------
	//	DELAYER :
	//----------------------------------------------------------------------------------

	pcb_delay pcb_delay_0 (
	
	// IN FROM TESTER
		// CM0 : CLOCK AND RESET ------------
		.iCLK		(CLK_EXT),
		.iRSTn		(RSTn_EXT),
		// SPI ------------------------------
		.iMISO		(MISO_EXT),
		// GPIN -----------------------------
		.iGPIN		(GPIN_EXT),
		
	// IN FROM PIXRACER
		// SPI ------------------------------
		.iSCK		(SCK),
		.iMOSI		(MOSI),
		.iSSn		(SSn),
		// GPOUT ----------------------------
		.iGPOUT		(GPOUT),
		
	// OUT TO TESTER
		// SPI ------------------------------
		.oSCK		(SCK_EXT),
		.oMOSI		(MOSI_EXT),
		.oSSn		(SSn_EXT),
		// GPOUT ----------------------------
		.oGPOUT		(GPOUT_EXT),
		
	// OUT TO PIXRACER					
		// CM0 : CLOCK AND RESET ------------
		.oCLK		(CLK),
		.oRSTn		(RSTn),
		// SPI ------------------------------
		.oMISO		(MISO),
		// GPIN -----------------------------
		.oGPIN		(GPIN)
	);
	
	//----------------------------------------------------------------------------------
	//	PIX RACER :
	//----------------------------------------------------------------------------------

	pixracer pixracer_0 (

		// CM0 : CLOCK AND RESET ------------
		.CLK		(CLK),
		.RSTn		(RSTn),					
		
		// SPI ------------------------------
		.SCK		(SCK),
		.MISO		(MISO),
		.MOSI		(MOSI),
		.SSn		(SSn),
		
		// GPIN -----------------------------
		.GPIN		(GPIN),
		
		// GPOUT ----------------------------
		.GPOUT		(GPOUT)
	);

endmodule