class output_monitor extends uvm_monitor;
	`uvm_component_utils(output_monitor)
	uvm_analysis_port#(trans) out_monitor_port;

	virtual alu_if.OUT_MON vif;
	alu_config m_cfg;
	trans rd_data;

 function new(string name="output_monitor",uvm_component parent);
	super.new(name,parent);
 endfunction

 function void build_phase(uvm_phase phase);
	super.build_phase(phase);
   if(!uvm_config_db#(alu_config)::get(this,"","alu_config",m_cfg))
	`uvm_fatal(get_type_name(),"Output_Monitor Getting Failed")
	//new
	out_monitor_port=new("out_monitor_port",this);
 endfunction

 function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
 	vif=m_cfg.vif;
 endfunction

 task run_phase(uvm_phase phase);
	rd_data=trans::type_id::create("rd_data");
repeat(5) @(vif.out_mon_cb);
	forever 
		begin	 
	    	collect_data();
          `uvm_info("OUTPUT_MONITOR",$sformatf("OUTPUT MONITOR :res=%0d|cout=%0b|ofloe=%0b|err=%0b|GEL=%0b%0b%0b",rd_data.res,rd_data.cout,rd_data.oflow,rd_data.err,rd_data.G,rd_data.E,rd_data.L),UVM_NONE)
		end

 endtask
	  
virtual task collect_data();
     begin
	@(vif.out_mon_cb);
          begin
	  rd_data.res=vif.out_mon_cb.res;
	  rd_data.err=vif.out_mon_cb.err;
	  rd_data.cout=vif.out_mon_cb.cout;
	  rd_data.oflow=vif.out_mon_cb.oflow;
	  rd_data.G = vif.out_mon_cb.G;
	  rd_data.L = vif.out_mon_cb.L;
	  rd_data.E = vif.out_mon_cb.E;
	  out_monitor_port.write(rd_data);
          end
    end
 endtask

 endclass

