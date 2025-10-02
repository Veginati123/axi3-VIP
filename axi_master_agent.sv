class axi_master_agent extends uvm_agent;
	//factory registration
	`uvm_component_utils(axi_master_agent)
	//memeory allocation
     function new(string name="",uvm_component parent=null);
	     super.new(name,parent);
     endfunction
      //is_active=UVM_PASSIVE;(default uvm agent is active )
     //axi_sequencer ,axi_driver,axi_monitor
     axi_sequencer seqr;
     axi_master_driver mdrv;
     axi_monitor mon;
     function void build_phase(uvm_phase phase);
	     super.build_phase(phase);
	    // if(get_is_active=="UVM_ACTIVE")begin
	     seqr=axi_sequencer::type_id::create("seqr",this);
	     mdrv=axi_master_driver::type_id::create("mdrv",this);
     //end
	     mon=axi_monitor::type_id::create("mon",this);
     endfunction
     //we need to connect seqr to driver
     //mon to sco
     //mon to cov
     //connect phase
     function void connect_phase(uvm_phase phase);
	     super.connect_phase(phase);
	     // connection from port to import

	     mdrv.seq_item_port.connect(seqr.seq_item_export);
     endfunction
endclass
