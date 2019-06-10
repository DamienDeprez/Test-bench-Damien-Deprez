
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

`timescale 1ps / 1fs

module memory #(
	// Default values (if not specified in the instantiation)
	parameter imem_addr_low   	= 32'h00000000,		// Instruction Memory	
	parameter imem_addr_high  	= 32'h00008000,	
	parameter dmem_addr_low		= 32'h20000000,		// Data Memory
	parameter dmem_addr_high   	= 32'h20008000
)(
	// AHB -----------------------------
	input  	wire 		HCLK,
	input  	wire 		HRESETn,
	input  	wire [31:0] HADDR,		// AHB transaction address
	input  	wire [2:0]	HSIZE,		// AHB size: byte, half-word or word
	input  	wire [1:0]	HTRANS,	    // AHB transfer: non-sequential only
	input  	wire [31:0]	HWDATA,		// AHB write-data
	input  	wire 		HWRITE,		// AHB write control
	output	wire [31:0]	HRDATA,		// AHB read-data
	output  wire		HREADY,		// AHB stall signal 
	
	// SEL -----------------------------
	input 	wire		MEM_SEL	// Selection from the AHB slave mux
);

	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------
	
	wire 			rst;
	
	// AHB ----------------------------
	wire 			hwen_imem, hwen_dmem;
	
	reg        		hwrite_last;
	reg  [31:0] 	haddr_last;
	
	// MEM -----------------------------
	wire			hmem_seln_imem, hmem_seln_dmem;
    reg             dmem_seln_last,imem_seln_last;
	
	wire 			imem_seln,dmem_seln;
	wire 			imem_wen,dmem_wen;
	wire [12:0] 	mem_addr, mem_addr_last, rw_imem_addr,rw_dmem_addr;
	wire [31:0] 	imem_wdata,dmem_wdata;	
	wire [31:0]		imem_wmask,dmem_wmask;

	wire [31:0] 	imem_rdata,dmem_rdata;
	wire    		imem_ready,dmem_ready;
	
	reg  [31:0] 		mem_wmask_reg;
 
 // Counter
 reg  [63:0] imem_read_byte;
 reg  [63:0] imem_read_half_word;
 reg  [63:0] imem_read_word;
 
 reg [63:0]  imem_write_byte;
 reg [63:0]  imem_write_half_word;
 reg [63:0]  imem_write_word;
 
 reg  [63:0] dmem_read_byte;
 reg  [63:0] dmem_read_half_word;
 reg  [63:0] dmem_read_word;
 
 reg [63:0]  dmem_write_byte;
 reg [63:0]  dmem_write_half_word;
 reg [63:0]  dmem_write_word;
 
 reg [1:0] htrans_prev;
 reg [2:0] hsize_prev;
 reg [31:0] haddr_prev;
 reg hwrite_prev;
 
 integer f;
 
 reg [63:0]  number_of_cycle;
 initial begin
   imem_read_byte=64'b0;
   imem_read_half_word=64'b0;
   imem_read_word=64'b0;
   
   imem_write_byte=64'b0;
   imem_write_half_word=64'b0;
   imem_write_word=64'b0;
 
   dmem_read_byte=64'b0;
   dmem_read_half_word=64'b0;
   dmem_read_word=64'b0;
 
   dmem_write_byte=64'b0;
   dmem_write_half_word=64'b0;
   dmem_write_word=64'b0;
   
   number_of_cycle = 64'b0;
   
   htrans_prev = 2'b0;
   hsize_prev = 3'b0;
   haddr_prev = 32'b0;
   hwrite_prev = 1'b0;
   
   f = $fopen("cortexm0.profile","w");
 end
 
 //$fwrite(f,"IRB %X @0x%X\n",HRDATA,HADDR);
 
 always @(posedge HCLK)
 begin
   if(HRESETn)
   begin
     number_of_cycle <= number_of_cycle + 64'b1;
     htrans_prev <= HTRANS;
     hsize_prev <= HSIZE;
     haddr_prev <= HADDR;
     hwrite_prev <= HWRITE;
   end
 end
 always@(negedge HCLK) begin
   if(HREADY & HTRANS[1]) begin
     case({HSIZE[1:0],HWRITE})
       3'b000:
         begin
           if (MEM_SEL & HADDR[31:16] == imem_addr_low[31:16]) imem_read_byte<=imem_read_byte+64'b1;
           if (MEM_SEL & HADDR[31:16] == dmem_addr_low[31:16]) dmem_read_byte<=dmem_read_byte+64'b1;
         end//read byte;
       3'b010:
         begin
           if (MEM_SEL & HADDR[31:16] == imem_addr_low[31:16]) imem_read_half_word<=imem_read_half_word+64'b1;
           if (MEM_SEL & HADDR[31:16] == dmem_addr_low[31:16]) dmem_read_half_word<=dmem_read_half_word+64'b1;
         end//read half word;
       3'b100:
         begin
           if (MEM_SEL & HADDR[31:16] == imem_addr_low[31:16]) imem_read_word<=imem_read_word+64'b1;
           if (MEM_SEL & HADDR[31:16] == dmem_addr_low[31:16]) dmem_read_word<=dmem_read_word+64'b1;
         end//read word;
       3'b001:
         begin
           if (MEM_SEL & HADDR[31:16] == imem_addr_low[31:16]) imem_write_byte<=imem_write_byte+64'b1;
           if (MEM_SEL & HADDR[31:16] == dmem_addr_low[31:16]) dmem_write_byte<=dmem_write_byte+64'b1;
         end//write byte;
       3'b011:
         begin
           if (MEM_SEL & HADDR[31:16] == imem_addr_low[31:16]) imem_write_half_word<=imem_write_half_word+64'b1;
           if (MEM_SEL & HADDR[31:16] == dmem_addr_low[31:16]) dmem_write_half_word<=dmem_write_half_word+64'b1;
         end//write half word;
       3'b101:
         begin
           if (MEM_SEL & HADDR[31:16] == imem_addr_low[31:16]) imem_write_word<=imem_write_word+64'b1;
           if (MEM_SEL & HADDR[31:16] == dmem_addr_low[31:16]) dmem_write_word<=dmem_write_word+64'b1;
         end//write word;
     endcase
   end
   if(HREADY & htrans_prev[1]) begin
     case({hsize_prev[1:0],hwrite_prev})
       3'b000:
         begin
           if(haddr_prev[31:16] == imem_addr_low[31:16]) $fwrite(f,"IRB 0x%X @ 0x%X - %d\n",HRDATA,haddr_prev,$time);
           if(haddr_prev[31:16] == dmem_addr_low[31:16]) $fwrite(f,"DRB 0x%X @ 0x%X - %d\n",HRDATA,haddr_prev,$time);
         end // read byte;
       3'b010:
         begin
           if(haddr_prev[31:16] == imem_addr_low[31:16]) $fwrite(f,"IRH 0x%X @ 0x%X - %d\n",HRDATA,haddr_prev,$time);
           if(haddr_prev[31:16] == dmem_addr_low[31:16]) $fwrite(f,"DRH 0x%X @ 0x%X - %d\n",HRDATA,haddr_prev,$time);
         end // read half word
       3'b100:
         begin
           if(haddr_prev[31:16] == imem_addr_low[31:16]) $fwrite(f,"IRW 0x%X @ 0x%X - %d\n",HRDATA,haddr_prev,$time);
           if(haddr_prev[31:16] == dmem_addr_low[31:16]) $fwrite(f,"DRW 0x%X @ 0x%X - %d\n",HRDATA,haddr_prev,$time);
         end // read word
       3'b001:
         begin
           if(haddr_prev[31:16] == imem_addr_low[31:16]) $fwrite(f,"IWB 0x%X @ 0x%X - %d\n",HWDATA,haddr_prev,$time);
           if(haddr_prev[31:16] == dmem_addr_low[31:16]) $fwrite(f,"DWB 0x%X @ 0x%X - %d\n",HWDATA,haddr_prev,$time);
         end // write byte;
       3'b011:
         begin
           if(haddr_prev[31:16] == imem_addr_low[31:16]) $fwrite(f,"IWH 0x%X @ 0x%X - %d\n",HWDATA,haddr_prev,$time);
           if(haddr_prev[31:16] == dmem_addr_low[31:16]) $fwrite(f,"DWH 0x%X @ 0x%X - %d\n",HWDATA,haddr_prev,$time);
         end // write half word
       3'b101:
         begin
           if(haddr_prev[31:16] == imem_addr_low[31:16]) $fwrite(f,"IWW 0x%X @ 0x%X - %d\n",HWDATA,haddr_prev,$time);
           if(haddr_prev[31:16] == dmem_addr_low[31:16]) $fwrite(f,"DWW 0x%X @ 0x%X - %d\n",HWDATA,haddr_prev,$time);
         end // write word

     endcase
   end
 end
 

	//----------------------------------------------------------------------------------
	//	CONTROL :
	//----------------------------------------------------------------------------------
	
	// Reset
	assign rst = (~HRESETn);

	// Record AHB transaction information
	always @(posedge HCLK or negedge HRESETn) 
	begin
		if(!HRESETn)
		begin
			hwrite_last    <= 1'b0;
			haddr_last	   <= 32'b0;
			imem_seln_last <= 1'b1;
			dmem_seln_last <= 1'b1;
		end
		else
		begin
			imem_seln_last <= hmem_seln_imem;
			dmem_seln_last <= hmem_seln_dmem;
			if (MEM_SEL)
			begin
				hwrite_last    <= HWRITE;
				haddr_last	   <= HADDR;
			end
		end
	end
	// Data read from memory
	assign HRDATA 		= (~imem_seln_last) ? imem_rdata:((~dmem_seln_last)? dmem_rdata: 32'd0) ;	
	
	// Mem select (active low)		
	assign hmem_seln_imem	= ~(MEM_SEL & (HADDR[31:16] == imem_addr_low[31:16]));
	assign hmem_seln_dmem	= ~(MEM_SEL & (HADDR[31:16] == dmem_addr_low[31:16]));

	// Write enable (active low)
	assign hwen_imem      	= (~imem_seln_last) ? ~hwrite_last : 1'b1; 
	assign hwen_dmem      	= (~dmem_seln_last) ? ~hwrite_last : 1'b1; 

		// Write mask generator (byte selection) for HD SRAM (bit wise).
	// Write mask generator (byte-selective)
	always @(posedge HCLK or negedge HRESETn) 
	begin
		if(!HRESETn)
		begin
			mem_wmask_reg <= 32'hFFFFFFFF;
		end
		else if(HREADY & HWRITE & HTRANS[1]) begin			// Select the adequate SRAM writing mask, from AHB-Lite transaction
      //if (HSIZE[1:0] != 2'b10 && HADDR[1:0] != 2'b00) begin $display("Mask : %x (%x %x) - time : %d tick\n",mem_wmask_reg,HSIZE[1:0],HADDR[1:0],$time); end
			case({HSIZE[1:0], HADDR[1:0]})
		  		// Byte writes are valid to any address
		 		4'b0000 : mem_wmask_reg <= 32'hFFFFFF00;						
		 	 	4'b0001 : mem_wmask_reg <= 32'hFFFF00FF;								
		  		4'b0010 : mem_wmask_reg <= 32'hFF00FFFF;							
		  		4'b0011 : mem_wmask_reg <= 32'h00FFFFFF;					
		  		// Halfword writes are only valid to even addresses
		  		4'b0100 : mem_wmask_reg <= 32'hFFFF0000;						
		  		4'b0110 : mem_wmask_reg <= 32'h0000FFFF;					
		 		// Word writes are only valid to word aligned addresses
		  		4'b1000 : mem_wmask_reg <= 32'h00000000;	
		  		default  : mem_wmask_reg <= 32'hFFFFFFFF;
			endcase
	  	end
	  	else 
			mem_wmask_reg <= 32'hFFFFFFFF;
	end
	
    assign HREADY       = 1'b1;//~(~(imem_wen&dmem_wen) & ~(imem_seln&dmem_seln) & ~HWRITE & MEM_SEL);//1'b1;
	
	//----------------------------------------------------------------------------------
	//	SRAM macro instantiation
	//----------------------------------------------------------------------------------
	
	assign mem_addr_last		= haddr_last[14:2] ; 
	assign mem_addr				= HADDR[14:2] ; 
	
	// IMEM
    assign rw_imem_addr  = imem_wen?mem_addr:mem_addr_last;

	assign imem_seln	= imem_wen?hmem_seln_imem:imem_seln_last; 	
	assign imem_wen		= hwen_imem;
	assign imem_wdata	= HWDATA;
    assign imem_wmask	= mem_wmask_reg;
	 
    rom imem  (    
		// IN 
		.HCLK			(HCLK),		    	// Clock (synchronous read/write)
		.HRESETn		(HRESETn),
		.addr			(rw_imem_addr),	// Address bus 

        
		// OUT
		.rdata			(imem_rdata),		// Data output bus (read)
    .cs        (1'b1)
	);
	
	// DMEM
	assign rw_dmem_addr  = dmem_wen?mem_addr:mem_addr_last;

	assign dmem_seln	= dmem_wen?hmem_seln_dmem:dmem_seln_last;  	// si write -> dmem_seln_last; si read -> hmem_seln_dmem
	assign dmem_wen		= hwen_dmem;
	assign dmem_wdata	= HWDATA;
    assign dmem_wmask	= mem_wmask_reg;
	
	ram dmem  (    
		// IN 
		.HCLK			(HCLK),		    	// Clock (synchronous read/write)
		.HRESETn		(HRESETn),
		.we		(~dmem_wen),			// Write enable (active low)
		.addr			(rw_dmem_addr),	// Address bus 
		.wdata			(dmem_wdata),		// Data input bus (write)
		.wmask			(dmem_wmask),		// Bit-wise mask for write operation
        
		// OUT
		.rdata			(dmem_rdata),		// Data output bus (read)
    .cs(~dmem_seln)
	);
endmodule	// memory
