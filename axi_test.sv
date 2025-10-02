class axi_test extends uvm_test;
	//factory registration
	axi_base_sequence seq;
	axi_top_env top_env;

	`uvm_component_utils(axi_test)
	//memeory allcoation
	function new(string name="axi_test",uvm_component parent=null);
		super.new(name,parent);
	endfunction
		//axi_base_sequence seq;

	//we are including env
	//axi_top_env top_env;//handle creation
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		//object creation
	seq=axi_base_sequence::type_id::create("seq",this);
	top_env=axi_top_env::type_id::create("top_env",this);
	endfunction
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		// we need to connect sequence to sequncer
		//connection sequence to sqr by using start method
		// objects creation of sequnce
		phase.raise_objection(this);
		seq.start(top_env.menv.agent.seqr);
		phase.drop_objection(this);
		
	endtask
endclass
