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

	output logic   bvalid,
	input          bready,

	input          arvalid,
	output         arready,
	input   [31:0] araddr,
	input   [ 2:0] arprot,

	output logic   rvalid,
	input          rready,
	output  [31:0] rdata
);
`ifdef RISCV_FORMAL
    (* keep *) `rvformal_rand_reg [31:0] randdata;
    (* keep *) `rvformal_rand_reg [31:0] randbits;
`else
    logic [31:0] randdata, randbits;
    always_ff @(posedge clk) begin
        randdata <= $urandom();
        randbits =  $urandom();
    end
`endif

    // random ready signals
    // some code below ensures
    // the ready/valid signals
    // respect the AXI protocol and also use these
    // bits
    wire rand_arready = randbits[0];
    wire rand_rvalid  = randbits[1];
    wire rand_awready = randbits[2];
    wire rand_wready  = randbits[3];
    wire rand_bvalid  = randbits[4];



    wire ar_handshake = arready & arvalid;
    wire r_handshake  = rready  & rvalid;

    wire aw_handshake = awready & awvalid;
    wire w_handshake  = wready  & wvalid;
    wire b_handshake  = bready  & bvalid;


    logic [31:0] read_reg;
    assign rdata = read_reg;
    


    assign arready = ~rvalid & rand_arready;

    always_ff @(posedge clk) begin
        if(arvalid)
            read_reg <= randdata;
    end


    
    logic rvalid_can_rise; // if true, it is legal for rvalid
                        // to rise
    always_ff @(posedge clk) begin
        if(~resetn) begin
            rvalid_can_rise <= '0;
            rvalid <= '0;
        end
        if(ar_handshake)
            rvalid_can_rise <= '1;
        

        if((rvalid_can_rise || ar_handshake) && rand_rvalid)
        // ar_handshake is a shortcut to allow rvalid to
        // rise right after the handshake without waiting
        // for an extra cycle
            rvalid <= '1;

        if(r_handshake) begin
            rvalid_can_rise <= '0;
            rvalid <= '0;
        end
    end



    logic w_done;
    logic aw_done;

    // always ready unless a write transaction
    // began and did not end yet
    assign awready = ~aw_done && rand_awready;
    assign wready  = ~w_done  && rand_wready;



    logic bvalid_can_rise; // if true, it is legal for bvalid
                        // to rise
    always_ff @(posedge clk) begin
        if(~resetn) begin
            bvalid_can_rise <= '0;
            bvalid <= '0;
        end
        else begin
            if(w_done & aw_done)
                bvalid_can_rise <= '1;

            // same as for rvalid 
            if((bvalid_can_rise || (w_done & aw_done)) && rand_bvalid)
                bvalid <= 1;


            if(b_handshake) begin
                bvalid_can_rise <= '0;
                bvalid <= '0;
            end

        end
    end


    always_ff @(posedge clk) begin
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