class subscriber extends uvm_subscriber #(trans);
`uvm_component_utils(subscriber)
trans in_mon;

covergroup cg;
opa_:coverpoint in_mon.OA { bins b[5]={[0:255]};}
opb_:coverpoint in_mon.OB { bins b[5]={[0:255]};}
ce_:coverpoint in_mon.ce {bins b1[]={0,1};}
mode_:coverpoint in_mon.mode {bins b[]={0,1};}
cin_:coverpoint in_mon.cin {bins b[]={0,1};}
cmd_:coverpoint in_mon.cmd {bins b[]={[0:15]};}
inp_vld_:coverpoint in_mon.inp_valid {bins b[]={[0:3]};}

c1:cross mode_,cmd_;
c2:cross cmd_,inp_vld_;
c3:cross opa_,mode_;
c4:cross opb_,mode_;
endgroup

function new(string name="subscriber",uvm_component parent=null);
super.new(name,parent);
cg=new();
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
endfunction

function void write(trans t);
in_mon=t;
cg.sample();
`uvm_info(get_name(),"[subceriber]:input received",UVM_HIGH);
endfunction

endclass
