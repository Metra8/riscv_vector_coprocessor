// tb_decoder.sv
import vpu_pkg::*;

module tb_decoder;

// ---- Señales ----
logic        clk;
logic [31:0] instr;
logic [4:0]  vs1_addr, vs2_addr, vd_addr, imm;
logic        vm;
logic        src_vv, src_vx, src_vi;
logic        addsub_en, logic_en, mult_en, div_en, compare_en;
funct6_opi_t opi_op;
funct6_opm_t opm_op;
logic        csr_we, illegal;

// ---- DUT ----
vpu_decoder dut (
    .instr_i      (instr),
    .vs1_addr_o   (vs1_addr),
    .vs2_addr_o   (vs2_addr),
    .vd_addr_o    (vd_addr),
    .vm_o         (vm),
    .imm_o        (imm),
    .src_vv_o     (src_vv),
    .src_vx_o     (src_vx),
    .src_vi_o     (src_vi),
    .addsub_en_o  (addsub_en),
    .logic_en_o   (logic_en),
    .mult_en_o    (mult_en),
    .div_en_o     (div_en),
    .compare_en_o (compare_en),
    .opi_op_o     (opi_op),
    .opm_op_o     (opm_op),
    .csr_we_o     (csr_we),
    .illegal_o    (illegal)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Función para construir instrucción vectorial ----
// {funct6, vm, vs2, vs1, funct3, vd, opcode}
function automatic logic [31:0] build_instr;
    input logic [5:0] funct6;
    input logic       vm;
    input logic [4:0] vs2;
    input logic [4:0] vs1;
    input logic [2:0] funct3;
    input logic [4:0] vd;
    begin
        build_instr = {funct6, vm, vs2, vs1, funct3, vd, 7'b1010111};
    end
endfunction

// ---- Tarea de verificación ----
task check;
    input string test_name;
    input logic  got;
    input logic  expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %b | expected: %b",
                      test_name, got, expected);
    end
endtask

task check_5;
    input string     test_name;
    input logic [4:0] got;
    input logic [4:0] expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %0d | expected: %0d",
                      test_name, got, expected);
    end
endtask

// ---- Tests ----
initial begin

    // ----------------------------------------
    // VADD.VV → addsub_en, src_vv, opi_op=OPI_VADD
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b000000,  // funct6 = VADD
        1'b1,       // vm = 1 (sin máscara)
        5'd2,       // vs2
        5'd1,       // vs1
        3'b000,     // funct3 = OPIVV
        5'd3        // vd
    );
    @(posedge clk); #1;
    check  ("VADD.VV addsub_en",  addsub_en,  1'b1);
    check  ("VADD.VV logic_en",   logic_en,   1'b0);
    check  ("VADD.VV mult_en",    mult_en,    1'b0);
    check  ("VADD.VV div_en",     div_en,     1'b0);
    check  ("VADD.VV compare_en", compare_en, 1'b0);
    check  ("VADD.VV src_vv",     src_vv,     1'b1);
    check  ("VADD.VV src_vx",     src_vx,     1'b0);
    check  ("VADD.VV src_vi",     src_vi,     1'b0);
    check  ("VADD.VV vm",         vm,         1'b1);
    check  ("VADD.VV illegal",    illegal,    1'b0);
    check_5("VADD.VV vs1_addr",   vs1_addr,   5'd1);
    check_5("VADD.VV vs2_addr",   vs2_addr,   5'd2);
    check_5("VADD.VV vd_addr",    vd_addr,    5'd3);

    // ----------------------------------------
    // VSUB.VX → addsub_en, src_vx
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b000010,  // funct6 = VSUB
        1'b0,       // vm = 0 (con máscara)
        5'd5,       // vs2
        5'd4,       // rs1 (en VX el campo vs1 es rs1)
        3'b100,     // funct3 = OPIVX
        5'd6        // vd
    );
    @(posedge clk); #1;
    check  ("VSUB.VX addsub_en",  addsub_en,  1'b1);
    check  ("VSUB.VX src_vv",     src_vv,     1'b0);
    check  ("VSUB.VX src_vx",     src_vx,     1'b1);
    check  ("VSUB.VX src_vi",     src_vi,     1'b0);
    check  ("VSUB.VX vm",         vm,         1'b0);
    check  ("VSUB.VX illegal",    illegal,    1'b0);
    check_5("VSUB.VX vs1_addr",   vs1_addr,   5'd4);
    check_5("VSUB.VX vs2_addr",   vs2_addr,   5'd5);
    check_5("VSUB.VX vd_addr",    vd_addr,    5'd6);

    // ----------------------------------------
    // VADD.VI → addsub_en, src_vi, imm
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b000000,  // funct6 = VADD
        1'b1,       // vm
        5'd7,       // vs2
        5'd15,      // inmediato = 15
        3'b011,     // funct3 = OPIVI
        5'd8        // vd
    );
    @(posedge clk); #1;
    check  ("VADD.VI addsub_en",  addsub_en,  1'b1);
    check  ("VADD.VI src_vv",     src_vv,     1'b0);
    check  ("VADD.VI src_vx",     src_vx,     1'b0);
    check  ("VADD.VI src_vi",     src_vi,     1'b1);
    check  ("VADD.VI illegal",    illegal,    1'b0);
    check_5("VADD.VI imm",        imm,        5'd15);

    // ----------------------------------------
    // VAND.VV → logic_en
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b001001,  // funct6 = VAND
        1'b1,
        5'd1,
        5'd2,
        3'b000,     // OPIVV
        5'd3
    );
    @(posedge clk); #1;
    check("VAND.VV logic_en",   logic_en,   1'b1);
    check("VAND.VV addsub_en",  addsub_en,  1'b0);
    check("VAND.VV illegal",    illegal,    1'b0);

    // ----------------------------------------
    // VSLL.VV → logic_en
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b100101,  // funct6 = VSLL
        1'b1,
        5'd1,
        5'd2,
        3'b000,     // OPIVV
        5'd3
    );
    @(posedge clk); #1;
    check("VSLL.VV logic_en",   logic_en,   1'b1);
    check("VSLL.VV addsub_en",  addsub_en,  1'b0);
    check("VSLL.VV mult_en",    mult_en,    1'b0);
    check("VSLL.VV illegal",    illegal,    1'b0);

    // ----------------------------------------
    // VMSEQ.VV → compare_en
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b011000,  // funct6 = VMSEQ
        1'b1,
        5'd1,
        5'd2,
        3'b000,     // OPIVV
        5'd3
    );
    @(posedge clk); #1;
    check("VMSEQ.VV compare_en", compare_en, 1'b1);
    check("VMSEQ.VV addsub_en",  addsub_en,  1'b0);
    check("VMSEQ.VV illegal",    illegal,    1'b0);

    // ----------------------------------------
    // VMUL.VV → mult_en, src_vv
    // funct3 = OPMVV = 3'b010
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b100101,  // funct6 = VMUL
        1'b1,
        5'd1,
        5'd2,
        3'b010,     // OPMVV
        5'd3
    );
    @(posedge clk); #1;
    check("VMUL.VV mult_en",    mult_en,    1'b1);
    check("VMUL.VV div_en",     div_en,     1'b0);
    check("VMUL.VV logic_en",   logic_en,   1'b0);
    check("VMUL.VV addsub_en",  addsub_en,  1'b0);
    check("VMUL.VV src_vv",     src_vv,     1'b1);
    check("VMUL.VV illegal",    illegal,    1'b0);

    // ----------------------------------------
    // VDIV.VX → div_en, src_vx
    // funct3 = OPMVX = 3'b110
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b100001,  // funct6 = VDIV
        1'b1,
        5'd1,
        5'd2,
        3'b110,     // OPMVX
        5'd3
    );
    @(posedge clk); #1;
    check("VDIV.VX div_en",     div_en,     1'b1);
    check("VDIV.VX mult_en",    mult_en,    1'b0);
    check("VDIV.VX src_vx",     src_vx,     1'b1);
    check("VDIV.VX src_vv",     src_vv,     1'b0);
    check("VDIV.VX illegal",    illegal,    1'b0);

    // ----------------------------------------
    // OPCFG → csr_we
    // funct3 = 3'b111
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b000000,
        1'b1,
        5'd0,
        5'd0,
        3'b111,     // OPCFG
        5'd0
    );
    @(posedge clk); #1;
    check("OPCFG csr_we",    csr_we,  1'b1);
    check("OPCFG illegal",   illegal, 1'b0);
    check("OPCFG addsub_en", addsub_en, 1'b0);
    check("OPCFG mult_en",   mult_en,   1'b0);

    // ----------------------------------------
    // Opcode incorrecto → illegal
    // ----------------------------------------
    @(posedge clk);
    instr = 32'h00000013; // ADDI escalar, opcode != 1010111
    @(posedge clk); #1;
    check("Opcode incorrecto illegal", illegal, 1'b1);
    check("Opcode incorrecto addsub",  addsub_en, 1'b0);
    check("Opcode incorrecto mult",    mult_en,   1'b0);

    // ----------------------------------------
    // funct6 inválido dentro de OPI → illegal
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(
        6'b111111,  // funct6 no definido en OPI
        1'b1,
        5'd1,
        5'd2,
        3'b000,     // OPIVV
        5'd3
    );
    @(posedge clk); #1;
    check("funct6 inválido OPI illegal", illegal, 1'b1);

    $display("---- Tests completados ----");
    $finish;
end

endmodule