class ce_gate_seq extends uvm_sequence #(trans);
  `uvm_object_utils(ce_gate_seq)
  function new(string name="ce_gate_seq"); super.new(name); endfunction
  task body();
    // CE=1, normal op executes
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with { ce==1'b1; inp_valid==2'b11; mode==1'b1; cmd==4'b0000; });
    finish_item(req);

    // CE=0, op must NOT execute
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with { ce==1'b0; inp_valid==2'b11; mode==1'b1; cmd==4'b0000; });
    finish_item(req);
  endtask
endclass

class arith_sweep_seq extends uvm_sequence #(trans);
  `uvm_object_utils(arith_sweep_seq)
  function new(string name="arith_sweep_seq"); super.new(name); endfunction
  task body();
    bit [7:0] pairs[$][2] = '{ '{255,255}}; //'{0,1}, '{1,0}, '{255,255}, '{128,127}, '{200,55} };
    foreach(pairs[i]) begin
      for (int cmd = 0; cmd <= 7; cmd++) begin
        for (int cin_v = 0; cin_v <= 1; cin_v++) begin
          req = trans::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {
            mode==1'b1; ce==1'b1; inp_valid==2'b11;
            cmd==local::cmd; cin==local::cin_v;
            OA==pairs[i][0]; OB==pairs[i][1];
          });
          finish_item(req);
        end
      end
    end
  endtask
endclass

class arith_flag_targeted_seq extends uvm_sequence #(trans);
  `uvm_object_utils(arith_flag_targeted_seq)
  function new(string name="arith_flag_targeted_seq"); super.new(name); endfunction

  task send(bit[3:0] c, bit[7:0] a, bit[7:0] b, bit cinv);
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      mode==1'b1; ce==1'b1; inp_valid==2'b11; cmd==c; OA==a; OB==b; cin==cinv;
    });
    finish_item(req);
  endtask

  task body();
    // ADD: cout=0, cout=1
    send(4'b0000, 8'd10,  8'd20,  0);
    send(4'b0000, 8'd200, 8'd200, 0);
    // SUB: oflow=0 (OA>=OB), oflow=1 (OA<OB)
    send(4'b0001, 8'd50, 8'd5,  0);
    send(4'b0001, 8'd5,  8'd50, 0);
    // ADD_CIN: cin=0 and cin=1, both forcing cout=1
    send(4'b0010, 8'd255, 8'd1, 0);
    send(4'b0010, 8'd254, 8'd1, 1);
    // SUB_CIN: cin=0 and cin=1, both forcing oflow=1
    send(4'b0011, 8'd0, 8'd1, 0);
    send(4'b0011, 8'd0, 8'd1, 1);
  endtask
endclass

class staged_inp_valid_seq extends uvm_sequence #(trans);
  `uvm_object_utils(staged_inp_valid_seq)
  function new(string name="staged_inp_valid_seq"); super.new(name); endfunction

  task send(bit[3:0] c, bit[1:0] iv, bit[7:0] a, bit[7:0] b);
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      mode==1'b1; ce==1'b1; cmd==c; inp_valid==iv; OA==a; OB==b;
    });
    finish_item(req);
  endtask

  task body();
    // INC_A (cmd=4)
    send(4'b0100, 2'b11, 8'd10, 8'd0);   // normal capture
    send(4'b0100, 2'b01, 8'd12, 8'd0);   // OPA-only capture, still valid
    send(4'b0100, 2'b10, 8'd15, 8'd0);   // OPA never latched -> expect ERR
    send(4'b0100, 2'b00, 8'd17, 8'd0);   // OPA never latched -> expect ERR

    // DEC_A (cmd=5)
    send(4'b0101, 2'b01, 8'd10, 8'd0);
    send(4'b0101, 2'b11, 8'd12, 8'd0);
    send(4'b0101, 2'b10, 8'd15, 8'd0);
    send(4'b0101, 2'b00, 8'd17, 8'd0);

    // INC_B (cmd=6)
    send(4'b0110, 2'b11, 8'd0, 8'd10);
    send(4'b0110, 2'b10, 8'd0, 8'd12);   // OPB-only capture, still valid
    send(4'b0110, 2'b01, 8'd0, 8'd15);   // OPB never latched -> expect ERR
    send(4'b0110, 2'b00, 8'd0, 8'd17);   // OPB never latched -> expect ERR

    // DEC_B (cmd=7)
    send(4'b0111, 2'b10, 8'd0, 8'd14);
    send(4'b0111, 2'b11, 8'd0, 8'd18);
  endtask
endclass

class logic_sweep_seq extends uvm_sequence #(trans);
  `uvm_object_utils(logic_sweep_seq)
  function new(string name="logic_sweep_seq"); super.new(name); endfunction
  task body();
    bit [7:0] pairs[$][2] = '{ '{0,0}, '{255,255}, '{170,85}, '{1,254} };
    foreach(pairs[i]) begin
      for (int cmd = 0; cmd <= 11; cmd++) begin
        req = trans::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          mode==1'b0; ce==1'b1; inp_valid==2'b11;
          cmd==local::cmd; OA==pairs[i][0]; OB==pairs[i][1];
        });
        finish_item(req);
      end
    end
  endtask
endclass

class cmp_seq extends uvm_sequence #(trans);
  `uvm_object_utils(cmp_seq)
  function new(string name="cmp_seq"); super.new(name); endfunction
  task body();
    bit [7:0] pairs[$][2] = '{ '{50,50}, '{99,10}, '{10,99} }; // E, G, L
    foreach(pairs[i]) begin
      req = trans::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        mode==1'b1; ce==1'b1; inp_valid==2'b11; cmd==4'b1000;
        OA==pairs[i][0]; OB==pairs[i][1];
      });
      finish_item(req);
    end
  endtask
endclass

class rotate_seq extends uvm_sequence #(trans);
  `uvm_object_utils(rotate_seq)
  function new(string name="rotate_seq"); super.new(name); endfunction
  task body();
    bit [3:0] cmds[$] = '{4'b1100, 4'b1101}; // ROL_A_B, ROR_A_B
    foreach(cmds[c]) begin
      for (int amt = 0; amt <= 7; amt++) begin
        req = trans::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          mode==1'b0; ce==1'b1; inp_valid==2'b11; cmd==cmds[c];
          OA==8'hA5; OB[2:0]==local::amt[2:0]; OB[7:4]==4'b0000;
        });
        finish_item(req);
      end
    end
  endtask
endclass

class rotate_errbit_seq extends uvm_sequence #(trans);
  `uvm_object_utils(rotate_errbit_seq)
  function new(string name="rotate_errbit_seq"); super.new(name); endfunction
  task body();
    bit [3:0] cmds[$] = '{4'b1100, 4'b1101}; // ROL_A_B, ROR_A_B
    foreach(cmds[c]) begin
      // error cases: each of OPB[7:4] individually forced high
      for (int bit_i = 4; bit_i <= 7; bit_i++) begin
        req = trans::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          mode==1'b0; ce==1'b1; inp_valid==2'b11; cmd==cmds[c];
          OA==8'hA5; OB[local::bit_i]==1'b1;
        });
        finish_item(req);
      end
      // no-error case: OPB[7:4] == 0
      req = trans::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        mode==1'b0; ce==1'b1; inp_valid==2'b11; cmd==cmds[c];
        OA==8'hA5; OB[7:4]==4'b0000;
      });
      finish_item(req);
    end
  endtask
endclass

class invalid_cmd_seq extends uvm_sequence #(trans);
  `uvm_object_utils(invalid_cmd_seq)
  function new(string name="invalid_cmd_seq"); super.new(name); endfunction
  task body();
    // MODE=1, CMD=15 (invalid arithmetic)
    begin
    bit[3:0] bad_cmds[$] ='{4'd11,12,13,14,15};
    foreach(bad_cmds[i])begin
    req = trans::type_id::create("req");
    req.c5.constraint_mode(0);
    start_item(req);
    assert(req.randomize() with { mode==1'b1; ce==1'b1; inp_valid==2'b11; cmd==bad_cmds[i]; });
    finish_item(req);
    end
    end

    // MODE=0, CMD=14 and CMD=15 (invalid logical)
    begin
      bit [3:0] bad_cmds[2] = '{4'b1110, 4'b1111};
      foreach(bad_cmds[i]) begin
        req = trans::type_id::create("req");
        req.c5.constraint_mode(0);
        start_item(req);
        assert(req.randomize() with { mode==1'b0; ce==1'b1; inp_valid==2'b11; cmd==bad_cmds[i]; });
        finish_item(req);
      end
    end
  endtask
endclass

class mul_pipeline_seq extends uvm_sequence #(trans);
  `uvm_object_utils(mul_pipeline_seq)
  function new(string name="mul_pipeline_seq"); super.new(name); endfunction

  task mul_op(bit[3:0] c, bit[7:0] a, bit[7:0] b);
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      mode==1'b1; ce==1'b1; inp_valid==2'b11; cmd==c; OA==a; OB==b;
    });
    finish_item(req);
  endtask

  task body();
    // Single-shot MUL_INC / MUL_SHL, check 3-cycle latency (35, 45)
    mul_op(4'b1001, 8'd5, 8'd6);
    mul_op(4'b1010, 8'd5, 8'd6);

    // Sustained run, operands changing every cycle (36, 46)
    for (int i = 0; i < 10; i++) begin
      req = trans::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        mode==1'b1; ce==1'b1; inp_valid==2'b11;
        cmd==4'b1001; OA==local::i; OB==(local::i+1);
      });
      finish_item(req);
    end

    // Mid-flight abort: start MUL, then switch cmd/inp_valid before it
    // completes (43, 53)
    mul_op(4'b1001, 8'd20, 8'd30);
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      mode==1'b1; ce==1'b1; inp_valid==2'b01; // partial capture -> abort
      cmd==4'b0000; OA==8'd1; OB==8'd1;
    });
    finish_item(req);

    // Alternate MUL_INC/MUL_SHL back-to-back (55-60)
    for (int i = 0; i < 4; i++) begin
      req = trans::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        mode==1'b1; ce==1'b1; inp_valid==2'b11;
        cmd == (local::i % 2 == 0) ? 4'b1001 : 4'b1010;
        OA==8'd7; OB==8'd8;
      });
      finish_item(req);
    end

    // Operand perturbation on cycle 2 of a MUL_SHL - result should reflect
    // cycle-1 values, not the perturbed ones (61, 62)
    mul_op(4'b1010, 8'd12, 8'd3);
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      mode==1'b1; ce==1'b1; inp_valid==2'b11; cmd==4'b1010; OA==8'd99; OB==8'd99;
    });
    finish_item(req);
  endtask
endclass

class timeout_wait_seq extends uvm_sequence #(trans);
  `uvm_object_utils(timeout_wait_seq)
  function new(string name="timeout_wait_seq"); super.new(name); endfunction

  task send(bit[1:0] iv, bit[7:0] a, bit[7:0] b, bit m, bit[3:0] c);
    req = trans::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      ce==1'b1; inp_valid==iv; OA==a; OB==b; mode==m; cmd==c;
    });
    finish_item(req);
  endtask

  task body();
    // --- Case A: OPA arrives, OPB never comes within 16 cycles -> ERR=1 ---
    send(2'b01, 8'd42, 8'd0, 1'b1, 4'b0000);
    repeat(16) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000); // sticky, no clear
    // at this point >16 cycles have elapsed since OPA arrived -> expect ERR=1

    // --- Case B: OPB arrives first, OPA never comes within 16 cycles -> ERR=1 ---
    send(2'b10, 8'd0, 8'd7, 1'b1, 4'b0000);
    repeat(16) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000);
    // expect ERR=1

    // --- Case C: OPB arrives well within the window -> normal op, no ERR ---
    //send(2'b01, 8'd10, 8'd0, 1'b1, 4'b0000);
    //repeat(5) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000);
    //send(2'b10, 8'd0, 8'd20, 1'b1, 4'b0000); // OPB arrives at cycle 6

    // --- Case D: OPA changes value mid-wait; counter does NOT reset, so if
    //     OPB still never arrives, ERR still fires at 16 cycles from the
    //     ORIGINAL arrival, using the latest OPA value internally ---
    //send(2'b01, 8'd1, 8'd0, 1'b1, 4'b0000);       // OPA=1 at cycle 0
    //repeat(8) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000);
    //send(2'b01, 8'd99, 8'd0, 1'b1, 4'b0000);      // OPA updated to 99 at cycle 9
    //repeat(17) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000); // cycles 10-16, total=16 since cycle 0
    // expect ERR=1 (counter was never reset by the operand update)

    // --- Case E: same as D, but OPB arrives right after the operand update
    //     -> op executes using the LATEST OPA value (99), not the original (1) ---
    //send(2'b01, 8'd1, 8'd0, 1'b1, 4'b0000);
    //repeat(8) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000);
    //send(2'b01, 8'd99, 8'd0, 1'b1, 4'b0000);      // OPA updated at cycle 9
    //send(2'b10, 8'd0, 8'd7, 1'b1, 4'b0000);       // OPB arrives at cycle 10
    // expect RES computed from OPA=99, OPB=7

    // --- Case F: CMD changes mid-wait -> counter RESETS. Confirm the
    //     timeout window restarts (ERR should NOT fire at the original
    //     16-cycle mark, only 16 cycles after the CMD change) ---
    //send(2'b01, 8'd5, 8'd0, 1'b1, 4'b0000);       // ADD selected, OPA=5 at cycle 0
    //repeat(10) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000); // cycles 1-10, no ERR yet
    //send(2'b01, 8'd5, 8'd0, 1'b1, 4'b0001);       // CMD changed to SUB at cycle 11 -> reset
    //repeat(15) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0001); // cycles 12-26: still within new window
    // expect NO ERR yet at what would have been the "original" 16-cycle mark (cycle 16)
    //send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0001);        // cycle 27: now 16 cycles since the reset
    // expect ERR=1 here (16 cycles measured from the CMD change, not from cycle 0)

    // --- Case G: MODE changes mid-wait -> counter RESETS (symmetric to F) ---
    //send(2'b01, 8'd5, 8'd0, 1'b1, 4'b0000);
    //repeat(10) send(2'b00, 8'd0, 8'd0, 1'b1, 4'b0000);
    //send(2'b01, 8'd5, 8'd0, 1'b0, 4'b0000);       // MODE flipped to logical -> reset
    //repeat(16) send(2'b00, 8'd0, 8'd0, 1'b0, 4'b0000);
    // expect ERR=1, 16 cycles after the MODE change
  endtask
endclass

//-----------------------------------------------------------------------------
// 11. Master sequence: runs the full library in one shot.
//-----------------------------------------------------------------------------
class alu_full_coverage_seq extends uvm_sequence #(trans);
  `uvm_object_utils(alu_full_coverage_seq)
  function new(string name="alu_full_coverage_seq"); super.new(name); endfunction

  task body();
    ce_gate_seq            s0;
    arith_sweep_seq         s1;
    arith_flag_targeted_seq s2;
    staged_inp_valid_seq    s3;
    logic_sweep_seq         s4;
    cmp_seq                 s5;
    rotate_seq              s6;
    rotate_errbit_seq       s7;
    invalid_cmd_seq         s8;
    mul_pipeline_seq        s9;
    timeout_wait_seq        s10;

    s0  = ce_gate_seq::type_id::create("s0");             s0.start(m_sequencer);
    s1  = arith_sweep_seq::type_id::create("s1");          s1.start(m_sequencer);
    s2  = arith_flag_targeted_seq::type_id::create("s2");  s2.start(m_sequencer);
    s3  = staged_inp_valid_seq::type_id::create("s3");     s3.start(m_sequencer);
    s4  = logic_sweep_seq::type_id::create("s4");          s4.start(m_sequencer);
    s5  = cmp_seq::type_id::create("s5");                  s5.start(m_sequencer);
    s6  = rotate_seq::type_id::create("s6");                s6.start(m_sequencer);
    s7  = rotate_errbit_seq::type_id::create("s7");         s7.start(m_sequencer);
    s8  = invalid_cmd_seq::type_id::create("s8");           s8.start(m_sequencer);
    s9  = mul_pipeline_seq::type_id::create("s9");          s9.start(m_sequencer);
    s10 = timeout_wait_seq::type_id::create("s10");         s10.start(m_sequencer);
  endtask
endclass
