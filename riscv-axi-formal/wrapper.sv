/*
    this module is adapted from the original picorv32 formal wrapper:
    www.github.com/YosysHQ/riscv-formal/cores/picorv32/wrapper.sv
*/
module rvfi_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);
	(* keep *) wire 	trap;

	wire resetn = !reset;


    // AXI4-lite signals
	logic        awvalid;
	logic        awready;
	logic [31:0] awaddr;
	logic [ 2:0] awprot;
	logic        wvalid;
	logic        wready;
	logic [31:0] wdata;
	logic [ 3:0] wstrb;
	logic        bvalid;
	logic        bready;
	logic        arvalid;
	logic        arready;
	logic [31:0] araddr;
	logic [ 2:0] arprot;
	logic        rvalid;
	logic        rready;
	logic [31:0] rdata;


	picorv32_axi #(
		.COMPRESSED_ISA(1),
		.ENABLE_FAST_MUL(1),
		.ENABLE_DIV(1),
		.BARREL_SHIFTER(1)
	) uut (
		.clk       (clock    ),
		.resetn    (resetn   ),
		.trap      (trap     ),

		// axi4 master interface
	    .mem_axi_awvalid (awvalid),
	    .mem_axi_awready (awready),
	    .mem_axi_awaddr  (awaddr ),
	    .mem_axi_awprot  (awprot ),
	    .mem_axi_wvalid  (wvalid ),
	    .mem_axi_wready  (wready ),
	    .mem_axi_wdata   (wdata  ),
	    .mem_axi_wstrb   (wstrb  ),
	    .mem_axi_bvalid  (bvalid ),
	    .mem_axi_bready  (bready ),
	    .mem_axi_arvalid (arvalid),
	    .mem_axi_arready (arready),
	    .mem_axi_araddr  (araddr ),
	    .mem_axi_arprot  (arprot ),
	    .mem_axi_rvalid  (rvalid ),
	    .mem_axi_rready  (rready ),
	    .mem_axi_rdata   (rdata  ),

		// rvfi interface
		`RVFI_CONN
	);

	rand_axi_slave axis (
		.clk     (clock  ),
		.resetn  (resetn ),

		.awvalid (awvalid),
		.awready (awready),
		.awaddr  (awaddr ),
		.awprot  (awprot ),
		.wvalid  (wvalid ),
		.wready  (wready ),
		.wdata   (wdata  ),
		.wstrb   (wstrb  ),
		.bvalid  (bvalid ),
		.bready  (bready ),
		.arvalid (arvalid),
		.arready (arready),
		.araddr  (araddr ),
		.arprot  (arprot ),
		.rvalid  (rvalid ),
		.rready  (rready ),
		.rdata   (rdata  )
	);


// liveness hypotheses to force the
// read and write operations to take a 
// bounded maximum time. 
// Note that it is only useful for the liveness check.

// trans_max_lat = N gives up to N-1 cycles before
// each handshake, plus N-1 cycles between the 
// operation request and the operation response.
// It results in a 2N + 1 latency cycles.
// 1-9 cycle axi write/read transactions
`ifdef PICORV32_FAIRNESS

localparam trans_max_lat = 4;

(* keep *) reg [31:0] wlat = 0, awlat = 0;
(* keep *) reg wtrans = 0, awtrans = 0;

always_ff @(posedge clock) begin
	if(awvalid)	awtrans = 1;
	if(awready)	awtrans = 0;
	if(wvalid)	wtrans  = 1;
	if(wready)	wtrans  = 0;
	
	if(awtrans) awlat = awlat + 1;
	if(wtrans)  wlat  = wlat + 1;

	assume(awlat < trans_max_lat);
	assume(wlat  < trans_max_lat);
end




(* keep *) reg [31:0] read_lat = 0, write_lat = 0;
(* keep *) reg reading = 0, writing = 0;
always_ff @(posedge clock) begin
	if(arvalid)	reading = 1;
	if(rvalid)	reading = 0;


	if(bvalid)	writing = 0;
	if(wvalid)	writing = 1;
	
	if(reading) read_lat  = read_lat + 1;
	if(writing) write_lat = write_lat + 1;

	assume(read_lat  < trans_max_lat);
	assume(write_lat < trans_max_lat);
end

`endif// PICORV32_FAIRNESS

endmodule

