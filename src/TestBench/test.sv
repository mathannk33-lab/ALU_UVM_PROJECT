class test extends uvm_test;

        `uvm_component_utils(test)

env env_h;

alu_config m_cfg;
 
function new(string name="test",uvm_component parent);

        super.new(name,parent);

endfunction
 
function void build_phase(uvm_phase phase);

        super.build_phase(phase);
 
  m_cfg=alu_config::type_id::create("m_cfg");

  if(!uvm_config_db#(virtual alu_if)::get(this,"","alu_if",m_cfg.vif))

        `uvm_fatal(get_type_name,"Can't get the interface")

  m_cfg.input_agent_is_active=UVM_ACTIVE;

  m_cfg.output_agent_is_active=UVM_PASSIVE;
 
  uvm_config_db#(alu_config)::set(this,"*","alu_config",m_cfg);

  env_h=env::type_id::create("env_h",this);
 
endfunction
 
function void end_of_elaboration_phase(uvm_phase phase);

  super.end_of_elaboration_phase(phase);

   uvm_top.print_topology();

endfunction

endclass
 
 
class test1 extends test;

        `uvm_component_utils(test1)
 
        arith_sweep_seq s1;

        ce_gate_seq s2;

        arith_flag_targeted_seq s3;

        staged_inp_valid_seq s4;

        logic_sweep_seq s5;

        cmp_seq s6;

        rotate_seq s7;

        rotate_errbit_seq s8;

        invalid_cmd_seq s9;

        mul_pipeline_seq s10;

        timeout_wait_seq s11;

        alu_full_coverage_seq s12;
 
 
function new(string name="test1",uvm_component parent);

        super.new(name,parent);

endfunction
 
 
function void build_phase(uvm_phase phase);

        super.build_phase(phase);

endfunction
 
 
task run_phase(uvm_phase phase);
 
        phase.raise_objection(this);

        s1=arith_sweep_seq::type_id::create("s1");

        s2=ce_gate_seq::type_id::create("s2");

        s3=arith_flag_targeted_seq::type_id::create("s3");

        s4=staged_inp_valid_seq::type_id::create("s4");

        s5=logic_sweep_seq::type_id::create("s5");

        s6=cmp_seq::type_id::create("s6");

        s7=rotate_seq::type_id::create("s7");

        s8=rotate_errbit_seq::type_id::create("s8");

        s9=invalid_cmd_seq::type_id::create("s9");

        s10=mul_pipeline_seq::type_id::create("s10");

        s11=timeout_wait_seq::type_id::create("s11");

        s12=alu_full_coverage_seq::type_id::create("s12");
 
        fork

   // s1.start(env_h.inp_agt_h.seqr_h);

//      s2.start(env_h.inp_agt_h.seqr_h);

//    s3.start(env_h.inp_agt_h.seqr_h);

 //     s4.start(env_h.inp_agt_h.seqr_h);

//     s5.start(env_h.inp_agt_h.seqr_h);

 //     s6.start(env_h.inp_agt_h.seqr_h);

//     s7.start(env_h.inp_agt_h.seqr_h);

//      s8.start(env_h.inp_agt_h.seqr_h);

//      s9.start(env_h.inp_agt_h.seqr_h);

 //     s10.start(env_h.inp_agt_h.seqr_h);

 //    s11.start(env_h.inp_agt_h.seqr_h);

        s12.start(env_h.inp_agt_h.seqr_h);

        join

        #50;

        phase.drop_objection(this);
 
endtask
 
endclass

 
