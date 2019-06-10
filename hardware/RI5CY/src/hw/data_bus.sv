module data_bus#(
	parameter mem_addr_low		= 32'h00100000,		// Data memory
	parameter mem_addr_high   	= 32'h00108000,
	parameter spi_addr			= 32'h20000000,		// SPI
	parameter gpin_addr	   		= 32'h20001000,		// General purpose inputs
	parameter gpout_addr		= 32'h20002000		// General purpose outputs
	
) (
	input 	wire HCLK,
	input 	wire HRESETn,
	
	// From the Core
	input 	logic 			data_req,
	input 	logic   [31:0] 	data_addr,
	input 	logic 			data_we,
	input	logic	[3:0]	data_be,
	input	logic	[31:0]	data_wdata,
	output  logic   		data_gnt,
	output  logic   		data_rvalid,
	output  logic   [31:0] 	data_rdata,
	
	// To the data memory
	input  	logic	[31:0]	mem_rdata,
	input  	logic 			mem_gnt,
	input	logic			mem_rvalid,
	output 	logic			mem_sel,
	output 	logic			mem_write,
	
	
	// To the GPIO
	input 	logic 	[31:0]	gpio_rdata,
	input 	logic			gpio_gnt,
	input	logic			gpio_rvalid,
	output 	logic			gpio_sel,
	output 	logic			gpio_write
	
	);
	
	
	reg [31:0] 	data_rdata_reg;
	reg 		data_gnt_reg;
	reg			mem_read_last;
	reg			gpio_read_last;
	reg 		data_req_last;
	reg			data_rvalid_reg;
	
	
	integer f;
	reg [63:0] read_byte;
	reg [63:0] read_half;
	reg [63:0] read_word;
	reg [63:0] write_byte;
	reg [63:0] write_half;
	reg [63:0] write_word;
	
	
	initial begin
		read_byte = 64'b0;
		read_half = 64'b0;
		read_word = 64'b0;
		write_byte = 64'b0;
		write_half = 64'b0;
		write_word = 64'b0;
		f = $fopen("CPU-data.profile","w");
	end
	
	always @(posedge HCLK)
	begin
			if(data_req_last) begin
				read_byte <= read_byte + 64'b1;
				//$fwrite(f,"IR 0x%X @ 0x%X\n",data_rdata,data_addr_last);
			end
	end
	
	always @(posedge HCLK or negedge HRESETn) 
	begin
		if(!HRESETn)
		begin
			data_req_last = 1'b0;
			mem_read_last = 1'b0;
			gpio_read_last = 1'b0;
		end
		else
		begin
			data_req_last <= data_req;
			mem_read_last <= mem_sel;
			gpio_read_last <= gpio_sel;
		end
	end
	
	always @(*)
	begin
		if(data_addr >= mem_addr_low & data_addr < mem_addr_high)
		begin
			data_gnt_reg = mem_gnt;
		end
		else if(data_addr == gpin_addr)
		begin
			data_gnt_reg = gpio_gnt;
		end
		else
		begin
			data_rdata_reg = 32'b0;
			data_gnt_reg = 1'b0;
			data_rvalid_reg = 1'b0;
		end
	end
	
	assign data_gnt = mem_sel?mem_gnt:(gpio_sel?gpio_gnt:1'b0);
	assign data_rvalid = mem_read_last?mem_rvalid:(gpio_read_last?gpio_rvalid:1'b0);
	assign data_rdata = mem_read_last?mem_rdata:(gpio_read_last?gpio_rdata:32'b0);
	
	assign mem_sel = (data_addr >= mem_addr_low & data_addr < mem_addr_high) & data_req;
	assign gpio_sel = (data_addr == gpin_addr | data_addr == gpout_addr) & data_req;
	
	assign mem_write = (data_addr >= mem_addr_low & data_addr < mem_addr_high) & data_req & data_we;
	assign gpio_write = (data_addr == gpin_addr | data_addr == gpout_addr) & data_req & data_we; 
	
endmodule