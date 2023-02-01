module rvfi_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);

	(* keep *) `rvformal_rand_reg [31:0] mem_rdata;
	(* keep *) `rvformal_rand_reg [31:0] instr_rdata;

	(* keep *) wire [31:0] instr_addr;
	(* keep *) wire        instr_valid;
	(* keep *) wire        mem_valid;
	(* keep *) wire [31:0] mem_addr;
	(* keep *) wire [31:0] mem_wdata;
	(* keep *) wire        mem_wenable;

	RISC #(
	) uut (
		.clk       (clock    ),
		.reset_n    (!reset   ),
    
    // RAM contenant les données
    .d_address      (mem_addr),
    .d_data_read    (mem_rdata),
    .d_data_write   (mem_wdata),
    .d_write_enable (mem_wenable),
    .d_data_valid   (mem_valid),
    
    // ROM contenant les instructions
    .i_address(instr_addr),
    .i_data_read(instr_rdata),
    .i_data_valid(instr_valid),

	 `RVFI_CONN
	);
endmodule

