
//------------------------------------------------------------------------------
// "jtag_slave.v"
//
// Authors : T. Haine, L. Moreau, D. Bol, K. Nguyen, 10/2015 (UCL)
//           C. Frenkel (UCL), 	01/2017 
//			 M. Schramme (UCL), 18/01/2017, RSTn instead of HRESETn,
//											Asyncronous tms_rls posedge (with TMS)
//											Additional bit for HCLK_SRC conf. reg. 
//			 R. Dekimpe (UCL), 10/2017, modifications for PixRacer
//
//------------------------------------------------------------------------------

module jtag_slave (
	input	wire		HCLK,
	input	wire		RSTn,
	// JTAG ------------------
	input	wire		TMS,		// Test mode select
	input   wire		TCK,		// Test clock
	input   wire		TDI,		// Test data input
	output  wire		TDO,		// Test data output
	
	// AHB --------------------
	output wire [31:0] HADDR,		// AHB transaction address
	output wire [ 2:0] HBURST,		// AHB burst: tied to single
	output wire        HMASTLOCK, 	// AHB locked transfer (always zero)
	output wire [ 3:0] HPROT, 		// AHB protection: priv; data or inst
	output wire [ 2:0] HSIZE,		// AHB size: byte, half-word or word
	output wire [ 1:0] HTRANS,		// AHB transfer: non-sequential only
	output wire [31:0] HWDATA,		// AHB write-data
	output wire        HWRITE		// AHB write control
);
 
	
	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------
	
	reg				tdo_reg;
	reg				data_load, addr_load;
	reg				data_load_sync_meta, data_load_sync, data_load_sync_del;
 
	
	reg [4:0]  		jtag_cnt;
	reg [15:0] 		instr_cnt;
	reg [31:0] 		jtag_data;
	
	reg				mem_sel;
	reg [15:0]		mem_addr;
	reg [31:0]		mem_wdata;
	
	reg				hwrite_sync, hwrite_sync_del;
    reg [15:0]      mem_addr_sync;
    reg [31:0]      mem_wdata_sync;
	
	reg 			tms_rls_int;
	wire			tms_rls;
	
	reg [14:0]		dummy_values;
	
	//----------------------------------------------------------------------------------
	//	Control and Data Acquisition
	//----------------------------------------------------------------------------------
    
	// JTAG counter
	always @(posedge TCK, negedge TMS)
		if(~TMS)			jtag_cnt <= 5'd0;
		else					jtag_cnt <= jtag_cnt + 5'd1;
		
		
	// JTAG counting control signals
	always @(posedge TCK, negedge TMS)
		if (~TMS) 				data_load <= 1'b0;
		else if (jtag_cnt == 5'd30)	data_load <= 1'b1;
		else 						data_load <= 1'b0;
	
	// JTAG counting control signals
	always @(posedge TCK, negedge TMS)
		if (~TMS)				addr_load <= 1'b0;
		else if (jtag_cnt == 5'd29)	addr_load <= 1'b1;
		else 						addr_load <= 1'b0;
		
	
	// Instruction counter + data acquisition 
	always @(posedge TCK, negedge TMS)
		if(~TMS)			begin          
								instr_cnt   <= 16'd0;
                                jtag_data   <= 32'd0;  
							end 
		else if(data_load) 	begin
								instr_cnt   <= instr_cnt + 16'd1;
                                jtag_data   <= { jtag_data[30:0], TDI };
							end
		else				begin
								instr_cnt   <= instr_cnt;
                                jtag_data   <= { jtag_data[30:0], TDI }; 
							end

    always @(negedge TCK)
		tdo_reg <= jtag_data[31];
				     
	assign TDO = tdo_reg;
	
	//----------------------------------------------------------------------------------
	//	AHB
	//----------------------------------------------------------------------------------
		
    // Memory write data
    always @(posedge TCK, negedge TMS)
		if(~TMS)        mem_wdata <= 32'd0;
		else if(data_load)  mem_wdata <= { jtag_data[30:0], TDI };
        else                mem_wdata <= mem_wdata;
	
	// Memory address
	always @(posedge TCK, negedge TMS)
		if(~TMS)        mem_addr  <= 16'd0;
		else if(addr_load)	mem_addr  <= instr_cnt;
        else                mem_addr  <= mem_addr;
	
	// synchronization of data_load signal
	always @(posedge HCLK, negedge RSTn) begin
		if(~RSTn) begin
			data_load_sync_meta	<= 1'b0;
			data_load_sync		<= 1'b0;
			data_load_sync_del	<= 1'b0;
		end
		else begin
			data_load_sync_meta	<= data_load;
			data_load_sync		<= data_load_sync_meta;
			data_load_sync_del	<= data_load_sync;
		end
	end
	
		
	// Generation of the write command
	always @(posedge HCLK, negedge RSTn) begin
		if(~RSTn) begin
			hwrite_sync	    	<= 1'b0;
			hwrite_sync_del		<= 1'b0;
		end
		else begin // single-cycle write on the rising edge of data_load
			if (~data_load_sync & data_load_sync_del) 	hwrite_sync <= 1'b1;
			else 										hwrite_sync <= 1'b0;
			hwrite_sync_del		<= hwrite_sync;
		end
	end
	
   	// synchronisation
	always @(posedge HCLK, negedge RSTn) begin
		if(~RSTn) mem_addr_sync      	<= 16'b0; 
		else if (hwrite_sync)		mem_addr_sync  <= mem_addr; 
		else					mem_addr_sync <= mem_addr_sync;
	end
	always @(posedge HCLK, negedge RSTn) begin
		if(~RSTn) mem_wdata_sync     	<= 32'b0; 
		else if (hwrite_sync_del)	mem_wdata_sync <= mem_wdata; // One cycle later as the AHB write transfer takes two cycles
		else					mem_wdata_sync <= mem_wdata_sync;
	end
	
    // synchronized release of TMS when final write done for proper processor reset
	always @(posedge HCLK, negedge RSTn)
        if (~RSTn)         	tms_rls_int <= 1'b0;
        else if (TMS)       tms_rls_int <= 1'b1;
        else if (~HWRITE)   tms_rls_int <= 1'b0;
        else                tms_rls_int <= tms_rls_int;
	
	assign tms_rls = tms_rls_int;
	
	// AHB signals  (TCK to HCLK)
	assign HADDR	= {8'b0,mem_addr_sync,2'b0};
	assign HWDATA	= mem_wdata_sync;
	assign HWRITE	= hwrite_sync_del & tms_rls;
	assign HBURST	= 3'b0;            
	assign HMASTLOCK= 1'b0;         
	assign HPROT	= 4'b0011;             
	assign HSIZE	= 3'b010;            
	assign HTRANS	= {hwrite_sync_del,1'b0};      // This avoids reading the memory at all time when not in write.   

    
endmodule