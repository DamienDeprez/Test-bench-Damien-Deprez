
//------------------------------------------------------------------------------
//
// "pixracer.v" - "PixRacer" SoC top-level
//
// Authors : T. Haine, L. Moreau, 09/2014 (UCL)
//			 R. Dekimpe 10/2017 (UCL)
//
//------------------------------------------------------------------------------

module pixracer (
	// CM0 : CLOCK AND RESET  ------------------
	input 	wire 		CLK,			   			// System clock
	input 	wire 		RSTn,						// Reset

	
	// SPI  ------------------------------------
	output 	wire 		SCK,						// SPI clock
	input   wire 		MISO,						// Master-input-slave-output
	output  wire 		MOSI,						// Master-output-slave-input
	output	wire 		SSn,						// Slave select
	
	// GPIN -----------------------------
	input	wire [15:0] GPIN,						// General purpose inputs

	// GPOUT -------- --------------------------
	output 	wire [15:0] GPOUT						// General purpose outputs
);

	//----------------------------------------------------------------------------------
	//	PARAMETERS :
	//----------------------------------------------------------------------------------
	
	// Peripherals addressing :
	localparam imem_addr_low   	= 32'h00000000;		// Instruction memory	
	localparam imem_addr_high  	= 32'h00008000;	
	localparam dmem_addr_low	= 32'h20000000;		// Data memory
	localparam dmem_addr_high   = 32'h20008000;
	localparam spi_addr			= 32'h40000000;		// SPI
	localparam gpin_addr	   	= 32'h40001000;		// General purpose inputs
	localparam gpout_addr		= 32'h40002000;		// General purpose outputs

	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------

	// NOTE : "not used" does not mean "not to use" ;)

	//
	wire		HCLK = CLK;
	
	// RESET & TMS SYNC
	reg HRESETn_sync_meta, HRESETn_sync, HRESETn_m0_sync;
	wire HRESETn_m0;
	
	// AHB-LITE MASTER PORT
	wire [31:0] HADDR;				// AHB transaction address
	wire [ 2:0] HBURST;             // AHB burst type 				 (not used)
	wire        HMASTLOCK;          // AHB locked transaction 		 (not used - fixed to 0)
	wire [ 3:0] HPROT;              // AHB protection 				 (not used)           
	wire [ 2:0] HSIZE;             	// AHB size (byte, half-word or word)
	wire [31:0] HWDATA;				// AHB write-data
	wire [ 1:0] HTRANS;				// AHB transfer (non-sequential only)
	wire		HWRITE;				// AHB write control
	wire [31:0] HRDATA;				// AHB read-data
	wire		HREADY;				// AHB stall signal				 (not used - fixed to 1)
	wire        HRESP;              // AHB bus error 				 (not used - fixed to 0)
	

	
	// CM0 : OUTPUT SIGNALS
	wire [31:0] HADDR_m0;             // AHB transaction address
	wire [ 2:0] HBURST_m0;            // AHB burst: tied to single
	wire        HMASTLOCK_m0;         // AHB locked transfer (always zero)
	wire [ 3:0] HPROT_m0;             // AHB protection: priv; data or inst
	wire [ 2:0] HSIZE_m0;             // AHB size: byte, half-word or word
	wire [ 1:0] HTRANS_m0;            // AHB transfer: non-sequential only
	wire [31:0] HWDATA_m0;            // AHB write-data
	wire        HWRITE_m0;            // AHB write control
	
	// CM0 : MISCELLANEOUS
	wire        NMI;                // Non-maskable interrupt input 	 (not used)
	wire [15:0] IRQ;                // Interrupt inputs 				 (not used)
	wire		TXEV;				// Event output (SEV executed)		 (not used)
	wire        RXEV;               // Event input 						 (not used)
	wire 		LOCKUP;				// Core is locked-up				 (not used)
	wire	    SYSRESETREQ;		// System reset request (by SW)		 (not used)
	
	// CM0 : POWER MANAGEMENT
	wire        SLEEPING;           // CPU is sleeping 					 (not used)
	
	// IRQ's
	wire		SPI_IRQ;	
	wire		GPIO_IRQ;
	
	// MEMORY
	wire [31:0] MEM_RDATA;			// Memory read-data
	wire		MEM_SEL;
	wire 		MEM_READ;
	wire		MEM_WRITE;
	wire		MEM_READY;
	
	// SPI
	wire [31:0] SPI_RDATA;			// SPI read-data
	wire 		SPI_SEL;

	// GPIO
	wire		GPIO_WRITE;			// GPIO write enable
	wire		GPIO_READ;			// GPIO read enable
	wire		GPIO_SEL;  			// GPIO select
	wire [31:0] GPIO_RDATA;			// GPIO read-data
	
	
	//----------------------------------------------------------------------------------
	//	TMS & HRESETn sync
	//----------------------------------------------------------------------------------

	
	always @(posedge HCLK or negedge RSTn) begin
		if(~RSTn) begin
			HRESETn_sync_meta	<= 1'b0;
			HRESETn_sync		<= 1'b0;
		end else begin
			HRESETn_sync_meta	<= RSTn;
			HRESETn_sync		<= HRESETn_sync_meta;
		end
	end
	
	assign HRESETn_m0	= RSTn;
	always @(posedge HCLK or negedge HRESETn_m0) begin
		if(~HRESETn_m0) 
			HRESETn_m0_sync	<= 1'b0;
		else
			HRESETn_m0_sync	<=  HRESETn_sync;
	end
		
	//----------------------------------------------------------------------------------
	//	AHB MUX
	//----------------------------------------------------------------------------------
	ahb_slave_mux #(
		imem_addr_low,		// Instruction Memory
		imem_addr_high,
		dmem_addr_low,		// Data Memory
		dmem_addr_high,
		spi_addr,			// SPI
		gpin_addr,			// General purpose inputs
		gpout_addr			// General purpose outputs
	) ahb_slave_mux_0 (
		.HCLK(HCLK),
		.HRESETn(HRESETn_sync),
		
		
		// Selection signals
		.MEM_SEL(MEM_SEL),
		.SPI_SEL(SPI_SEL),
		.GPIO_SEL(GPIO_SEL),

		// Muxed AHB signals
		.HADDR(HADDR),             			// AHB transaction address
		.HBURST(HBURST),            		// AHB burst: tied to single
		.HMASTLOCK(HMASTLOCK),         		// AHB locked transfer (always zero)
		.HPROT(HPROT),             			// AHB protection: priv; data or inst
		.HSIZE(HSIZE),             			// AHB size: byte, half-word or word
		.HTRANS(HTRANS),            		// AHB transfer: non-sequential only
		.HWDATA(HWDATA),            		// AHB write-data
		.HWRITE(HWRITE),            		// AHB write control
	
		.HRDATA(HRDATA),					// AHB read-data
	
		// Cortex-M0
		.HADDR_m0(HADDR_m0),             	// AHB transaction address
		.HBURST_m0(HBURST_m0),            	// AHB burst: tied to single
		.HMASTLOCK_m0(HMASTLOCK_m0),        // AHB locked transfer (always zero)
		.HPROT_m0(HPROT_m0),             	// AHB protection: priv; data or inst
		.HSIZE_m0(HSIZE_m0),             	// AHB size: byte, half-word or word
		.HTRANS_m0(HTRANS_m0),            	// AHB transfer: non-sequential only
		.HWDATA_m0(HWDATA_m0),            	// AHB write-data
		.HWRITE_m0(HWRITE_m0),            	// AHB write control
	
		// Memory
		.HRDATA_MEM(MEM_RDATA),				// read-data from memory
		.MEM_READ(MEM_READ),
		.MEM_WRITE(MEM_WRITE),
	
		// SPI
		.HRDATA_SPI(SPI_RDATA),				// read-data from spi
	
		// GPIO
		.HRDATA_GPIO(GPIO_RDATA),			// read-data from gpio
		.GPIO_READ(GPIO_READ),				// read control signal
		.GPIO_WRITE(GPIO_WRITE)				// write control signal
	);
	
	
	//----------------------------------------------------------------------------------
	//	JTAG
	//----------------------------------------------------------------------------------
	
	
	//----------------------------------------------------------------------------------
	//	ARM CORTEX M0 :
	//----------------------------------------------------------------------------------

	assign HREADY       = MEM_READY;			// Only memory can stall transfer
	assign HRESP        = 1'b0;					// No device in this system generates errors
	assign NMI       	= 1'b0;         		// Do not generate any non-maskable interrupts
	assign IRQ[0]		= SPI_IRQ;
	assign IRQ[1]		= GPIO_IRQ;
	assign IRQ[15:2] 	= 15'b0;   				// Do not generate any interrupts
	assign RXEV      	= 1'b0;         		// Do not generate any external events
	

	
	CORTEXM0DS cortex_0(
  		// CLOCK AND RESETS ------------------
  		.HCLK		(HCLK),              		// IN : Clock
  		.HRESETn	(HRESETn_m0_sync),           		// IN : Asyncronous reset
	
		// AHB-LITE MASTER PORT --------------
  		.HADDR      (HADDR_m0[31:0]),        		// OUT : AHB transaction address
  		.HBURST     (HBURST_m0[2:0]),            	// OUT : AHB burst: tied to single
  		.HMASTLOCK  (HMASTLOCK_m0),         		// OUT : AHB locked transfer (always zero)
  		.HPROT      (HPROT_m0[3:0]),             	// OUT : AHB protection: priv; data or inst
  		.HSIZE      (HSIZE_m0[2:0]),             	// OUT : AHB size: byte, half-word or word
  		.HTRANS     (HTRANS_m0[1:0]),            	// OUT : AHB transfer: non-sequential only
  		.HWDATA     (HWDATA_m0[31:0]),            	// OUT : AHB write-data
  		.HWRITE     (HWRITE_m0),	           		// OUT : AHB write control
  		.HRDATA     (HRDATA[31:0]),            	// IN  : AHB read-data
  		.HREADY     (HREADY),            		// IN  : AHB stall signal
  		.HRESP      (HRESP),             		// IN  : AHB error response

  		// MISCELLANEOUS ---------------------
  		.NMI        (NMI),               		// IN  : Non-maskable interrupt 
  		.IRQ        (IRQ[15:0]),               	// IN  : Interrupt request 
  		.TXEV       (TXEV),              		// OUT : Event output (SEV executed)
  		.RXEV       (RXEV),              		// IN  : Event input
  		.LOCKUP     (LOCKUP),           		// OUT : Core is locked-up
  		.SYSRESETREQ(SYSRESETREQ),       		// OUT : System reset request

  		// POWER MANAGEMENT ------------------
  		.SLEEPING   (SLEEPING)           		// OUT : Core and NVIC sleeping
	);


	//----------------------------------------------------------------------------------
	//	MEMORY
	//----------------------------------------------------------------------------------
	
	memory #(
		imem_addr_low,		// Instruction Memory
		imem_addr_high,
		dmem_addr_low,		// Data Memory
		dmem_addr_high
	) memory_0(
		// AHB ----------------
		.HCLK		(HCLK),			
		.HRESETn	(HRESETn_sync),    
		.HADDR		(HADDR),		// AHB transaction address
		.HSIZE		(HSIZE),		// AHB size: byte, half-word or word
		.HTRANS		(HTRANS),	    // AHB transfer: non-sequential only
		.HWDATA		(HWDATA),		// AHB write-data
		.HWRITE		(HWRITE),		// AHB write control
		.HRDATA		(MEM_RDATA),	// AHB read-data
		.HREADY		(MEM_READY),		// AHB stall signal
		
		// SEL -----------------------------
		.MEM_SEL	(MEM_SEL)
	);

	//----------------------------------------------------------------------------------
	//	SPI (MASTER) 
	//----------------------------------------------------------------------------------
		
	spi_master #(
		.spi_addr(spi_addr)
	) spi_master_0 (
	
		// CLK & RST ---------------------
		.CLK			(HCLK),				// System clock
		.RSTn			(HRESETn_sync),			// System reset (active low)
		
		// SPI ---------------------------
		.SCK			(SCK),				// SPI clock
		.MISO			(MISO),				// Master-input-slave-output
		.MOSI			(MOSI),				// Master-output-slave-input
		.SSn			(SSn),				// Slave select
		
		// AHB ---------------------------
		.HWRITE			(HWRITE),			// AHB transaction address
		.HADDR			(HADDR),			// AHB write-data
		.HWDATA			(HWDATA),			// AHB write control
		.HRDATA			(SPI_RDATA),		// AHB read-data
		
		// IRQ ---------------------------
		.IRQ			(SPI_IRQ), 			// IRQ when byte received
		// SEL ---------------------------
		.SPI_SEL		(SPI_SEL)			// SPI selection
	);
	
	//----------------------------------------------------------------------------------
	//	GPIO
	//----------------------------------------------------------------------------------
	
	gpio #( 						// General-purpose I/O 
		.DATA_WIDTH(16)				
	) gpio_0 (	
		// IN
		.clk	(HCLK),			// Clock (syncronous read/write)
		.reset	(~HRESETn_sync),	// syncronous reset
		.sel	(GPIO_SEL),			// Chip select
		.read	(GPIO_READ),		// Read enable
		.write	(GPIO_WRITE),		// Write enable
		.wdata	(HWDATA[15:0]),		// Internal input bus (write)
		.gpin	(GPIN[15:0]),		// I/O input bus
		
		// OUT
		.rdata	(GPIO_RDATA),		// Internal output bus (read)
		.gpout  (GPOUT[15:0]),		// I/O output bus
		.irq	(GPIO_IRQ)
	);

endmodule