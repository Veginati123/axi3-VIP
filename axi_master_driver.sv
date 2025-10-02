class axi_master_driver extends uvm_driver#(axi_tx);
	`uvm_component_utils(axi_master_driver);

	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
	endfunction
//getting pointed virtual interface from top module

	virtual axi_interface mvif;
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	uvm_config_db#(virtual axi_interface)::get(this,"","vif",mvif);
	endfunction
	int k;
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			@(posedge mvif.aclk);
			//we need to get all request from sqr
			seq_item_port.get_next_item(req);//getting data from sqr by using tlm
	//put all information into interface //wrt channels we need to write
			
			driver_to_interface(req);


			//send response to sqr
			seq_item_port.item_done();
		end
	endtask




	task driver_to_interface(axi_tx tx); //indirectly we are copying only req --> tx

		if(tx.rd==WRITE_ONLY)begin
			//write address
			write_address_channel(req);
			//write data
			write_data_channel(req);
			//write response
			write_response_channel(req);
			
		end
		if(tx.rd==READ_ONLY)begin
			//read address
			read_address_channel(req);
			//read data
			read_data_channel(req);
		end
		if(tx.rd==WRITE_THEN_READ)begin
			//write address data
			write_address_channel(req);
			//write data channel
			write_data_channel(req);
			//write response
			write_response_channel(req);
			//read address
			read_address_channel(req);
			//read data
			read_data_channel(req);
		end
		if(tx.rd==WRITE_PARALELL_READ)begin
			fork 
			begin
			//write address
			write_address_channel(req);
			//write data
			write_data_channel(req);
			//write response
			write_response_channel(req);
			end
			begin
			//read address
			read_address_channel(req);
			//read data
			read_data_channel(req);
			end

		join
		end

	endtask
	
	task write_address_channel(axi_tx req);

	
	//strobe calculation start
	
		case(req.awsize)
			0:begin end
			1:begin end
			2:begin
		       		req.wstrb=4'hf;//all bytes are active
				if(req.awaddr% (2**req.awsize) !=0)begin //unaligned addr condition
					k=req.awaddr % (2**req.awsize);
					for(int i=0;i<k;i++)begin
						req.wstrb[i]=0;
					end
				end
		
			end
			3:begin end
			4:begin end
			5:begin end
			6:begin end
			7:begin end

		endcase
	//strobe calculation ended


	//we are sending all write address channel signals to interface
	//awaddr=2 awlen=3 awsize=2 awburst=1 awid=5 send all information to
	//interface, if awready =0 maintain same addr and control information
	//untill ready=1 comes from slave.
	//note: the below code is written according to the timing diagram provided
	//in spec
	mvif.awaddr=req.awaddr;
	mvif.awvalid=1;//valid address & control info	
	mvif.awid=req.awid;
	mvif.awlen=req.awlen;
	mvif.awsize=req.awsize;
	mvif.awburst=req.awburst;
	mvif.awcache=req.awcache;
	mvif.awprot=req.awprot;
	mvif.awlock=req.awlock;
	//we need to maintain same address & control information ready comes
	//from slave
	wait(mvif.awready==1);
	@(posedge mvif.aclk);//2nd clk cycle
	mvif.awaddr=0;
	mvif.awvalid=0;	
	mvif.awid=0;
	mvif.awlen=0;
	mvif.awsize=0;
	mvif.awburst=0;
	mvif.awcache=0;
	mvif.awprot=0;
	mvif.awlock=0;
	endtask

	task write_data_channel(axi_tx req);
		mvif.bready<=1;//refer spec
	//we are sending all write data channel signals to interface
	
	for(int i=0;i<=req.awlen;i++)begin
		//2nd clock cycle 

		mvif.wdata<=req.wdata.pop_back();
		mvif.wvalid<=1;
		mvif.wid=req.wid;
		//wrt aligned and narrow transfer
		//mvif.wstrb=4'b1111;
		mvif.wstrb<=req.wstrb;
		if(i==req.awlen) mvif.wlast<=1;
		wait(mvif.wready==1);
		@(posedge mvif.aclk);
		mvif.wlast<=0;
		mvif.wvalid<=0;
  	//before gng to next transfer 
		for(int i=0;i<(2**req.awsize);i++)begin //for 2nd,3rd,4th ......beats
			req.wstrb[i]=1;
		end

	end

	endtask

	task write_response_channel(axi_tx req);
	//we are sending all write response channel signals to interface
	wait(mvif.bvalid==1);
	@(posedge mvif.aclk);
	mvif.bready=0;

	endtask

	task read_address_channel(axi_tx req);
	//we are sending all read address channel signals to interface
	mvif.araddr=req.araddr;
	mvif.arvalid=1;//valid address & control info	
	mvif.arid=req.arid;
	mvif.arlen=req.arlen;
	mvif.arsize=req.arsize;
	mvif.arburst=req.arburst;
	mvif.arcache=req.arcache;
	mvif.arprot=req.arprot;
	mvif.arlock=req.arlock;
	//we need to maintain same address & control information ready comes
	//from slave
	wait(mvif.arready==1);
	@(posedge mvif.aclk);//2nd clk cycle
	mvif.araddr=0;
	mvif.arvalid=0;	
	mvif.arid=0;
	mvif.arlen=0;
	mvif.arsize=0;
	mvif.arburst=0;
	mvif.arcache=0;
	mvif.arprot=0;
	mvif.arlock=0;

	endtask

	task read_data_channel(axi_tx req);
	//we are sending all read data channel signals to interface
	for(int i=0;i<=req.arlen;i++)begin
		mvif.rready<=1;
		wait(mvif.rvalid==1);
		@(posedge mvif.aclk);
		mvif.rready<=0;
	end
	endtask
		


endclass
