class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)
	uvm_tlm_analysis_fifo #(trans)inp_mon_fifo;
	uvm_tlm_analysis_fifo #(trans)out_mon_fifo;

	trans inp_mon_xn;
	trans out_mon_xn;
    trans q[$];
    int MATCH=0,MISMATCH=0;
  
 function new(string name="scoreboard",uvm_component parent);
	super.new(name,parent);
	inp_mon_fifo=new("inp_mon_fifo",this);
	out_mon_fifo=new("out_mon_fifo",this);
 endfunction

 task run_phase(uvm_phase phase);
   fork
    // Thread 1: consume inputs, predict expected result, whenever they arrive
    forever begin
      inp_mon_fifo.get(inp_mon_xn);
      ref_model(inp_mon_xn);
      q.push_front(inp_mon_xn); 
          
     end

    // Thread 2: consume outputs independently, whenever they arrive
    forever begin
      out_mon_fifo.get(out_mon_xn);
      if (q.size() > 0) begin
        trans t = q.pop_back();
        `uvm_info("ref----pop_front",$sformatf("after ref opa=%0d,opb=%0d|mode=%0b|cmd=%0b|inp_val=%0b|cin=%0b|ce=%0b| res=%0d|cout=%0b|oflow=%0b|GEL=%0b%0b%0b|err=%0b\n",t.OA,t.OB,t.mode,t.cmd,t.inp_valid,t.cin,t.ce,t.res,t.cout,t.oflow,t.G,t.E,t.L,t.err),UVM_NONE)
        validate_output(t, out_mon_xn);
      end else begin
        `uvm_error(get_type_name(),
          "Output transaction arrived with no corresponding expected transaction in queue")
      end
    end
  join
endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info (get_type_name,$sformatf("scoreboeard_report match=%0d |mismatch=%0d \n",MATCH,MISMATCH),UVM_NONE)
    endfunction

  virtual task validate_output(trans in,trans out);
    if(in.res==out.res && in.cout==out.cout && in.oflow==out.oflow && in.err==out.err && {in.G,in.E,in.L}=={out.G,out.E,out.L} )
	begin
	  `uvm_info(get_type_name,$sformatf("DATA MATCH SUCCESSFUL"),UVM_NONE)
	   MATCH++;
	end
	else
	
	begin
      `uvm_info(get_type_name,$sformatf("DATA MISMATCH SUCCESSFUL"),UVM_NONE)
	   	MISMATCH++;
      `uvm_info(get_type_name,$sformatf("Expected Packet  res=%0d|cout=%0b|oflow=%0b|GEL=%0b%0b%0b|err=%0b\n",in.res,in.cout,in.oflow,in.G,in.E,in.L,in.err),UVM_NONE)
      `uvm_info(get_type_name,$sformatf("DUTPacket res=%0d|cout=%0b|oflow=%0b|GEL=%0b%0b%0b|err=%0b\n",out.res,out.cout,out.oflow,out.G,out.E,out.L,out.err),UVM_NONE)
	end
	
endtask

 task ref_model(ref trans t);
  static bit mode;
  static bit [3:0] cmd;
  static bit [7:0] opa,opb;
   static bit [5:0] waiting=0;
  static bit opa_val=0,opb_val=0;
   static bit [3:0] mul_wait1=0,mul_wait2=0;
  static bit [7:0] mul1,mul2;
  bit cin;
  bit [7:0] opa_1,opb_1;
 
   if(t.rst)
  begin
    t.res=0;
    t.cout=1'b0;
    t.oflow=1'b0;
    t.G=1'b0;
    t.E=1'b0;
    t.L=1'b0;
    t.err=1'b0;
    mode=0;
    cmd=0;
    opa=0;
    opb=0;
    waiting=0;
    opa_val=0;
    opb_val=0;
    mul1=0;
    mul2=0;
    opa_1=0;
    opb_1=0;
  end
   else if(t.ce)
  begin
    if(mode!=t.mode || cmd!=t.cmd)
    begin
      waiting=0;
      opa_val=0;
      opb_val=0;
    end
    mode=t.mode;
    cmd=t.cmd;
   
    if(t.inp_valid==2'b01)
    begin
      opa_val=1;
      waiting++;
      opa=t.OA;
      cin=t.cin;
    end
    else if(t.inp_valid==2'b10)
    begin
      opb_val=1;
      waiting++;
      opb=t.OB;
      cin=t.cin;
    end
    else if(t.inp_valid==2'b11)
    begin
      opa=t.OA;
      opb=t.OB;
      cin=t.cin;
      opa_val=1;
      opb_val=1;
      waiting =0;
    end
    else if(t.inp_valid==2'b00)
    begin
      if(opa_val || opb_val)
        waiting++;
    end
 
    if(waiting==17)
    begin
      t.res=0;
      t.cout=1'b0;
      t.oflow=1'b0;
      t.G=1'b0;
      t.E=1'b0;
      t.L=1'b0;
      t.err=1'b1;
      waiting=0;
      opa_val=0;
      opb_val=0;
    end
 
    if(mode)
    begin
      t.res=0;
      t.cout=1'b0;
      t.oflow=1'b0;
      t.G=1'b0;
      t.E=1'b0;
      t.L=1'b0;
      if(t.err==1) t.err=t.err;
      else t.err=0;
      if(cmd!=9) mul_wait1=0;
      if(cmd!=10) mul_wait2=0;
      case(cmd)
        0:if(opa_val && opb_val)
          begin
            t.res=opa+opb;
            t.cout=t.res[8]?1:0;
            t.res=t.res[7:0];
          end
 
        1:if(opa_val && opb_val)
          begin
            t.oflow=(opa<opb)?1:0;
            t.res=opa-opb;
            t.res=t.res[7:0];
          end
 
        2:if(opa_val && opb_val)
          begin
            t.res=opa+opb+cin;
            t.cout=t.res[8]?1:0;
            t.res=t.res[7:0];
          end
 
        3:if(opa_val && opb_val)
          begin
            t.oflow=(opa<(opb+cin))?1:0;
            t.res=opa-opb-cin;
            t.res=t.res[7:0];
          end
 
        4:if(opa_val)begin
            t.res=opa+1;
            t.res=t.res[7:0];
        end
 
        5:if(opa_val)begin
            t.res=opa-1;
            t.res=t.res[7:0];
        end
 
        6:if(opb_val)begin
            t.res=opb+1;
            t.res=t.res[7:0];
        end
 
        7:if(opb_val)begin
            t.res=opb-1;
            t.res=t.res[7:0];
        end
 
        8:if(opa_val && opb_val)
          begin
            t.res=0;
            if(opa==opb)
            begin
              t.E=1'b1;
              t.G=1'b0;
              t.L=1'b0;
            end
            else if(opa>opb)
            begin
              t.E=1'b0;
              t.G=1'b1;
              t.L=1'b0;
            end
            else
            begin
              t.E=1'b0;
              t.G=1'b0;
              t.L=1'b1;
            end
          end
 
        9:if(opa_val && opb_val)
          begin
            if(mul_wait1==1)
            begin
              t.res=(mul1+1)*(mul2+1);
              mul_wait1=0;
            end
            else
            begin
              mul_wait1++;
              mul1=opa;
              mul2=opb;
            end
          end
 
        10:if(opa_val && opb_val)
           begin
             if(mul_wait2==1)
             begin
               t.res=(mul1<<1)*(mul2);
			   mul_wait2=0;
             end
             else
             begin
               mul_wait2++;
               mul1=opa;
               mul2=opb;
             end
           end
 
        default:
          begin
            t.res=0;
            t.cout=1'b0;
            t.oflow=1'b0;
            t.G=1'b0;
            t.E=1'b0;
            t.L=1'b0;
            t.err=1'b0;
          end
      endcase
    end
    else
    begin
      t.res=0;
      t.cout=1'b0;
      t.oflow=1'b0;
      t.G=1'b0;
      t.E=1'b0;
      t.L=1'b0;
      t.err=1'b0;
 
      case(cmd)
        0:if(opa_val && opb_val) t.res={1'b0,opa&opb};
        1:if(opa_val && opb_val) t.res={1'b0,~(opa&opb)};
        2:if(opa_val && opb_val) t.res={1'b0,opa|opb};
        3:if(opa_val && opb_val) t.res={1'b0,~(opa|opb)};
        4:if(opa_val && opb_val) t.res={1'b0,opa^opb};
        5:if(opa_val && opb_val) t.res={1'b0,~(opa^opb)};
        6:if(opa_val) t.res={1'b0,~opa};
        7:if(opb_val) t.res={1'b0,~opb};
        8:if(opa_val) t.res={1'b0,opa>>1};
        9:if(opa_val) t.res={1'b0,opa<<1};
        10:if(opb_val) t.res={1'b0,opb>>1};
        11:if(opb_val) t.res={1'b0,opb<<1};
 
        12:if(opa_val && opb_val)
           begin
             if(opb[4] | opb[5] | opb[6] | opb[7])
               t.err=1'b1;
             else
             begin
               if(opb[0])
                 opa_1={opa[6:0],opa[7]};
               else
                 opa_1=opa;
 
               if(opb[1])
                 opb_1={opa_1[5:0],opa_1[7:6]};
               else
                 opb_1=opa_1;
 
               if(opb[2])
                 t.res={opb_1[3:0],opb_1[7:4]};
               else
                 t.res=opb_1;
             end
           end
 
        13:if(opa_val && opb_val)
           begin
             if(opb[4] | opb[5] | opb[6] | opb[7])
               t.err=1'b1;
             else
             begin
               if(opb[0])
                 opa_1={opa[0],opa[7:1]};
               else
                 opa_1=opa;
 
               if(opb[1])
                 opb_1={opa_1[1:0],opa_1[7:2]};
               else
                 opb_1=opa_1;
 
               if(opb[2])
                 t.res={opb_1[3:0],opb_1[7:4]};
               else
                 t.res=opb_1;
             end
           end
 
        default:
          begin
            t.res=0;
            t.cout=1'b0;
            t.oflow=1'b0;
            t.G=1'b0;
            t.E=1'b0;
            t.L=1'b0;
            t.err=1'b0;
          end
      endcase
    end
  end
 //  `uvm_info("refmodel",$sformatf("after ref opa=%0d,opb=%0d|mode=%0b|cmd=%0b|inp_val=%0b|cin=%0b|ce=%0b| res=%0d|cout=%0b|oflow=%0b|GEL=%0b%0b%0b|err=%0b\n",t.OA,t.OB,t.mode,t.cmd,t.inp_valid,t.cin,t.ce,t.res,t.cout,t.oflow,t.G,t.E,t.L,t.err),UVM_NONE)
endtask
endclass

