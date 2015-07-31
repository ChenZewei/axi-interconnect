`include "axi_interface.sv"

module axi_interconnect(
	input clk,
	input reset,
	axi_interface.master axi_bus_m0,//sdram controller
	axi_interface.master axi_bus_m1,//f2h_bridge 
	axi_interface.slave  axi_bus_s0,//h2f_briege
	axi_interface.slave  axi_bus_s1);//JBush core

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
	burst_state_t write_state_0;
	burst_state_t write_state_1;
	logic[31:0] write_burst_address;
	logic[7:0] write_burst_length;	// Like axi_awlen, this is number of transfers minus 1
	logic write_master_select;
	logic slave_select;
	logic dir;
	logic master_select;
	
	axi_arbiter arbiter(
	.clk(clk),
	.reset(reset),
	.s0_awvalid(axi_bus_s0.awvalid),
	.s0_arvalid(axi_bus_s0.arvalid),
	.s1_awvalid(axi_bus_s1.awvalid),
	.s1_arvalid(axi_bus_s1.arvalid),
	.state(slave_select));

	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
		begin
			write_state_0 <= STATE_ARBITRATE;
			/*AUTORESET*/
			// Beginning of autoreset for uninitialized flops
			write_burst_address <= 32'h0;
			write_burst_length <= 8'h0;
			write_master_select <= 1'h0;
			// End of automatics
		end
		else if(slave_select == 0)
		begin 
			if (axi_bus_s0.awvalid)
			begin
				// Start a new write transaction
				write_master_select <=  axi_bus_s0.awaddr >= M1_BASE_ADDRESS;
				write_burst_address <= axi_bus_s0.awaddr;
				write_burst_length <= axi_bus_s0.awlen;
				write_state_0 <= STATE_ISSUE_ADDRESS;
			end
			else if (write_state_0 == STATE_ISSUE_ADDRESS)
			begin
				// Wait for the slave to accept the address and length
				if (axi_bus_s0.awready)
					write_state_0 <= STATE_ACTIVE_BURST;
			end
			else if (write_state_0 == STATE_ACTIVE_BURST)
			begin
				// Burst is active.  Check to see when it is finished.
				if (axi_bus_s0.wready && axi_bus_s0.wvalid)
				begin
					write_burst_length <= write_burst_length - 8'd1;
					if (write_burst_length == 0)
						write_state_0 <= STATE_ARBITRATE;
				end
			end
		end
	end
	
	always_comb
	begin
		if(slave_select == 0)
		begin
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
		if (write_master_select == 0)
		begin
			// Master Interface 0 is selected
			axi_bus_m0.wvalid = axi_bus_s0.wvalid && write_state_0 == STATE_ACTIVE_BURST && slave_select == 0;
			axi_bus_m1.wvalid = 0;
			axi_bus_s0.awready = axi_bus_m0.awready && write_state_0 == STATE_ISSUE_ADDRESS && slave_select == 0;
			axi_bus_s0.wready = axi_bus_m0.wready && write_state_0 == STATE_ACTIVE_BURST && slave_select == 0;
			axi_bus_s0.bvalid = axi_bus_m0.bvalid && slave_select == 0;
			axi_bus_s1.awready = axi_bus_m0.awready && write_state_1 == STATE_ISSUE_ADDRESS && slave_select;
			axi_bus_s1.wready = axi_bus_m0.wready && write_state_1 == STATE_ACTIVE_BURST && slave_select;
			axi_bus_s1.bvalid = axi_bus_m0.bvalid && slave_select;
		end
		else
		begin
			// Master interface 1 is selected
			axi_bus_m0.wvalid = 0;
			axi_bus_m1.wvalid = axi_bus_s0.wvalid && write_state_0 == STATE_ACTIVE_BURST && slave_select == 0;
			axi_bus_s0.awready = axi_bus_m1.awready && write_state_0 == STATE_ISSUE_ADDRESS && slave_select == 0;
			axi_bus_s0.wready = axi_bus_m1.wready && write_state_0 == STATE_ACTIVE_BURST && slave_select == 0;
			axi_bus_s0.bvalid = axi_bus_m1.bvalid && slave_select == 0;
			axi_bus_s1.awready = axi_bus_m1.awready && write_state_1 == STATE_ISSUE_ADDRESS && slave_select;
			axi_bus_s1.wready = axi_bus_m1.wready && write_state_1 == STATE_ACTIVE_BURST && slave_select;
			axi_bus_s1.bvalid = axi_bus_m1.bvalid && slave_select;
		end
	end
	
	

endmodule