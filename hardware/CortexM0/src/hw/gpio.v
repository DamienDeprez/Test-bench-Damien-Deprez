
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
	input							clk, 
	input							reset, 
	input							sel,
	input 							read,
	input							write,
	input  		[DATA_WIDTH-1:0]	wdata,
	input  		[DATA_WIDTH-1:0]	gpin,
	output	 	[31:0] 				rdata,
	output reg 	[DATA_WIDTH-1:0] 	gpout,
	output reg						irq
	);

reg	[DATA_WIDTH-1:0]	gpin_meta, gpin_sync, gpin_sync_del;
	
// Latching the input
always @(posedge clk, posedge reset)
    if  (reset) begin
					gpin_meta <= 4'b0;
					gpin_sync <= 4'b0;
					gpin_sync_del <= 4'b0;
				end
    else        begin
					gpin_meta <= gpin;
					gpin_sync <= gpin_meta;
					gpin_sync_del <= gpin_sync;
				end
// IRQ
always @(posedge clk)
	if (reset) 								irq <= 1'b0;
	else if (gpin_sync != gpin_sync_del)	irq <= 1'b1;
	else 									irq <= 1'b0;

// AHB
always @(posedge clk)
	if (reset) 						gpout <= 0;
	else if (write & sel)    		gpout <= wdata;
	else 							gpout <= gpout;

assign rdata = (read & sel) ? {{(32-DATA_WIDTH){1'b0}}, gpin_sync} : 32'b0;


endmodule