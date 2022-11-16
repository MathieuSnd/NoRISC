/*
    This module acts as an axi slave
    but does not contain any memory
    and always reads random values
*/
module rand_axi_slave(

	input clk, resetn,


    // AXI4-lite master memory interface
	input          awvalid,
	output         awready,
	input   [31:0] awaddr,
	input   [ 2:0] awprot,

	input          wvalid,
	output         wready,
	input   [31:0] wdata,
	input   [ 3:0] wstrb,

	output         bvalid,
	input          bready,

	input          arvalid,
	output         arready,
	input   [31:0] araddr,
	input   [ 2:0] arprot,

	output         rvalid,
	input          rready,
	output  [31:0] rdata,
);
    (* keep *) `rvformal_rand_reg [31:0] randdata;



    wire ar_handshake = arready & arvalid;
    wire r_handshake  = rready  & rvalid;

    wire aw_handshake = awready & awvalid;
    wire w_handshake  = wready  & wvalid;
    wire b_handshake  = bready  & bvalid;


    logic [31:0] read_reg;
    assign rdata = read_reg;
    


    assign arready = 1;
    always_ff @(posedge clk) begin
        if(~r_handshake)
            read_reg <= randdata;
    end


    logic w_done;
    logic aw_done;

    // always ready unless a write transaction
    // began and did not end yet
    assign awready = ~aw_done;
    assign wready  = ~w_done;



    always_ff @(posedge clk or negedge resetn) begin
        if(~resetn)
            bvalid <= '0;
        else begin
            if(w_done & aw_done)
                bvalid <= '1;
            
            if(b_handshake)
                bvalid <= '0;
        end
    end


    always_ff @(posedge clk or negedge resetn) begin
        if(~resetn) begin
            aw_done <= '0;
            w_done  <= '0;
        end
        else begin
            if(aw_handshake)
                aw_done <= '1;

            if(w_handshake)
                w_done  <= '1;


            if(b_handshake)  begin
                aw_done <= '0;
                w_done  <= '0;
            end 
        end
    end
endmodule