
//------------------------------------------------------------------------------
//
// "pixracer.v" - "PixRacer" SoC top-level
//
// Authors : T. Haine, L. Moreau, 09/2014 (UCL)
//			 R. Dekimpe 10/2017 (UCL)
//
//------------------------------------------------------------------------------

`timescale 1ns / 1ps

module pixracer (
	// CM0 : CLOCK AND RESET  ------------------
	input 	wire 		CLK,			   			// System clock
	input 	wire 		RSTn,						// Reset

	
	// SPI  ------------------------------------
	output 	wire 		SCK,						// SPI clock
	input   wire 		MISO,						// Master-input-slave-output
	output  wire 		MOSI,						// Master-output-slave-input
	output	wire 		SSn,						// Slave select
	
	// GPIN -----------------------------
	input	wire [15:0] GPIN,						// General purpose inputs

	// GPOUT -------- --------------------------
	output 	wire [15:0] GPOUT						// General purpose outputs
);

	//----------------------------------------------------------------------------------
	//	PARAMETERS :
	//----------------------------------------------------------------------------------
	
	// Peripherals addressing :

	localparam mem_addr_low		= 32'h00100000;		// Data memory
	localparam mem_addr_high   	= 32'h00108000;
	localparam spi_addr			= 32'h20000000;		// SPI
	localparam gpin_addr	   	= 32'h20001000;		// General purpose inputs
	localparam gpout_addr		= 32'h20002000;		// General purpose outputs

	//----------------------------------------------------------------------------------
	//	REG & WIRES :
	//----------------------------------------------------------------------------------

	// NOTE : "not used" does not mean "not to use" ;)

	//
	wire 		HCLK = CLK;
	reg 		HRESETn_sync_meta, HRESETn_sync, HRESETn_m0_sync;
	wire		HRESETn_m0;
	
	// Zero-Riscy 
	wire [31:0]	data_addr_core;
	wire 		data_req_core;
	wire 		data_we_core;
	wire [3:0]	data_be_core;
	wire [31:0]	data_wdata_core;
	wire 		data_gnt_core;
	wire		data_rvalid_core;
	wire [31:0]	data_rdata_core;
	
	wire		irq;
	wire [4:0]	irq_id_in;
	wire		irq_ack;
	wire [4:0]	irq_id_out;
		
	wire		debug_req;
	wire 		debug_gnt;
	wire		debug_rvalid;
	wire [14:0]	debug_addr;
	wire		debug_we;
	wire [31:0]	debug_rdata;
	wire [31:0] debug_wdata;
	wire 		debug_halt;
	wire 		debug_halted;
	wire		debug_resume;
		
	wire		fetch_enable;
		
	wire 		ext_perf_counters;
	
	// DATA BUS
	wire [31:0]	data_rdata_mem;
	wire		data_gnt_mem;
	wire		data_rvalid_mem;
	wire 		data_sel_mem;
	wire		data_write_mem;
		
	wire [31:0]	data_rdata_gpio;
	wire 		data_gnt_gpio;
	wire 		data_rvalid_gpio;
	wire 		data_sel_gpio;
	wire		data_write_gpio;
	
	// INSTRUCTION BUS
	wire 		instr_req;
	wire		instr_gnt;
	wire		instr_rvalid;
	wire [31:0]	instr_addr;
	wire [31:0]	instr_rdata;
	
	assign debug_req = 1'b0;
	assign debug_addr = 32'b0;
	assign debug_we = 1'b0;
	assign debug_wdata = 32'b0;
	assign debug_halt = 1'b0;
	assign debug_resume = 1'b0;
	
	assign fetch_enable = 1'b1;
	assign ext_perf_counters = 1'b0;
	
	//assign data_rdata_gpio = 32'b0;
	//assign data_gnt_gpio = 1'b0;
	//assign data_rvalid_gpio = 1'b0;
	
	//assign GPOUT = 16'b0;
	assign SCK = 1'b0;						// SPI clock
	assign MOSI = 1'b0;						// Master-output-slave-input
	assign SSn = 1'b0;						// Slave select
	
	
	
	
	
	
	//----------------------------------------------------------------------------------
	//	TMS & HRESETn sync
	//----------------------------------------------------------------------------------

	
	always @(posedge HCLK or negedge RSTn) begin
		if(~RSTn) begin
			HRESETn_sync_meta	<= 1'b0;
			HRESETn_sync		<= 1'b0;
		end else begin
			HRESETn_sync_meta	<= RSTn;
			HRESETn_sync		<= HRESETn_sync_meta;
		end
	end
	
	assign HRESETn_m0	= RSTn;
	always @(posedge HCLK or negedge HRESETn_m0) begin
		if(~HRESETn_m0) 
			HRESETn_m0_sync	<= 1'b0;
		else
			HRESETn_m0_sync	<=  HRESETn_sync;
	end
		
	//----------------------------------------------------------------------------------
	//	DATA BUS
	//----------------------------------------------------------------------------------
	
	data_bus #(
		mem_addr_low,
		mem_addr_high,
		spi_addr,
		gpin_addr,
		gpout_addr
	) data_bus_0 (
		.HCLK(HCLK),
		.HRESETn(HRESETn_m0_sync),
 
		.data_req (data_req_core),
		.data_addr (data_addr_core),
		.data_we (data_we_core),
		.data_be (data_be_core),
		.data_wdata (data_wdata_core),
		.data_gnt (data_gnt_core),
		.data_rvalid (data_rvalid_core),
		.data_rdata (data_rdata_core),
		
		.mem_rdata (data_rdata_mem),
		.mem_gnt (data_gnt_mem),
		.mem_rvalid (data_rvalid_mem),
		.mem_sel (data_sel_mem),
		.mem_write (data_write_mem),
		
		.gpio_rdata (data_rdata_gpio),
		.gpio_gnt (data_gnt_gpio),
		.gpio_rvalid (data_rvalid_gpio),
		.gpio_sel (data_sel_gpio),
		.gpio_write (data_write_gpio)
	);
	
	
	//----------------------------------------------------------------------------------
	//	JTAG
	//----------------------------------------------------------------------------------
	
	
	//----------------------------------------------------------------------------------
	//	ARM CORTEX M0 :
	//----------------------------------------------------------------------------------

	riscv_core riscv_core_0(
		.clk_i (HCLK),
		.rst_ni (HRESETn_m0_sync),
		
		.clock_en_i(1'b1),
		.test_en_i(1'b0),
		
		.core_id_i(4'b0),
		.cluster_id_i(6'b0),
		.boot_addr_i(32'h00000080),
		
		.instr_req_o(instr_req),
		.instr_gnt_i(instr_gnt),
		.instr_rvalid_i(instr_rvalid),
		.instr_addr_o(instr_addr),
		.instr_rdata_i(instr_rdata),
		
		.data_req_o(data_req_core),
		.data_gnt_i(data_gnt_core),
		.data_rvalid_i(data_rvalid_core),
		.data_we_o(data_we_core),
		.data_be_o(data_be_core),
		.data_addr_o(data_addr_core),
		.data_wdata_o(data_wdata_core),
		.data_rdata_i(data_rdata_core),
   
   .apu_master_gnt_i(1'b0),
   .apu_master_valid_i(1'b0),
   .apu_master_result_i(32'b0),
   .apu_master_flags_i(5'b0),

		
		.irq_i(irq),
		.irq_id_i(irq_id_in),
		.irq_ack_o(irq_ack),
		.irq_id_o(irq_id_out),
		
		.debug_req_i(debug_req),
		.debug_gnt_o(debug_gnt),
		.debug_rvalid_o(debug_rvalid),
		.debug_addr_i(debug_addr),
		.debug_we_i(debug_we),
		.debug_rdata_o(debug_rdata),
		.debug_wdata_i(debug_wdata),
		.debug_halt_i(debug_halt),
		.debug_halted_o(debug_halted),
		.debug_resume_i(debug_resume),
		
		.fetch_enable_i(fetch_enable),
		
		.ext_perf_counters_i(ext_perf_counters)
	);


	//----------------------------------------------------------------------------------
	//	MEMORY
	//----------------------------------------------------------------------------------
	
	data_memory #(
		mem_addr_low,
		mem_addr_high
	) data_memory_0 (
		.HCLK(HCLK),
		.HRESETn(HRESETn_sync),
		.data_req(data_req_core),
		.data_addr(data_addr_core),
		.data_be(data_be_core),
		.data_sel(data_sel_mem),
		.data_write(data_write_mem),
		.data_wdata(data_wdata_core),
		.data_rdata(data_rdata_mem),
		.data_gnt(data_gnt_mem),
		.data_rvalid(data_rvalid_mem)
	);
	
	instruction_memory instruction_memory_0
	(
		.HCLK(HCLK),
		.HRESETn(HRESETn_sync),
		.instr_req(instr_req),
		.instr_gnt(instr_gnt),
		.instr_rvalid(instr_rvalid),
		.instr_addr(instr_addr),
		.instr_rdata(instr_rdata)
	);

	//----------------------------------------------------------------------------------
	//	SPI (MASTER) 
	//----------------------------------------------------------------------------------
		
	
	
	//----------------------------------------------------------------------------------
	//	GPIO
	//----------------------------------------------------------------------------------
		gpio gpio_0
	(
		.HCLK(HCLK),
		.HRESETn(HRESETn_sync),
		.gpio_sel(data_sel_gpio),
		.gpio_write(data_write_gpio),
		.gpio_req(data_req_core),
		.gpio_wdata(data_wdata_core[15:0]),
		.gpin(GPIN),
		.gpio_gnt(data_gnt_gpio),
		.gpio_rvalid(data_rvalid_gpio),
		.gpio_rdata(data_rdata_gpio),
		.gpout(GPOUT),
		.irq(irq_gpio)
	);
	

endmodule