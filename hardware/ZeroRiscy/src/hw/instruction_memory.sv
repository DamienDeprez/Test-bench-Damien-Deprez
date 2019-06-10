
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
module instruction_memory (
	input 	wire HCLK,
	input 	wire HRESETn,
	
	// From the Core
	input 	logic 			instr_req,
	output  logic   		instr_gnt,
	output  logic   		instr_rvalid,
	input 	logic   [31:0] 	instr_addr,
	output  logic   [31:0] 	instr_rdata
	);
	
	reg [31:0] instr_addr_last;
	reg instr_req_last;
	
	wire [31:0] rom_rdata;
	
	//integer f;
	reg [63:0] counter;
	
	
	initial begin
		counter = 64'b0;
		//f = $fopen("CPU-instr.profile","w");
	end
	
	always @(posedge HCLK)
	begin
			if(instr_req_last) begin
				counter <= counter + 64'b1;
				//$fwrite(f,"IRW 0x%X @ 0x%X\n",instr_rdata,instr_addr_last);
			end
	end
	
	always @(posedge HCLK or negedge HRESETn) 
	begin
		if(!HRESETn)
		begin
			instr_addr_last <= 32'b0;
			instr_req_last <= 1'b0;
		end
		else
		begin
			instr_addr_last <= instr_addr;
			instr_req_last <= instr_req;
		end
	end
	
	assign instr_gnt = instr_req;
	assign instr_rvalid = instr_req_last;
	assign instr_rdata = (instr_req_last) ? rom_rdata : 32'b0;
	
	
	//----------------------------------------------------------------------------------
	//	CONTROL :
	//----------------------------------------------------------------------------------
	
	
	
	
	rom imem  (    
		// IN 
		.HCLK		(HCLK),		    	// Clock (synchronous read/write)
		.HRESETn	(HRESETn),
		.addr		(instr_addr),	// Address bus 

        
		// OUT
		.rdata		(rom_rdata),		// Data output bus (read)
		.cs        	(instr_req)
	);
endmodule