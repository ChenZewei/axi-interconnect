`include "axi_interface.sv"

module axi_arbiter(
	input clk,
	input reset,
   input s0_awvalid,
   input s0_arvalid,
   input s1_awvalid,
   input s1_arvalid,
	output state);
	
	typedef enum {
		MASTER_0,
		MASTER_1,
		IDEL
	} arbit_state;
	
	logic cur_state = 1'bz;
	logic cur_dir;
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
					if(s0_awvalid||s0_arvalid)
					begin
						cur_state <= 1'b0;
					end
					else if(s1_awvalid||s1_arvalid)
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
					if(s0_awvalid||s0_arvalid)
					begin
						cur_state <= 1'b0;
					end
					else if(s1_awvalid||s1_arvalid)
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
					if(s1_awvalid||s1_arvalid)
					begin
						cur_state <= 1'b1;
					end
					else if(s0_awvalid||s0_arvalid)
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