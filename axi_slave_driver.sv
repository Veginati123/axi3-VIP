class axi_slave_driver extends uvm_driver#(axi_tx);
	`uvm_component_utils(axi_slave_driver)
	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	virtual axi_interface svif;
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual axi_interface)::get(this,"*","vif",svif))begin
			`uvm_fatal(get_full_name(),"FATAL ERROR SLAVE DRIVER");end
	endfunction
	//create memory
	reg [7:0] mem [1000]; //mem[0] mem[1] mem[2]
	int count,j;
	bit [7:0] byte_count;//used to temp_size/8
	axi_tx wr_tx[int];//associative array
	axi_tx rd_tx[int];//associative array
	bit [3:0] response_id;//used to copy the write data id to response id
	bit [3:0] temp_read_id;//used to store read first id
	int temp_size;//mainly used to store the size of wdata	
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			@(posedge svif.aclk);//vid36:t1,t2,t3,t8
			if(svif.aresetn==0)begin //0-slave in reset state,memory in reset state
				//all outputs need to make 0 or x
				svif.awready<=1'bx;
				
				svif.wready<=1'bx;
				
				svif.bvalid<=1'bx;
				svif.bresp<=2'bxx;
				svif.bid<=4'bxxxx;
				
				svif.arready<=1'bx;
				
				svif.rvalid<=1'bx;
				svif.rdata<=32'hxxxxxxxx;				
				svif.rid<=4'bxxxx;
				svif.rresp<=2'bxx;
				svif.rlast<=1'bx;
				for(int i=0;i<1000;i++)begin
					mem[i]=0;
				end

			end//aresetn=1
			else begin //svif.aresetn=1

//*******************************************************************************		
//STEP 1: Master sending invalid information
//*******************************************************************************
				//slave need to check master sending valid
				//information or not
				//1.write address channel
				if(svif.awvalid==0)//master not sending valid address & control information
					svif.awready<=0;//slave not ready to receive the address & control information
				//2.write data channel
				if(svif.wvalid==0)
					svif.wready<=0;
				//3.write response channel
				if(svif.bready==0)//master is not ready to receive response from slave
					svif.bvalid<=0;
				//4.read address channel
				if(svif.arvalid==0)
					svif.arready<=0;
				//5.read data channel
				if(svif.rready==0)//master not ready to receive the data from slave
					svif.rvalid<=0;

//*******************************************************************************		
//STEP 2: Master sending valid information or master is ready to receive response
//*******************************************************************************

//let say master is sending:
//1st transaction: awaddr=0 [aligned]    awid=5  awlen=3 awsize=2 awburst=1 awcache=0 awprot=0 awlock=0 awvalid=1 
//2nd transaction: awaddr=22[un aligned] awid=10 awlen=3 awsize=2 awburst=1 awcache=0 awprot=0 awlock=0 awvalid=1 

 				fork
				//1.write address channel
				if(svif.awvalid==1)begin//master sending valid address & control information
					svif.awready<=1;//slave ready to receive the address & control information

//here we need to implement how my slave is gng to receive the addr & contol information if the info is valids.
				
				wr_tx[svif.awid]=new();//vid36:creating memory of wr_tx[5]=new();(t2 clk cycle)         wr_tx[10]=new()(t3 clk cycle)
				wr_tx[svif.awid].awaddr=svif.awaddr;      //wr_tx[5].awaddr=2       wr_tx[10].awaddr=20 //similarly for all other signals      				
				wr_tx[svif.awid].awlen=svif.awlen;
				wr_tx[svif.awid].awsize=svif.awsize;
				wr_tx[svif.awid].awcache=svif.awcache;
				wr_tx[svif.awid].awprot=svif.awprot;
				wr_tx[svif.awid].awlock=svif.awlock;
				wr_tx[svif.awid].awburst=svif.awburst;
				wr_tx[svif.awid].awid=svif.awid;

				end
				//2.write data channel
				if(svif.wvalid==1)begin//master sending valid data,let say handshake of wvalid & wready happens at 2nd clk cycle//vid36:t3 clk cycle
					svif.wready<=1;//slave also ready to receive the data
					temp_size=$size(svif.wdata);
					byte_count=temp_size/8;
//slave need to receive all the data wrt awlen,awsize,wstb
//how many beats i need to receive
//slave needs to know how many beats of data master is sending
			if(wr_tx[svif.wid].awburst==1)begin //INCRIMENT TXN
				
				//foreach (svif.wdata[j]) if(j%8==0) byte_count++;

				for(int i=0;i<=wr_tx[svif.wid].awlen;i++)begin //wr_tx[5].awlen=3 //this for loop is used to tell how many beats it should gothrough.//vid36:t3 id=5,t8 id=10
 			//2nd clock cycle wid=5 wdata=32'h11223344 wstb=4'b1111 ==>master is generating
 			//3rd clock cycle wid=5 wdata=32'haabbccdd wstb=4'b1111
 			//4th clock cycle wid=5 wdata=32'h55667788 wstb=4'b1111
 			//5th clock cycle wid=5 wdata=32'h1a1b1c1d wstb=4'b1111
			//second transaction data
		        //7th clock cycle wid=10 wdata=32'h118899aa wstrb=4'b1100
		        //8th clock cycle wid=10 wdata=32'hafcfdfff wstrb=4'b1111
		        //9th clock cycle wid=10 wdata=32'h65723411 wstrb=4'b1111
	  		@(posedge svif.aclk);		
			$display("[INCR WRITE]inside awlen for: beat no is=%d and less than %d, start_addr=%h current_beat_data=%h, wstrb=%h",i,wr_tx[svif.wid].awlen,wr_tx[svif.wid].awaddr,svif.wdata,svif.wstrb);	

				//foreach (svif.wdata[j]) if(i%8==0) byte_count++;
				//or temp_variable = $size(svif.wdata);

				case(wr_tx[svif.wid].awsize)//vid36:t3 wr_tx[5].awsize=2

					0:begin //1byte is active in each beat
					count=0;
					for(int i=0;i<128;i++)begin //this for loop is used to generate each addr loc to each byte
						if(svif.wstrb[i]==1)begin
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
							count=count+1;

						end
					end
					/*wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % (2**wr_tx[svif.wid].awsize);
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + (2**wr_tx[svif.wid].awsize);*/
					                     //(or)
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);
				//or 	wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % (temp_variable/8));
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;
					//$display("[INCR WRITE]: byte num=%0d,start_addr=%0h,current_beat_data=%0h",i,wr_tx[svif.wid].awaddr,svif.wdata);
		
					end
					1:begin //2bytes is active in each beat
					count=0;
					for(int i=0;i<128;i++)begin
						if(svif.wstrb[i]==1)begin
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
							count=count+1;
						end
					end
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;
		
					end
					2:begin //4bytes is active in each beat
//					case(svif.wstrb)
//							4'b1111:begin
//								//slave needs to receive all bytes of each beat      //8th clk    9th clk [second txn]    
//2nd clk    3rd clk   4th clk    5th clk[frst txn]		//first beat data need to store memory wrt addr      /*mem[24]=ff   mem[28]=11  */	
///*mem[0]=44 mem[4]=dd mem[8]=88  mem[12]=1d*/			mem[wr_tx[svif.wid].awaddr]  =svif.wdata[7:0];       /*mem[24+1]=df mem[29]=34  */	
///*mem[1]=33 mem[5]=cc mem[9]=77  mem[13]=1c*/			mem[wr_tx[svif.wid].awaddr+1]=svif.wdata[15:8];      /*mem[24+2]=cf mem[30]=72  */	
///*mem[2]=22 mem[6]=bb mem[10]=66 mem[14]=1b*/			mem[wr_tx[svif.wid].awaddr+2]=svif.wdata[23:16];     /*mem[24+3]=af mem[31]=65  */	
///*mem[3]=11 mem[7]=aa mem[11]=55 mem[15]=1a*/			mem[wr_tx[svif.wid].awaddr+3]=svif.wdata[31:24];
//								end
////when master sending unaligned addr,in that time master also sending which
////bytes are active out of multiple by wstrb 
//							4'b1110:begin
//								mem[wr_tx[svif.wid].awaddr]  =svif.wdata[15:8];
//								mem[wr_tx[svif.wid].awaddr+1]=svif.wdata[23:16];
//								mem[wr_tx[svif.wid].awaddr+2]=svif.wdata[31:24];
//								end
//							4'b1100:begin
////7th clk[second txn]			                                //first beat data need to store memory wrt addr
///*mem[22]=88*/					       		mem[wr_tx[svif.wid].awaddr]  =svif.wdata[23:16];
///*mem[23]=11*/							mem[wr_tx[svif.wid].awaddr+1]=svif.wdata[31:24];
//								end
//							4'b1000:begin
//								mem[wr_tx[svif.wid].awaddr]=svif.wdata[31:24];
//								end
//						endcase
					
					count=0;
					for(int i=0;i<128;i++)begin
						if(svif.wstrb[i]==1)begin //1100
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
					//1st transaction id=5
					//first beat
				        //mem[2+0]=svif.wdata[23:16];22
					//mem[2+1]=svif.wdata[31:24];11
					//
					//second beat
					//mem[4+0]=wdata[7:0] dd
					//mem[4+1]=wdata[15:8] cc
					//mem[4+2]=wdata[23:16] bb
					//
					//third beat
					//mem[8+0]=wdata[7:0] 88
					//mem[8+1]=wdata[15:8] 77
					//mem[8+2]=wdata[23:16] 66
					//mem[8+3]=wdata[31:24] 55
					//
					//fourth beat
					//mem[12+0]=wdata[7:0] 1d
					//mem[12+1]=wdata[15:8] 1c
					//mem[12+2]=wdata[23:16] 1b
					//mem[12+3]=wdata[31:24] 1a
				
					//second transaction id=10
					//1st beat
					//mem[20+0]=wdata[7:0] 23 	
                                	//mem[20+1]=wdata[15:8] 85
                                	//mem[20+2]=wdata[23:16] 67
                                	//mem[20+3]=wdata[31:24] 15
					//2nd beat
					//mem[24+0]=wdata[7:0] 88	
                                	//mem[24+1]=wdata[15:8] 00
                                	//mem[24+2]=wdata[23:16] 55
                                	//mem[24+3]=wdata[31:24] 77
					//3rd beat
					//mem[28+0]=wdata[7:0] 33	
                                	//mem[28+1]=wdata[15:8] 44
                                	//mem[28+2]=wdata[23:16] 99
                                	//mem[28+3]=wdata[31:24] 11
					
					

					//$display("[INCR WRITE]:inside case: byte num=%0d,start_addr=%0h,current_beat_data=%0h",i,wr_tx[svif.wid].awaddr,svif.wdata);
							


					
							count=count+1;
						end
					end
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);//converting unaligned to aligned
					//vid36:id=5==> 0;id =10 ==>20
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;//calculating next beat start address
					//vid36:id=5==> 0+4=4 8 12; id=10=> 24
		
					end	
					3:begin //8bytes is active in each beat
					count=0;
					for(int i=0;i<128;i++)begin
						if(svif.wstrb[i]==1)begin
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
							count=count+1;
						end
					end
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);//converting unaligned to aligned
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;//calculating next beat start address

					end
					4:begin //16bytes is active in each beat
					count=0;
					for(int i=0;i<128;i++)begin
						if(svif.wstrb[i]==1)begin
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
							count=count+1;
						end
					end
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;

					end
					 
					
					5:begin //32bytes is active in each beat
					count=0;
					for(int i=0;i<128;i++)begin
						if(svif.wstrb[i]==1)begin
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
							count=count+1;
						end
					end
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;

					end
					6:begin //64bytes is active in each beat
					count=0;
					for(int i=0;i<128;i++)begin
						if(svif.wstrb[i]==1)begin
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
							count=count+1;
						end
					end
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;

					end
					7:begin //128bytes is active in each beat
					count=0;
					for(int i=0;i<128;i++)begin
						if(svif.wstrb[i]==1)begin
							mem[wr_tx[svif.wid].awaddr+count]=svif.wdata[i*8 +: 8];
							count=count+1;
						end
					end
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr -(wr_tx[svif.wid].awaddr % byte_count);
					wr_tx[svif.wid].awaddr =wr_tx[svif.wid].awaddr + byte_count;

					end
				endcase
			//step1: convert unaligned to aligned address
			//note: you can convert aligned address also same result you will get
				//wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr - (wr_tx[svif.wid].awaddr % (2**wr_tx[svif.wid].awsize);

		//2nd clk cycle awaddr => 0-(0%4) = 0-0=0
		//3rd clk cycle awaddr => 4-(4%4) = 4-0=4
		//4th clk cycle awaddr => 8-(8%4) = 8-0=8
		//second transaction data
		//7th clk cycle awaddr => 22-(22%4)=22-2=20
		//8th clk cycle awaddr => 24-(24%4)=24-0=24
		//9th clk cycle awaddr => 28-(28%4)=28-0=28
		//




			     //	wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr + (2**wr_tx[svif.wid].awsize);


	//2nd clk cycle wr_tx[5].awaddr=> 0+2^2=0+4=4  //next starting addr
	//3rd clk cycle wr_tx[5].awaddr=> 4+2^2=4+4=8  //next starting addr
	//4th clk cycle wr_tx[5].awaddr=> 8+2^2=4+4=12 //next starting addr
	//second transaction data
	//7th clk cycle wr_tx[10].awaddr=>20+2^2=20+4=24
	//8th clk cycle wr_tx[10].awaddr=>24+2^2=24+4=28
	//9th clk cycle wr_tx[10].awaddr=>28+2^2=28+4=32


				//every beat will check wlast hign or not,at
				//any clk cycle wlast is high then store wid
				//to response_id
				if(svif.wlast==1)begin//last transfer or last beat of data
					response_id=svif.wid;
				end
					response_id=svif.wid;
				
				//@(posedge svif.aclk); //3rd->4th->5th[last]->6th clk(comes out of for loop)->8th clk->9th clk
				//vid36:first txn t4,t5,t6,t7 then for loop ends
				//vid36:second txn t9,t10



				if(svif.awvalid==1)begin//master sending valid address & control information //vid36: t4 awid=20
					svif.awready<=1;//slave ready to receive the address & control information 

				wr_tx[svif.awid]=new();
				wr_tx[svif.awid].awaddr=svif.awaddr;         				
				wr_tx[svif.awid].awlen=svif.awlen;
				wr_tx[svif.awid].awsize=svif.awsize;
				wr_tx[svif.awid].awcache=svif.awcache;
				wr_tx[svif.awid].awprot=svif.awprot;
				wr_tx[svif.awid].awlock=svif.awlock;
				wr_tx[svif.awid].awburst=svif.awburst;
				wr_tx[svif.awid].awid=svif.awid; //vid:36 it will go to second for loop with same id =5 since master generating the id,3rd for

				end

				end //for-awlen
					//3.write response channel
				if(svif.bready==1)begin//master is ready to receive response from slave
					svif.bvalid<=1;//slave also ready to send response
					//bid and bresp from slave
					svif.bresp<=2'b00;//ok response
					svif.bid<=response_id;
				end //write response channel ended


			end//awburst
		end//wvalid

		
//***************************************************WRITE RESPONSE CHANNEL START*********************************************//

				//3.write response channel
				/*if(svif.bready==1)begin//master is ready to receive response from slave
					svif.bvalid<=1;//slave also ready to send response
					//bid and bresp from slave
					svif.bresp<=2'b00;//ok response
					svif.bid<=response_id;
				end*/
//***************************************************WRITE RESPONSE CHANNEL END*********************************************//
//***************************************************READ ADDRESS CHANNEL START*********************************************//

				//4.read address channel
				if(svif.arvalid==1)begin
					svif.arready<=1;
					rd_tx[svif.arid]=new();//vid36: creating memory of rd_tx[5]=new();(t3 clk cycle); rd_tx[10]=new()(t4 clk cycle);rd_tx[20](t5clk cycle)
					rd_tx[svif.arid].araddr=svif.araddr;           				
					rd_tx[svif.arid].arlen=svif.arlen;
					rd_tx[svif.arid].arsize=svif.arsize;
					rd_tx[svif.arid].arcache=svif.arcache;
					rd_tx[svif.arid].arprot=svif.arprot;
					rd_tx[svif.arid].arlock=svif.arlock;
					rd_tx[svif.arid].arburst=svif.arburst;
					rd_tx[svif.arid].arid=svif.arid;

				end

//***************************************************READ ADDRESS CHANNEL END*********************************************//
//***************************************************READ DATA CHANNEL START*********************************************//

				//5.read data channel
				if(svif.rready==1)begin//master ready to receive the data from slave//vid36:t4
					svif.rvalid<=1;

					if(rd_tx.size()>0)begin //if some address is avl then only need to send real data//vid36:at t4 size 2;t5 size 3;t9 size=2
						rd_tx.first(temp_read_id);

						//increment
						if(rd_tx[temp_read_id].arburst==1)begin
			//how many beats of data need to send from memory
						for(int i=0;i<=rd_tx[temp_read_id].arlen;i++)begin //for{
					//what is the size of beat
					//$display("INCREMENT READ TXN1: beat num=%0d,start_addr=%0h,current_beat_data=%0h",i,rd_tx[temp_read_id].araddr,svif.rdata);
						case(rd_tx[temp_read_id].arsize)
							0:begin end
							1:begin end
							2:begin //rdata 128 bytes awsize=2 only 4 bytes are active
						       
				//convert unaligned address to aligned address
				rd_tx[temp_read_id].araddr=rd_tx[temp_read_id].araddr - (rd_tx[temp_read_id].araddr % ( 2**rd_tx[temp_read_id].arsize));
							count=0;
							for(int i=0;i<(2**rd_tx[temp_read_id].arsize);i++)begin //4 times
								svif.rdata[i*8 +: 8]=mem[rd_tx[temp_read_id].araddr + count];
					//vid36:
					//svif.rdata[7:0] =mem[0+0] --00
					//default value
					//svif.rdata[15:8]=mem[0+1] --00
					//svif.rdata[23:16]=mem[0+2] --22
					//svif.rdata[31:24]=mem[0+3] --11
					//rdata=32'h11220000

					//rdata=mem[4]
					//rdata=mem[5]
					//rdata=mem[6]
					//rdata=mem[7] --
					//rdata=32'haabbccdd(2nd beat)
					//rdata=mem[8]
					//rdata=mem[9]
					//rdata=mem[10]
					//rdata=mem[11]
					//rdata=32'h55667788(3rd beat)
					//
					//mem[12]
					//mem[13]
					//mem[14]
					//mem[15]
					//rdata=32'h1a1b1c1d(4th beat , 
					//1st txn completed at t7th clk cycle)
					//
					//2nd txn start
					//rdata[7:0] mem[20] 23
					//rdaat[15:8] mem[21] 85
					//rdata[23:16] mem[22] 67
					//rdaat[31:24] mem[23] 15
					//
					//
							count=count + 1;

							end
							svif.rid=temp_read_id;
							svif.rresp<=2'b00;//ok response
							if(i==rd_tx[temp_read_id].arlen) svif.rlast<=1;
							end

							3:begin end
							4:begin end
							5:begin end
							6:begin end
							7:begin end
						endcase

				//next beat start address

				//$display(" INCRIMENT READ TRASNACTION2 beat number %d start_addr=%h curreant_beta_data=%h ", i, rd_tx[temp_read_id].araddr, svif.rdata);
	
				rd_tx[temp_read_id].araddr=rd_tx[temp_read_id].araddr + (2**rd_tx[temp_read_id].arsize);
				//addt =0 +4=4; 4+4=8
				@(posedge svif.aclk);//between one beat to another beat making one clk cycle delay//vid36:t5,t6,t7,t8 get out for loop
				svif.rlast<=1;	
				if(svif.arvalid==1)begin
					svif.arready<=1;
					rd_tx[svif.arid]=new();//creating memory of wr_tx[5]=new();(1st clk cycle)         wr_tx[10]=new()(2nd clk cycle)
					rd_tx[svif.arid].araddr=svif.araddr;           				
					rd_tx[svif.arid].arlen=svif.arlen;
					rd_tx[svif.arid].arsize=svif.arsize;
					rd_tx[svif.arid].arcache=svif.arcache;
					rd_tx[svif.arid].arprot=svif.arprot;
					rd_tx[svif.arid].arlock=svif.arlock;
					rd_tx[svif.arid].arburst=svif.arburst;
					rd_tx[svif.arid].arid=svif.arid;

				end
						end //for}
					end//burst

					rd_tx.delete(temp_read_id);//vid36:at t8 delete the  id=5 info from array.
				end//rd_tx size end


				end//rready
//***************************************************READ DATA CHANNEL END*********************************************//

			join
			
			end//svif.aresetn=1
		end//forever
	endtask

endclass

