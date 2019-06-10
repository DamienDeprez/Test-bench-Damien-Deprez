//------------------------------------------------------------------------------
// "memory.v"
//
// Authors : T. Haine, L. Moreau, D. Bol 09/2015 (UCL)
//
// 3 steps :
//
// 0) SRAM empty and non-readable 
// 1) SRAM initialization through JTAG (TMS high) but non-readable
// 2) After HRESETn released, SRAM readable (instructions part) and R/W-able (data part)
//
//------------------------------------------------------------------------------
module ram (
	
	input  	wire 		HCLK,
	input  	wire 		HRESETn,
	input  	wire [12:0] addr,		
  input   wire [31:0] wmask,
	input  	wire [31:0]	wdata,		
	input  	wire 		we,		
	output	wire [31:0]	rdata,		
	
	
	input 	wire		cs
);

	localparam SIZE = 8191; // number of 32bit words in ram = (ZI+RW)/4

	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------

	reg [31:0]	mem	[0:SIZE];
  reg [31:0] mem_last;
  reg [31:0] write_data;
	
	//----------------------------------------------------------------------------------
	//	RAM :
	//----------------------------------------------------------------------------------
	
	// Read
	assign rdata	= mem_last;//(cs & ~we) ? mem[addr[14:2]] : 32'b0;
 
  always @(posedge HCLK) begin
    mem_last <= (cs & ~we)  ? mem[addr] : 32'b0;
	end
	
	// Write
	always @(posedge HCLK) begin
    if(HRESETn) begin
      if(we & cs) begin
       /*if(wmask!=32'hFFFFFFFF) begin
         $display("Write in memory : %x with %x at %x time = %d ps\n",wdata,wmask, addr,$time);
       end*/         
        write_data <= (mem[addr] & wmask) | (wdata & ~wmask);
        mem[addr] <= (mem[addr] & wmask) | (wdata & ~wmask);
      end
		end
	end

endmodule