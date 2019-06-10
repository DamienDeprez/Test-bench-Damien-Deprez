
//------------------------------------------------------------------------------
//
// "SPI_MASTER.v" - Serial Peripheral Interface (master side)
//
// Authors : L. Moreau, 09/2014 (UCL)
//			 R. Dekimpe, 2017 (UCL)
//
//------------------------------------------------------------------------------

`timescale 1ns / 1ps

module spi_master #(
	parameter spi_addr = 32'h40000000
)(
	// CLK & RST ---------------------
	input  	wire		CLK,			// System clock
	input 	wire 		RSTn,			// System reset (active low)
	
	// SPI ---------------------------
	output 	reg 		SCK,			// SPI clock
	input  	wire 		MISO,			// Master-input-slave-output
	output  wire 		MOSI,			// Master-output-slave-input
	output	wire 		SSn,			// Slave select
	
	// AHB ---------------------------
	input 	wire		HWRITE,			// AHB transaction address
	input 	wire [31:0]	HADDR,			// AHB write-data
	input 	wire [31:0]	HWDATA,			// AHB write control
	output  wire [31:0] HRDATA,			// AHB read-data
	
	// IRQ ---------------------------
	output  wire		IRQ, 			// IRQ - byte received
	
	// SEL ---------------------------
	input wire			SPI_SEL			// SPI selection
);

	//----------------------------------------------------------------------------------
	//	PARAMETERS :
	//----------------------------------------------------------------------------------

	// FSM states 
	localparam WAIT 		= 2'h0; 
	localparam ADDR      	= 2'h1;
	localparam DATA      	= 2'h2;
	localparam LAST 		= 2'h3;

	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------
	
	wire ICLK;
	
	wire	   	rst;
	wire	   	byte_complete;
	
	
	wire	   	addr_shift, addr_load;
	wire	   	data_shift;

	reg			cm0_byte_request;
	reg			irq;
	
	reg        	hwrite_last;
	reg [31:0] 	haddr_last;
	
	reg		   	spi_active;
	reg [3:0]	spi_cnt;
	reg [1:0]  	state, nextstate;
	reg			spi_capture;
	reg [7:0]  	spi_shift_reg; 
	
	reg [7:0]  	new_byte_reg;	
	
	//----------------------------------------------------------------------------------
	//	SPI CLOCK GEN :
	//----------------------------------------------------------------------------------

	clk_div #(
		.RATIO(16'd6)
	) clk_div (
		.CLK(CLK),
		.RST(rst),
		.CLK_OUT(ICLK)
	);

	//----------------------------------------------------------------------------------
	//	SPI ACTIVE CTRL & SLAVE SELECT :
	//----------------------------------------------------------------------------------

	// SCK (output clock) generation
    always @(posedge ICLK, posedge rst) 
        if      (rst)           					SCK <= 1'b0;
        else if (~spi_active & ~cm0_byte_request) 	SCK <= 1'b0;
        else                    					SCK <= ~SCK;
	
	// Record AHB transaction information
	always @(posedge CLK  or posedge rst) begin
		if(rst) begin
			hwrite_last <= 1'b0;
			haddr_last	<= 32'd0;
		end
		else begin
			hwrite_last <= HWRITE;
			haddr_last	<= HADDR;
		end
	end
	
	
	// SPI data read from CM0 (via AHB)
	assign HRDATA = SPI_SEL ? {24'd0,new_byte_reg} : 32'd0;
	
	// SPI byte request from CM0 (via AHB)
	always @(posedge CLK, posedge rst)
		if(rst)					 				cm0_byte_request <= 1'b0;
		else if(spi_active)	 	 				cm0_byte_request <= 1'b0;
		else if(SPI_SEL & hwrite_last) 			cm0_byte_request <= 1'b1;
		else					 				cm0_byte_request <= cm0_byte_request;
		
	// SPI active control
	always @(posedge ICLK, posedge rst)
		if(rst)					 	spi_active <= 1'b0;
		else if(byte_complete)	 	spi_active <= 1'b0;
		else if(cm0_byte_request) 	spi_active <= 1'b1;
		else					 	spi_active <= spi_active;
		
	// SPI slave select
	assign SSn = ~spi_active;
	
	//----------------------------------------------------------------------------------
	//	IRQ's TO CM0 :
	//----------------------------------------------------------------------------------
	
	// New byte interrupt
	always @(posedge ICLK, posedge rst)
		if(rst) 				irq <= 1'b0;
		else if(irq)			irq <= 1'b0;
		else if(byte_complete)  irq <= 1'b1;
		else					irq <= 1'b0;
	
	assign IRQ = irq;

	//----------------------------------------------------------------------------------
	//	FSM :
	//----------------------------------------------------------------------------------
	
	// Reset 
	assign rst = ~RSTn;
	
	// State register
	always @(posedge ICLK, posedge rst)
	begin
		if(rst) 				state <= WAIT;
		else if(spi_cnt[0]) 	state <= nextstate;
		else 					state <= state;
	end
		
	// Next state logic
	always @(*)
		case(state)
			WAIT 		:	if(spi_active)			nextstate <= ADDR;
							else					nextstate <= WAIT;
			ADDR    	:   if(spi_cnt == 4'd1) 	nextstate <= DATA; 
							else					nextstate <= ADDR;
			DATA    	: 	if(spi_cnt == 4'd1) 	nextstate <= LAST;
							else					nextstate <= DATA;
			LAST 		:							nextstate <= WAIT;	
		endcase 
		
	// Control
	assign addr_load    = ((state == WAIT) & spi_active);
	assign addr_shift   = (state == ADDR);
	assign data_shift   = (state == DATA);
	assign byte_complete = (state == LAST);

	// SPI counter
	always @(posedge ICLK, posedge rst)
		if(rst)								spi_cnt <= 3'd0;
		else if(spi_active) 				spi_cnt <= spi_cnt + 3'd1;
		else								spi_cnt <= 3'd0;
		
	// SPI capture register (rising edge)
	always @(posedge ICLK, posedge rst) 
		if(rst)												spi_capture <= 1'b0;
		else if((addr_shift | data_shift) & spi_cnt[0]) 	spi_capture <= MISO;
		else if(~spi_cnt[0]) 								spi_capture <= spi_capture;
		else												spi_capture <= 1'b0;
		
	// SPI shift register	(falling edge)
	always @(posedge ICLK, posedge rst)
		if(rst)								begin
												spi_shift_reg <= 8'd0;
												new_byte_reg  <= 8'd0;
											end
		else if(byte_complete & ~spi_cnt[0])   			
											begin
												new_byte_reg  <= { spi_shift_reg[6:0], spi_capture };
												spi_shift_reg <= { spi_shift_reg[6:0], spi_capture };
											end
		else if(addr_load & ~spi_cnt[0])  				
											begin
												new_byte_reg  <= new_byte_reg;
												spi_shift_reg <= 8'b0;
											end
		else if((addr_shift | data_shift) & ~spi_cnt[0]) 	
											begin
												new_byte_reg  <= new_byte_reg;
												spi_shift_reg <= { spi_shift_reg[6:0], spi_capture };
											end
		else if(spi_cnt[0])					begin
												new_byte_reg  <= new_byte_reg;
												spi_shift_reg <= spi_shift_reg;
											end
		else								begin
												spi_shift_reg <= 8'd0;
												new_byte_reg  <= new_byte_reg;
											end
	
	// SPI MOSI
	assign MOSI = spi_shift_reg[7]; 
		
endmodule	// SPI_MASTER

//----------------------------------------------------------------------
//	CLOCK DIVIDER 
//----------------------------------------------------------------------

module clk_div #(
	parameter RATIO = 16'd12
)(
	input wire  CLK,
	input wire  RST,
	output wire CLK_OUT
);

	reg [15:0]counter;
	reg clk_div;
	
	assign CLK_OUT=clk_div;
	
	always @(posedge CLK, posedge RST) begin
		if (RST) begin
			counter <= 16'd0;
			clk_div <= 1'b1;
			end	
		else if(counter==(RATIO-16'd1)) begin
			counter <= 16'd0;
			clk_div <= 1'b1;
			end
		else if(counter==((RATIO/16'd2)-16'd1)) begin
			counter <= counter + 16'd1;
			clk_div <= 1'b0;
			end
		else begin
			counter <= counter + 16'd1;
			clk_div <= clk_div;
			end
	end

endmodule

