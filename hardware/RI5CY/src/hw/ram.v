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

`timescale 1ps / 1fs

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
  
  integer f;
  
  integer k;
  
  initial
  begin
    f = $fopen("Riscv-DMEM-O3.profile","w");
    for(k = 0; k < SIZE; k = k + 1)
    begin
      mem[k] = 32'b0;
    end
    $readmemh("./../src/sw/data-O3.hex", mem);
  end
  
  always @(negedge HCLK) begin
    if(cs & ~we) begin
      case(wmask)
        32'h000000FF: $fwrite(f,"DRB 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
        32'h0000FF00: $fwrite(f,"DRB 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
        32'h00FF0000: $fwrite(f,"DRB 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
        32'hFF000000: $fwrite(f,"DRB 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
        32'h0000FFFF: $fwrite(f,"DRH 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
        32'h00FFFF00: $fwrite(f,"DRH 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
        32'hFFFF0000: $fwrite(f,"DRH 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
        32'hFFFFFFFF: $fwrite(f,"DRW 0x%X @ 0x%X - %d\n",mem[addr] & wmask,addr,$time);
      endcase
    end
    if(cs & we) begin
      case(wmask)
        32'h000000FF: $fwrite(f,"DWB 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
        32'h0000FF00: $fwrite(f,"DWB 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
        32'h00FF0000: $fwrite(f,"DWB 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
        32'hFF000000: $fwrite(f,"DWB 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
        32'h0000FFFF: $fwrite(f,"DWH 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
        32'h00FFFF00: $fwrite(f,"DWH 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
        32'hFFFF0000: $fwrite(f,"DWH 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
        32'hFFFFFFFF: $fwrite(f,"DWW 0x%X @ 0x%X - %d\n",wdata & wmask,addr,$time);
      endcase
    end
      
  end
	
	//----------------------------------------------------------------------------------
	//	RAM :
	//----------------------------------------------------------------------------------
	
	// Read
	assign rdata	= mem_last;//(cs & ~we) ? mem[addr[14:2]] : 32'b0;
 
  always @(posedge HCLK) begin
    mem_last <= (cs & ~we)  ? mem[addr] & wmask : 32'b0;
    /*if(cs & ~we) begin
      $display("Read in memory : %x with %x at %08x time = %d ps\n",mem[addr] & wmask, wmask,addr, $time);
    end*/
	end
	
	// Write
	always @(posedge HCLK or negedge HRESETn) begin
    if(HRESETn & we & cs) begin
       /*if(wmask!=32'hFFFFFFFF) begin
         
       end*/
                
       //write_data <= (mem[addr] & ~wmask) | (wdata & wmask);
       //$display("Write in memory : %x with %x at %08x time = %d ps\n",wdata,wmask, addr,$time);
       mem[addr] <= (mem[addr] & ~wmask) | (wdata & wmask);
		end
	end

endmodule