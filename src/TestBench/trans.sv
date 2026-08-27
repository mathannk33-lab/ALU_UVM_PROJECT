class trans extends uvm_sequence_item;
        `uvm_object_utils(trans)
 
        rand bit[7:0]OA;
        rand bit[7:0]OB;
        rand bit[1:0]inp_valid;
        rand bit[3:0]cmd;
        rand bit mode,cin,ce;
        logic [8:0]res;
        logic rst,err,oflow,cout,G,E,L;
 
constraint c0{ce dist{1:=90,0:=10};}
constraint c1{OA inside {[0:500]};}
constraint c2{OB inside {[0:500]};}
constraint c3{inp_valid dist {2'b00 :=5, 2'b01 :=5, 2'b10 :=5, 2'b11 :=500};}
constraint c4{mode dist{1'b1:=5,1'b0:=5};}
constraint c5{if(mode==1)
                cmd<11;
                else
                cmd<14;}
// constraint c5{cmd dist{4'b1001:=10};}
constraint c6{cin dist{1:=5,0:=5};}
 
function new(string name="trans");
        super.new(name);
endfunction
  
endclass
