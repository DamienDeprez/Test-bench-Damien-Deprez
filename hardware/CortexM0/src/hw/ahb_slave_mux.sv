
//------------------------------------------------------------------------------
// "ahb_slave_mux.v"
//	- Mux signals from M0 and JTAG according to TMS
//	- Mux HRDATA from peripheral according to the address
//	- Select the right peripheral according to the address
//
// Authors and updates: 
//			K. Nguyen, 10/2015 (UCL)
//          C. Frenkel, 01/2017 (UCL)
//    		L. Moreau, xx/01/2016 (UCL): addition of the FFT read/write control & data 
//			L. Moreau, 18/01/2017 (UCL): addition of the DCMI read control & data
//			L. Moreau, 06/02/2017 (UCL): addition of DCMI's config register
//								      AHB addressable write access to DCMI's registers
//			D. Bol, 14/04/2014 (UCL): OR between the two masters, (previously) HTRANS enabling of the memory
//			R. Dekimpe, 10/2017 (UCL): modifications for PixRacer
//
//------------------------------------------------------------------------------
module ahb_slave_mux #(
	parameter imem_addr_low   	= 32'h00000000,		// Instruction memory	
	parameter imem_addr_high  	= 32'h00008000,	
	parameter dmem_addr_low		= 32'h20000000,		// Data memory
	parameter dmem_addr_high   	= 32'h20008000,
	parameter spi_addr			= 32'h40000000,		// SPI
	parameter gpin_addr	   		= 32'h40001000,		// General purpose inputs
	parameter gpout_addr		= 32'h40002000		// General purpose outputs
	
)(
	input 	wire HCLK,
	input 	wire HRESETn,
	
	// Selection signals
	output wire MEM_SEL,
	output wire SPI_SEL,
	output wire GPIO_SEL,

	// Muxed output AHB signals
	output wire [31:0] HADDR,             	// AHB transaction address
	output wire [ 2:0] HBURST,           	// AHB burst: tied to single
	output wire        HMASTLOCK,        	// AHB locked transfer (always zero)
	output wire [ 3:0] HPROT,            	// AHB protection: priv; data or inst
	output wire [ 2:0] HSIZE,            	// AHB size: byte, half-word or word
	output wire [ 1:0] HTRANS,           	// AHB transfer: non-sequential only
	output wire [31:0] HWDATA,           	// AHB write-data
	output wire        HWRITE,           	// AHB write control
	
	output wire [31:0] HRDATA,				// AHB read-data
	
	// Cortex-M0
	input  wire [31:0] HADDR_m0,            // AHB transaction address
	input  wire [ 2:0] HBURST_m0,           // AHB burst: tied to single
	input  wire        HMASTLOCK_m0,        // AHB locked transfer (always zero)
	input  wire [ 3:0] HPROT_m0,            // AHB protection: priv; data or inst
	input  wire [ 2:0] HSIZE_m0,            // AHB size: byte, half-word or word
	input  wire [ 1:0] HTRANS_m0,           // AHB transfer: non-sequential only
	input  wire [31:0] HWDATA_m0,           // AHB write-data
	input  wire        HWRITE_m0,           // AHB write control
	
	// Memory
	input  wire [31:0] HRDATA_MEM,			// read-data from memory
	output wire 	   MEM_READ,
	output wire		   MEM_WRITE,
	
	// SPI
	input  wire [31:0] HRDATA_SPI,			// read-data from SPI0
	
	// GPIO
	input  wire [31:0] HRDATA_GPIO,			// read-data from GPIO
	output wire 	   GPIO_READ,			// read control signal
	output wire 	   GPIO_WRITE			// write control signal
);

	
	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------
	reg 		hwrite_last;
	reg [31:0]	haddr_last;
	reg [1:0]	htrans_last;
	reg [31:0]  HRDATA_reg;
	
	//----------------------------------------------------------------------------------
	//	CONTROL :
	//----------------------------------------------------------------------------------
	
	// AHB MUX ----------------------------------------------
	assign	HBURST		=  HBURST_m0;
	assign	HMASTLOCK	= 1'b0;
	assign	HPROT		= HPROT_m0;
	assign	HSIZE		=  HSIZE_m0;
	assign	HWDATA		=  HWDATA_m0;
	assign	HADDR		=  HADDR_m0; 
	
	assign HTRANS		=   HTRANS_m0;
	assign HWRITE		=   HWRITE_m0;
	
	
	// HRDATA Mux ---------------------------------------------
	always @(posedge HCLK, negedge HRESETn) begin
		if(!HRESETn) begin
			hwrite_last <= 1'b0;
			haddr_last	<= 32'b0;
			htrans_last <= 2'b0;
		end
		else begin
			hwrite_last <= HWRITE;
			haddr_last	<= HADDR;
			htrans_last	<= HTRANS;
		end
	end
	
	always @(*) begin
		if(haddr_last == gpin_addr)			                                        HRDATA_reg = HRDATA_GPIO;
		else if (haddr_last == spi_addr)	                                    	HRDATA_reg = HRDATA_SPI;
		else if ((haddr_last >= imem_addr_low) & (haddr_last < imem_addr_high))		HRDATA_reg = HRDATA_MEM;
		else if ((haddr_last >= dmem_addr_low) & (haddr_last < dmem_addr_high))		HRDATA_reg = HRDATA_MEM;
		else 								                                        HRDATA_reg = 32'b0;
	end 
	
	assign HRDATA = HRDATA_reg;
	
	// Assertions
	always @(posedge HCLK)
		if (HRESETn)
			address_notX: assert (^HADDR !== 1'bx) else $warning("X on address");
			
	always @(posedge HCLK)
		if (HRESETn & htrans_last[1]) begin
			address_valid: assert (haddr_last==gpin_addr | haddr_last==gpout_addr | haddr_last==spi_addr | ((haddr_last >= imem_addr_low) & (haddr_last < imem_addr_high)) | ((haddr_last >= dmem_addr_low) & (haddr_last < dmem_addr_high))) else $warning("Invalid address");
			if(~hwrite_last)
				rdata_valid: assert (^HRDATA !== 1'bx ) else $warning("Invalid read data");
		end
	
	// Selection signals ---------------------------------------------
    assign MEM_SEL	= (((HADDR >= imem_addr_low) & (HADDR < imem_addr_high))|((HADDR >= dmem_addr_low) & (HADDR < dmem_addr_high))) & HTRANS[1] ;
	assign SPI_SEL = (haddr_last == spi_addr) & htrans_last[1] ;
	assign GPIO_SEL = GPIO_READ | GPIO_WRITE ;
	
	// MEM write & read ----------------------------------------------
	assign MEM_WRITE   = ((((haddr_last >= imem_addr_low) & (haddr_last < imem_addr_high))|((haddr_last >= dmem_addr_low) & (haddr_last < dmem_addr_high))) & hwrite_last) & htrans_last[1];
	assign MEM_READ    = ((((haddr_last >= imem_addr_low) & (haddr_last < imem_addr_high))|((haddr_last >= dmem_addr_low) & (haddr_last < dmem_addr_high))) & ~hwrite_last) & htrans_last[1];
	
	// GPIO write & read ---------------------------------------------
	assign GPIO_READ 	= (haddr_last == gpin_addr) & htrans_last[1] ;
	assign GPIO_WRITE	= ((haddr_last == gpout_addr) & hwrite_last) & htrans_last[1] ;
	

endmodule