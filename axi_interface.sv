interface axi_interface(input bit aclk,aresetn);
	//static
	//group of signals
		      logic[31:0]awaddr;
	      logic[3:0]awid;
	      logic awvalid;
	      logic awready;
	      logic[3:0] awcache;
	      logic[1:0]awlock;
	      logic[2:0]awprot;
	      logic[1:0]awburst;
              logic[3:0]awlen;
	      logic[2:0]awsize;
	   	//2.write data channel
	       logic[31:0] wdata;//maximum supports 1024    logics
	       logic[3:0]wstrb;//maximum 128its
	       logic wlast;
	       logic wvalid;
	       logic[3:0] wid;
	   logic wready;
	//3.write response channel
	       logic bready;
	   logic[3:0] bresp;//from slave
	   logic bvalid;
	   logic[3:0]bid;
	//4.read address channel
	       logic[31:0]araddr;
	       logic[3:0]arid;
	       logic arvalid;
	   logic arready;
	       logic[3:0] arcache;
	       logic[1:0]arlock;
	       logic[2:0]arprot;
	       logic[1:0]arburst;
               logic[3:0]arlen;
	       logic[2:0]arsize;

	//5.read data channel
	       logic rready;
	   logic[31:0] rdata;
	   logic rvalid;
	   logic[3:0] rresp;
	   logic[3:0] rid;
	   logic rlast;
	

 
endinterface
