`include "axi_interface.sv"

module axi_router(
	input clk,
	input reset,
	axi_interface.slave axi_bus_s,
	output state);
	
	logic cur_state = 1'bz;
	
	always_comb
	begin
		if(axi_bus_s.awvalid)
		begin
			if(axi_bus_s.awaddr<32'h10000000)
			begin
				cur_state = 1'b0;
			end
			else if(axi_bus_s.awaddr<32'hffffffff)
			begin
				cur_state = 1'b1;
			end
			else
			begin
				cur_state = 1'bz;
			end
		end
		else if(axi_bus_s.arvalid)
		begin
			if(axi_bus_s.araddr<32'h10000000)
			begin
				cur_state = 1'b0;
			end
			else if(axi_bus_s.awaddr<32'hffffffff)
			begin
				cur_state = 1'b1;
			end
			else
			begin
				cur_state = 1'bz;
			end
		end
	end
	
	assign state = cur_state;
	
endmodule