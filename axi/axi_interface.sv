`ifndef __AXI_INTERFACE_SV
`define __AXI_INTERFACE_SV
interface axi_interface;
	//write address channel
	logic[3:0] awid;
	logic[31:0] awaddr;
	logic[7:0] awlen;
	logic[2:0] awsize;
	logic[1:0] awburst;
	logic awlock;
	logic[3:0] awcache;
	logic[2:0] awprot;
	logic awvalid;
	logic awready;
	logic[3:0] awqos;
	logic[3:0] awregion;
	
	//write data channel
	logic[31:0] wdata;
	logic[3:0] wstrb;
	logic wlast;
	logic wvalid;
	logic wready;
	
	//write response channel
	logic[3:0] bid;
	logic[1:0] bresp;
	logic bvalid;
	logic bready;
	
	//read address channel
	logic[3:0] arid;
	logic[31:0] araddr;
	logic[7:0] arlen;
	logic[2:0] arsize;
	logic[1:0] arburst;
	logic arlock;
	logic[3:0] arcache;
	logic[2:0] arprot;
	logic arvalid;
	logic arready;
	logic[3:0] arqos;
	logic[3:0] arregion;
	
	//read data channel
	logic[3:0] rid;
	logic[31:0] rdata;
	logic[1:0] rresp;
	logic rlast;
	logic rvalid;
	logic rready;
	
	modport master(input awready, wready, bid, bresp, bvalid, rid, rdata, rresp, rlast, rvalid, arready,
					output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid, awqos, 
					awregion, wdata, wstrb, wlast, wvalid, bready, arid, araddr, arlen, arsize, arburst, 
					arlock, arcache, arprot, arvalid, arqos, arregion, rready);
	modport slave (output awready, wready, bid, bresp, bvalid, rid, rdata, rresp, rlast, rvalid, arready,
					input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid, awqos, 
					awregion, wdata, wstrb, wlast, wvalid, bready, arid, araddr, arlen, arsize, arburst, 
					arlock, arcache, arprot, arvalid, arqos, arregion, rready);
endinterface

`endif