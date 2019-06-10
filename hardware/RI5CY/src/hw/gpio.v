
//------------------------------------------------------------------------------
// "GPIO.v" : Generate-purpose I/Os
//
// Authors : D. Bol, 2013 (UCL)
//			 C. Frenkel, 12/2016 (UCL)
//			 R. Dekimpe, 2017 (UCL)
//
//------------------------------------------------------------------------------

`timescale 1ns / 1ps

module gpio	#(parameter DATA_WIDTH = 16)(
	input							HCLK, 
	input							HRESETn, 
	input							gpio_sel,
	input							gpio_write,
	input							gpio_req,
	input		[DATA_WIDTH-1:0]	gpio_wdata,
	input		[DATA_WIDTH-1:0]	gpin,
	output							gpio_gnt,
	output							gpio_rvalid,
	output		[31:0]				gpio_rdata,
	output reg	[DATA_WIDTH-1:0]	gpout,
	output reg						irq
);

	reg	[DATA_WIDTH-1:0]	gpin_meta, gpin_sync, gpin_sync_del;
	reg rvalid;

	// Latching the input
	always @(posedge HCLK, negedge HRESETn)
		if(!HRESETn) begin
			gpin_meta <= 4'b0;
			gpin_sync <= 4'b0;
			gpin_sync_del <= 4'b0;
		end
		else	begin
			gpin_meta <= gpin;
			gpin_sync <= gpin_meta;
			gpin_sync_del <= gpin_sync;
		end
	// IRQ
	always @(posedge HCLK)
		if (!HRESETn) 								irq <= 1'b0;
		else if (gpin_sync != gpin_sync_del)		irq <= 1'b1;
		else 										irq <= 1'b0;

	// AHB
	always @(posedge HCLK)
		if (!HRESETn) 						gpout <= 0;
		else if (gpio_write & gpio_sel)		gpout <= gpio_wdata[15:0];
		else 								gpout <= gpout;
											
	always @(posedge HCLK)
		if (!HRESETn)	rvalid <= 1'b0;
		else 			rvalid <= gpio_req & gpio_sel;

	assign rdata = (!gpio_write & gpio_sel) ? {{(32-DATA_WIDTH){1'b0}}, gpin_sync} : 32'b0;
	assign gpio_gnt = gpio_sel & gpio_req;
	assign gpio_rvalid = rvalid;


endmodule