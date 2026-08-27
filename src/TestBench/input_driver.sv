class input_driver extends uvm_driver#(trans);
	`uvm_component_utils(input_driver)

	virtual alu_if.INP_DRV vif;
	alu_config m_cfg;
	//trans data2duv;

 function new(string name="input_driver",uvm_component parent);
	super.new(name,parent);
 endfunction

 function void build_phase(uvm_phase phase);
	super.build_phase(phase);
   if(!uvm_config_db#(alu_config)::get(this,"","alu_config",m_cfg))
	`uvm_fatal(get_type_name(),"Input_Driver Getting Failed")
 endfunction

 function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
 	vif=m_cfg.vif;
 endfunction

 task run_phase(uvm_phase phase);
	begin	
		
		@(vif.inp_dr_cb);
		 vif.inp_dr_cb.rst<=1'b1;
		@(vif.inp_dr_cb);
	         vif.inp_dr_cb.rst<=1'b0;

	forever
		begin
		   seq_item_port.get_next_item(req);
		   drive(req);	
		   seq_item_port.item_done();
		end
   	end

 endtask

 task drive(trans data2duv);
	begin
        	@(vif.inp_dr_cb);

	    vif.inp_dr_cb.ce        <= data2duv.ce;
	    vif.inp_dr_cb.inp_valid <= data2duv.inp_valid;
	    vif.inp_dr_cb.OA        <= data2duv.OA;
	    vif.inp_dr_cb.OB        <= data2duv.OB;
        vif.inp_dr_cb.mode      <= data2duv.mode;
	    vif.inp_dr_cb.cmd       <= data2duv.cmd;
	    vif.inp_dr_cb.cin       <= data2duv.cin;
	    `uvm_info("INPUT_DRIVER",$sformatf("Input Driver ce=%0b|mode=%0b|cmd=%0b|inp_vld=%0b|cin=%0b|opa=%0d|opb=%0d\n",data2duv.ce,data2duv.mode,data2duv.cmd,data2duv.inp_valid,data2duv.cin,data2duv.OA,data2duv.OB),UVM_NONE)

       end
 endtask
endclass


