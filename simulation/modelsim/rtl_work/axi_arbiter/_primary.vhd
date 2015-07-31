library verilog;
use verilog.vl_types.all;
entity axi_arbiter is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        s0_awvalid      : in     vl_logic;
        s0_arvalid      : in     vl_logic;
        s1_awvalid      : in     vl_logic;
        s1_arvalid      : in     vl_logic;
        state           : out    vl_logic;
        dir             : out    vl_logic
    );
end axi_arbiter;
