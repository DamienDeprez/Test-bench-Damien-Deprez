
//------------------------------------------------------------------------------
// "memory.v"
//
// Authors : T. Haine, L. Moreau, D. Bol 09/2015 (UCL)
//           C. Frenkel 01/2017 (UCL)
//			 D. Bol, L. Moreau 03/2017
//			 R. Dekimpe, 10/2017 (UCL)
//
// 3 steps :
//
// 0) SRAM empty and non-readable 
// 1) SRAM initialization through JTAG (TMS high) but non-readable
// 2) After HRESETn released, SRAM readable (instructions part) and R/W-able (data part)
//
//------------------------------------------------------------------------------

module data_memory #(
	// Default values (if not specified in the instantiation)
	parameter dmem_addr_low		= 32'h00100000,		// Data Memory
	parameter dmem_addr_high   	= 32'h00108000
)(
	// AHB -----------------------------
	input  	wire 		HCLK,
	input  	wire 		HRESETn,
	input	wire		data_req,
	input	wire [31:0]	data_addr,
	input	wire [3:0]	data_be,
	input	wire 		data_sel,
	input	wire		data_write,
	input	wire [31:0]	data_wdata,
	output	wire [31:0] data_rdata,
	output	wire		data_gnt,
	output	wire		data_rvalid
	
);

	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------
	reg			data_req_last;
	reg			data_sel_last;
	reg			data_write_last;
	reg [31:0]	data_wmask;
	
	always @(posedge HCLK or negedge HRESETn)
	begin
		if(!HRESETn)
		begin
			data_req_last <= 1'b0;
			data_sel_last <= 1'b0;
			data_write_last <= 1'b0;
		end
		else
		begin
			//if(data_sel)
			//begin
				data_req_last <= data_req;
				data_sel_last <= data_sel;
				data_write_last <= data_write;
			//end
		end
	end
	
	always @(*)
	begin
		if(!HRESETn)
		begin
			data_wmask <= 32'hFFFFFFFF;
		end
		else if(data_req & data_sel)
		begin
			case(data_be)
				4'b0000 : data_wmask <= 32'h00000000;
				4'b0001 : data_wmask <= 32'h000000FF;
				4'b0010 : data_wmask <= 32'h0000FF00;
				4'b0100 : data_wmask <= 32'h00FF0000;
				4'b1000 : data_wmask <= 32'hFF000000;
				4'b0011 : data_wmask <= 32'h0000FFFF;
				4'b0110 : data_wmask <= 32'h00FFFF00;
				4'b1100 : data_wmask <= 32'hFFFF0000;
				4'b0111 : data_wmask <= 32'h00FFFFFF;
				4'b1110 : data_wmask <= 32'hFFFFFF00;
				4'b1111 : data_wmask <= 32'hFFFFFFFF;
				default : data_wmask <= 32'h00000000;
			endcase
		end
	end
	
	assign data_rvalid = (data_req_last & data_sel_last);
	assign data_gnt = (data_req & data_sel);
	
	
	
	//----------------------------------------------------------------------------------
	//	CONTROL :
	//----------------------------------------------------------------------------------
	
	
	ram dmem  (    
		// IN 
		.HCLK			(HCLK),		    // Clock (synchronous read/write)
		.HRESETn		(HRESETn),
		.we				(data_write),	// Write enable (active low)
		.addr			(data_addr[14:2]),	// Address bus 
		.wdata			(data_wdata),	// Data input bus (write)
		.wmask			(data_wmask),	// Bit-wise mask for write operation
        
		// OUT
		.rdata			(data_rdata),	// Data output bus (read)
		.cs				(data_sel)
	);
endmodule	// memory
