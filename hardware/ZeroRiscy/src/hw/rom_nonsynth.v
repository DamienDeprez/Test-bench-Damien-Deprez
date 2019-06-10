
//------------------------------------------------------------------------------
// "rom.v"
//
// Authors : K. Nguyen 10/2015 (UCL)
//
//
//------------------------------------------------------------------------------

`timescale 1ps / 1fs

module rom (
	input	wire 		HCLK,
	input	wire		HRESETn,
	
	input  	wire [31:0]	addr,
	output 	wire [31:0]	rdata,
	input	wire 		cs
);
	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------
	reg [31:0] mem [0:8191];
  reg [31:0] mem_last;
  
  integer f;
	//----------------------------------------------------------------------------------
	//	ROM :
	//----------------------------------------------------------------------------------
	initial begin
    f = $fopen("ZeroRiscy-IMEM-O3C.profile","w");
		$readmemh("./../src/sw/code-O3C.hex", mem);
	end
 
   always @(negedge HCLK) begin
    if(cs) begin
       $fwrite(f,"IRW 0x%X @ 0x%X - %d\n",mem[addr[31:2]],addr,$time);
    end      
  end
	
  always @(posedge HCLK)
  begin
    mem_last <= cs  ? mem[addr[31:2]] : 32'b0;
  end
	assign rdata = mem_last;//(cs & mem_sel) ? mem[addr[31:2]] : 32'b0;
	
endmodule