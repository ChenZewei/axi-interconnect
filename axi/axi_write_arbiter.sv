`include "axi_interface.sv"

module axi_write_arbiter(
	input clk,
	input reset,
   input s0_awvalid,
   input s1_awvalid,
	output state);
	
	logic cur_state = 1'bz;
	
	always_ff @(posedge clk, posedge reset)
	begin
		if(reset)
		begin
			cur_state <= 1'bz;
		end
		else
		begin
			case(cur_state)
				1'bz:
				begin
					if(s0_awvalid)
					begin
						cur_state <= 1'b0;
					end
					else if(s1_awvalid)
					begin
						cur_state <= 1'b1;
					end
					else
					begin
						cur_state <= 1'bz;
					end
				end
				1'b0:
				begin
					if(s0_awvalid)
					begin
						cur_state <= 1'b0;
					end
					else if(s1_awvalid)
					begin
						cur_state <= 1'b1;
					end
					else
					begin
						cur_state <= 1'bz;
					end
				end
				1'b1:
				begin
					if(s1_awvalid)
					begin
						cur_state <= 1'b1;
					end
					else if(s0_awvalid)
					begin
						cur_state <= 1'b0;
					end
					else
					begin
						cur_state <= 1'bz;
					end
				end
			endcase
		end
	end
	
	assign state = cur_state;
	
endmodule