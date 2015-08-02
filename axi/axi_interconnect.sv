`include "axi_interface.sv"

module axi_interconnect(
	input clk,
	input reset,
	axi_interface.master axi_bus_m0,//sdram controller
	axi_interface.master axi_bus_m1,//f2h_bridge 
	axi_interface.slave  axi_bus_s0,//JBush core
	axi_interface.slave  axi_bus_s1);//h2f_briege

	localparam M1_BASE_ADDRESS = 32'h10000000;

	typedef enum {
		STATE_ARBITRATE,
		STATE_ISSUE_ADDRESS,
		STATE_ACTIVE_BURST
	} burst_state_t;
	
	//
	// Write handling. Only slave interface 0 does writes.
	// XXX I don't explicitly handle the response in the state machine, but it
	// works because everything is in the correct state when the transaction is finished.
	// This could introduce a subtle bug if the behavior of the core changed.
	//
	burst_state_t write_state;
	logic[31:0] write_burst_address;
	logic[7:0] write_burst_length;	// Like axi_awlen, this is number of transfers minus 1
	logic write_master_select;
	logic write_slave_select;
	//logic awvalid_check;
	/*
	axi_write_arbiter write_arbiter(
	.clk(clk),
	.reset(reset),
	.s0_awvalid(axi_bus_s0.awvalid),
	.s1_awvalid(axi_bus_s1.awvalid),
	.state(write_slave_select));*/
	/*
	assign awvalid_check = axi_bus_s0.awvalid || axi_bus_s1.awvalid;
	
	always_comb
	begin
		if(awvalid_check)
		begin
			if(write_slave_select == 1)
			begin
				write_slave_select = axi_bus_s1.awvalid?1'b1:1'b0;
			end
			else
			begin
				write_slave_select = axi_bus_s0.awvalid?1'b0:1'b1;
			end
		end
		else
		begin
			write_slave_select = 1'bz;
		end
	end*/
	
	assign axi_bus_m0.awvalid = write_master_select == 0 && write_state == STATE_ISSUE_ADDRESS;
	assign axi_bus_m1.awvalid = write_master_select == 1 && write_state == STATE_ISSUE_ADDRESS;

	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
		begin
			write_state <= STATE_ARBITRATE;
			/*AUTORESET*/
			// Beginning of autoreset for uninitialized flops
			write_burst_address <= 32'h0;
			write_burst_length <= 8'h0;
			write_master_select <= 1'h0;
			write_slave_select <= 1'h0;
			// End of automatics
		end
		else if (write_state == STATE_ACTIVE_BURST)
		begin
			// Burst is active.  Check to see when it is finished.
			if (axi_bus_s0.wready && axi_bus_s0.wvalid)
			begin
				write_burst_length <= write_burst_length - 8'd1;
				if (write_burst_length == 0)
					write_state <= STATE_ARBITRATE;
			end
		end
		else if (write_state == STATE_ISSUE_ADDRESS)
		begin
			// Wait for the slave to accept the address and length
			if (axi_bus_s0.awready)
				write_state <= STATE_ACTIVE_BURST;
		end
		else if (axi_bus_s0.awvalid)
		begin
			// Start a new write transaction
			write_master_select <=  axi_bus_s0.awaddr >= M1_BASE_ADDRESS;
			write_slave_select <= 1'h0;
			write_burst_address <= axi_bus_s0.awaddr;
			write_burst_length <= axi_bus_s0.awlen;
			write_state <= STATE_ISSUE_ADDRESS;
		end
		else if (axi_bus_s1.awvalid)
		begin
			// Start a new write transaction
			write_master_select <=  axi_bus_s1.awaddr >= M1_BASE_ADDRESS;
			write_slave_select <= 1'h1;
			write_burst_address <= axi_bus_s1.awaddr;
			write_burst_length <= axi_bus_s1.awlen;
			write_state <= STATE_ISSUE_ADDRESS;
		end
	end
	
	always_comb
	begin
		if(write_slave_select == 0)
		begin
			// Slave interface 0 is selected
			axi_bus_m0.awaddr = write_burst_address;
			axi_bus_m0.awlen = write_burst_length;
			axi_bus_m0.wdata = axi_bus_s0.wdata;
			axi_bus_m0.wlast = axi_bus_s0.wlast;
			axi_bus_m0.bready = axi_bus_s0.bready;
			axi_bus_m0.wstrb = axi_bus_s0.wstrb;
			axi_bus_m0.awburst = axi_bus_s0.awburst;
			axi_bus_m0.awsize = axi_bus_s0.awsize;
			axi_bus_m1.awaddr = write_burst_address - M1_BASE_ADDRESS;
			axi_bus_m1.awlen = write_burst_length;
			axi_bus_m1.wdata = axi_bus_s0.wdata;
			axi_bus_m1.wlast = axi_bus_s0.wlast;
			axi_bus_m1.bready = axi_bus_s0.bready;
			axi_bus_m1.wstrb = axi_bus_s0.wstrb;
			axi_bus_m1.awburst = axi_bus_s0.awburst;
			axi_bus_m1.awsize = axi_bus_s0.awsize;
		end
		else
		begin
			// Slave interface 1 is selected
			axi_bus_m0.awaddr = write_burst_address;
			axi_bus_m0.awlen = write_burst_length;
			axi_bus_m0.wdata = axi_bus_s1.wdata;
			axi_bus_m0.wlast = axi_bus_s1.wlast;
			axi_bus_m0.bready = axi_bus_s1.bready;
			axi_bus_m0.wstrb = axi_bus_s1.wstrb;
			axi_bus_m0.awburst = axi_bus_s1.awburst;
			axi_bus_m0.awsize = axi_bus_s1.awsize;
			axi_bus_m1.awaddr = write_burst_address - M1_BASE_ADDRESS;
			axi_bus_m1.awlen = write_burst_length;
			axi_bus_m1.wdata = axi_bus_s1.wdata;
			axi_bus_m1.wlast = axi_bus_s1.wlast;
			axi_bus_m1.bready = axi_bus_s1.bready;
			axi_bus_m1.wstrb = axi_bus_s1.wstrb;
			axi_bus_m1.awburst = axi_bus_s1.awburst;
			axi_bus_m1.awsize = axi_bus_s1.awsize;
		end
	end
	
	always_comb
	begin
		if(write_master_select == 0)
			begin
				// Master interface 0 is selected
				axi_bus_m0.wvalid = (axi_bus_s0.wvalid || axi_bus_s0.wvalid) && write_state == STATE_ACTIVE_BURST;
				axi_bus_m1.wvalid = 0;
				axi_bus_s0.awready = axi_bus_m0.awready && write_state == STATE_ISSUE_ADDRESS && write_slave_select == 0;
				axi_bus_s0.wready = axi_bus_m0.wready && write_state == STATE_ACTIVE_BURST && write_slave_select == 0;
				axi_bus_s0.bvalid = axi_bus_m0.bvalid && write_slave_select == 0;
				axi_bus_s1.awready = axi_bus_m0.awready && write_state == STATE_ISSUE_ADDRESS && write_slave_select == 1;
				axi_bus_s1.wready = axi_bus_m0.wready && write_state == STATE_ACTIVE_BURST && write_slave_select == 1;
				axi_bus_s1.bvalid = axi_bus_m0.bvalid && write_slave_select == 1;
			end
			else
			begin
				// Master interface 1 is selected
				axi_bus_m0.wvalid = 0;
				axi_bus_m1.wvalid = (axi_bus_s0.wvalid || axi_bus_s0.wvalid) && write_state == STATE_ACTIVE_BURST;
				axi_bus_s0.awready = axi_bus_m1.awready && write_state == STATE_ISSUE_ADDRESS && write_slave_select == 0;
				axi_bus_s0.wready = axi_bus_m1.wready && write_state == STATE_ACTIVE_BURST && write_slave_select == 0;
				axi_bus_s0.bvalid = axi_bus_m1.bvalid && write_slave_select == 0;
				axi_bus_s1.awready = axi_bus_m1.awready && write_state == STATE_ISSUE_ADDRESS && write_slave_select == 1;
				axi_bus_s1.wready = axi_bus_m1.wready && write_state == STATE_ACTIVE_BURST && write_slave_select == 1;
				axi_bus_s1.bvalid = axi_bus_m1.bvalid && write_slave_select == 1;
			end
	end

	//
	// Read handling.  Slave interface 1 has priority.
	//
	
	logic read_selected_slave;  // Which slave interface we are accepting request from
	logic read_selected_master; // Which master interface we are routing to
	logic[7:0] read_burst_length;	// Like axi_arlen, this is number of transfers minus one
	logic[31:0] read_burst_address;
	logic[1:0] read_state;
	wire axi_arready_m = read_selected_master ? axi_bus_m1.arready : axi_bus_m0.arready;
	wire axi_rready_m = read_selected_master ? axi_bus_m1.rready : axi_bus_m0.rready;
	wire axi_rvalid_m = read_selected_master ? axi_bus_m1.rvalid : axi_bus_m0.rvalid;
	
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
		begin
			read_state <= STATE_ARBITRATE;

			/*AUTORESET*/
			// Beginning of autoreset for uninitialized flops
			read_burst_address <= 32'h0;
			read_burst_length <= 8'h0;
			read_selected_master <= 1'h0;
			read_selected_slave <= 1'h0;
			// End of automatics
		end
		else if (read_state == STATE_ACTIVE_BURST)
		begin
			// Burst is active.  Check to see when it is finished.
			if (axi_rready_m && axi_rvalid_m)
			begin
				read_burst_length <= read_burst_length - 8'd1;
				if (read_burst_length == 0)
					read_state <= STATE_ARBITRATE;
			end
		end
		else if (read_state == STATE_ISSUE_ADDRESS)
		begin
			// Wait for the slave to accept the address and length
			if (axi_arready_m)
				read_state <= STATE_ACTIVE_BURST;
		end
		else if (axi_bus_s1.arvalid)
		begin
			// Start a read burst from slave 1
			read_state <= STATE_ISSUE_ADDRESS;
			read_burst_address <= axi_bus_s1.araddr;
			read_burst_length <= axi_bus_s1.arlen;
			read_selected_slave <= 2'd1;
			read_selected_master <= axi_bus_s1.araddr >= M1_BASE_ADDRESS;
		end
		else if (axi_bus_s0.arvalid)
		begin
			// Start a read burst from slave 0
			read_state <= STATE_ISSUE_ADDRESS;
			read_burst_address <= axi_bus_s0.araddr;
			read_burst_length <= axi_bus_s0.arlen;
			read_selected_slave <= 2'd0;
			read_selected_master <= axi_bus_s0.araddr[31:28] != 0;
		end
	end
	
	always_comb
	begin
		if (read_state == STATE_ARBITRATE)
		begin
			axi_bus_s0.rvalid = 0;
			axi_bus_s1.rvalid = 0;
			axi_bus_m0.rready = 0;
			axi_bus_m1.rready = 0;
			axi_bus_s0.arready = 0;
			axi_bus_s1.arready = 0;
		end
		else if (read_selected_slave == 0)
		begin
			axi_bus_s0.rvalid = axi_rvalid_m;
			axi_bus_s1.rvalid = 0;
			axi_bus_m0.rready = axi_bus_s0.rready && read_selected_master == 0; 
			axi_bus_m1.rready = axi_bus_s0.rready && read_selected_master == 1;
			axi_bus_s0.arready = axi_arready_m && read_state == STATE_ISSUE_ADDRESS;
			axi_bus_s1.arready = 0;
		end
		else 
		begin
			axi_bus_s0.rvalid = 0;
			axi_bus_s1.rvalid = axi_rvalid_m;
			axi_bus_m0.rready = axi_bus_s1.rready && read_selected_master == 0; 
			axi_bus_m1.rready = axi_bus_s1.rready && read_selected_master == 1;
			axi_bus_s0.arready = 0;
			axi_bus_s1.arready = axi_arready_m && read_state == STATE_ISSUE_ADDRESS;
		end
	end

	assign axi_bus_m0.arvalid = read_state == STATE_ISSUE_ADDRESS && read_selected_master == 0;
	assign axi_bus_m1.arvalid = read_state == STATE_ISSUE_ADDRESS && read_selected_master == 1;
	assign axi_bus_m0.araddr = read_burst_address;
	assign axi_bus_m1.araddr = read_burst_address - M1_BASE_ADDRESS;
	assign axi_bus_s0.rdata = read_selected_master ? axi_bus_m1.rdata : axi_bus_m0.rdata;
	assign axi_bus_s1.rdata = axi_bus_s0.rdata;
	assign axi_bus_m0.arburst = read_selected_master ? axi_bus_s1.arburst : axi_bus_s0.arburst;
	assign axi_bus_m0.arsize = read_selected_master ? axi_bus_s1.arsize : axi_bus_s0.arsize;

	// Note that we end up reusing read_burst_length to track how many beats are left
	// later.  At this point, the value of ARLEN should be ignored by slave
	// we are driving, so it won't break anything.
	//assign axi_bus_m0.arlen = read_burst_length;
	//assign axi_bus_m1.arlen = read_burst_length;
	

endmodule