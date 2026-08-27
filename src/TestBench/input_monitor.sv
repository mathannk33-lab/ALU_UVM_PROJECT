class input_monitor extends uvm_monitor;
	`uvm_component_utils(input_monitor)
	
	uvm_analysis_port#(trans) inp_monitor_port;

	virtual alu_if.INP_MON vif;
	alu_config m_cfg;

 function new(string name="input_monitor",uvm_component parent);
	super.new(name,parent);
 endfunction

 function void build_phase(uvm_phase phase);
	super.build_phase(phase);
   if(!uvm_config_db#(alu_config)::get(this,"","alu_config",m_cfg))
	`uvm_fatal(get_type_name(),"Input_Monitor Getting Failed")
	inp_monitor_port=new("inp_monitor_port",this);
 endfunction

 function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
 	vif=m_cfg.vif;
 endfunction

 task run_phase(uvm_phase phase);
        repeat(3) @(vif.inp_mon_cb);
	forever begin
      trans drv2mon;
      drv2mon=trans::type_id::create("drv2mon");
      collect_input_monitor(drv2mon);
     // `uvm_info("INPUT_MONITOR",$sformatf("Input MONITOR ce=%0b|mode=%0b|cmd=%0b|inp_vld=%0b|cin=%0b|opa=%0d|opb=%0d\n",drv2mon.ce,drv2mon.mode,drv2mon.cmd,drv2mon.inp_valid,drv2mon.cin,drv2mon.OA,drv2mon.OB),UVM_NONE)
	end
		    
 endtask

  virtual task collect_input_monitor(trans drv2mon);
	begin
		repeat(1)
        	@(vif.inp_mon_cb);

	    drv2mon.ce        =   vif.inp_mon_cb.ce; 
	    drv2mon.inp_valid =   vif.inp_mon_cb.inp_valid;
	    drv2mon.OA        =   vif.inp_mon_cb.OA;
	    drv2mon.OB        =   vif.inp_mon_cb.OB;
        drv2mon.mode      =   vif.inp_mon_cb.mode;
	    drv2mon.cmd       =   vif.inp_mon_cb.cmd;
	    drv2mon.cin       =   vif.inp_mon_cb.cin;
	    inp_monitor_port.write(drv2mon);
 	end
 endtask

endclass

