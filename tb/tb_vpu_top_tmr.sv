import vpu_pkg::*;

module tb_vpu_top_tmr;

// ---- Parámetros ----
localparam TMR_ENABLE = 1;

// ---- Señales ----
logic        clk, rst;
logic [31:0] instr;
logic [31:0] rs1_data;
logic        valid;
logic        done, illegal, stall;
logic        tmr_error;

// ---- DUT ----
vpu_top #(
    .TMR_ENABLE(TMR_ENABLE)
) dut (
    .clk_i       (clk),
    .rst_i       (rst),
    .instr_i     (instr),
    .rs1_data_i  (rs1_data),
    .valid_i     (valid),
    .done_o      (done),
    .illegal_o   (illegal),
    .stall_o     (stall),
    .tmr_error_o (tmr_error)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Función para construir instrucción vectorial ----
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

// ---- Tareas de verificación ----
task check;
    input string        test_name;
    input logic [127:0] got;
    input logic [127:0] expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %h | expected: %h",
                      test_name, got, expected);
    end
endtask

task check_1;
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

// ---- Tests ----
initial begin
    rst = 1; valid = 0; instr = '0; rs1_data = '0;
    @(posedge clk); #1;
    rst = 0;

    // ----------------------------------------
    // Configurar SEW32 via vsetvli
    // ----------------------------------------
    @(posedge clk);
    instr = {12'h010, 5'd0, 3'b111, 5'd0, 7'b1010111};
    valid = 1; rs1_data = 32'd4;
    @(posedge clk); #1;
    valid = 0;
    $display("SEW tras vsetvli: %0d (esperado 2=SEW32)", dut.sew);
    $display("vl  tras vsetvli: %0d (esperado 4)", dut.vl);

    // ----------------------------------------
    // Cargar datos en v1 y v2 via backdoor
    // v1 = {10, 20, 30, 40}
    // v2 = {1,  2,  3,  4}
    // ----------------------------------------
    force dut.regfile.regs[1].i32b = '{32'd10, 32'd20, 32'd30, 32'd40};
    force dut.regfile.regs[2].i32b = '{32'd1,  32'd2,  32'd3,  32'd4};
    @(posedge clk); #1;
    release dut.regfile.regs[1];
    release dut.regfile.regs[2];

    // ========================================
    // PARTE 1: Tests funcionales (igual que TMR_ENABLE=0)
    // Verifican que TMR no altera el comportamiento normal
    // ========================================
    $display("---- PARTE 1: Tests funcionales con TMR ----");

    // VADD.VV v3, v2, v1
    @(posedge clk);
    instr = build_instr(6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3);
    valid = 1;
    @(posedge clk); #1;
    check_1("VADD.VV done",      done,      1'b1);
    check_1("VADD.VV tmr_error", tmr_error, 1'b0);
    valid = 0;
    @(posedge clk); #1;
    check("VADD.VV SEW32",
          dut.regfile.regs[3].i128b,
          {32'd11, 32'd22, 32'd33, 32'd44});

    // VSUB.VV v4, v1, v2
    @(posedge clk);
    instr = build_instr(6'b000010, 1'b1, 5'd1, 5'd2, 3'b000, 5'd4);
    valid = 1;
    @(posedge clk); #1;
    check_1("VSUB.VV done",      done,      1'b1);
    check_1("VSUB.VV tmr_error", tmr_error, 1'b0);
    valid = 0;
    @(posedge clk); #1;
    check("VSUB.VV SEW32",
          dut.regfile.regs[4].i128b,
          {32'd9, 32'd18, 32'd27, 32'd36});

    // VADD.VX v5, v2, rs1
    @(posedge clk);
    instr = build_instr(6'b000000, 1'b1, 5'd2, 5'd0, 3'b100, 5'd5);
    valid = 1; rs1_data = 32'd100;
    @(posedge clk); #1;
    check_1("VADD.VX done",      done,      1'b1);
    check_1("VADD.VX tmr_error", tmr_error, 1'b0);
    valid = 0; rs1_data = '0;
    @(posedge clk); #1;
    check("VADD.VX SEW32",
          dut.regfile.regs[5].i128b,
          {32'd101, 32'd102, 32'd103, 32'd104});

    // VAND.VV v6, v1, v2
    @(posedge clk);
    instr = build_instr(6'b001001, 1'b1, 5'd1, 5'd2, 3'b000, 5'd6);
    valid = 1;
    @(posedge clk); #1;
    check_1("VAND.VV done",      done,      1'b1);
    check_1("VAND.VV tmr_error", tmr_error, 1'b0);
    valid = 0;
    @(posedge clk); #1;
    check("VAND.VV SEW32",
          dut.regfile.regs[6].i128b,
          {32'd10&32'd1, 32'd20&32'd2, 32'd30&32'd3, 32'd40&32'd4});

    // VMUL.VV v7, v2, v1
    @(posedge clk);
    instr = build_instr(6'b100101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd7);
    valid = 1;
    @(posedge clk); #1;
    check_1("VMUL.VV done",      done,      1'b1);
    check_1("VMUL.VV tmr_error", tmr_error, 1'b0);
    valid = 0;
    @(posedge clk); #1;
    check("VMUL.VV SEW32",
          dut.regfile.regs[7].i128b,
          {32'd10, 32'd40, 32'd90, 32'd160});

    // VDIVU.VV v8, v1, v2
    @(posedge clk);
    instr = build_instr(6'b100000, 1'b1, 5'd1, 5'd2, 3'b010, 5'd8);
    valid = 1;
    @(posedge clk); #1;
    check_1("VDIVU.VV done",      done,      1'b1);
    check_1("VDIVU.VV tmr_error", tmr_error, 1'b0);
    valid = 0;
    @(posedge clk); #1;
    check("VDIVU.VV SEW32",
          dut.regfile.regs[8].i128b,
          {32'd10, 32'd10, 32'd10, 32'd10});

    // VMSEQ ninguno igual
    @(posedge clk);
    instr = build_instr(6'b011000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd9);
    valid = 1;
    @(posedge clk); #1;
    check_1("VMSEQ ninguno done",      done,      1'b1);
    check_1("VMSEQ ninguno tmr_error", tmr_error, 1'b0);
    valid = 0;
    @(posedge clk); #1;
    check("VMSEQ.VV SEW32 ninguno igual",
          dut.regfile.regs[9].i128b,
          128'h0);

    // VMSEQ todos iguales
    force dut.regfile.regs[10].i32b = '{32'd1, 32'd2, 32'd3, 32'd4};
    @(posedge clk); #1;
    release dut.regfile.regs[10];

    @(posedge clk);
    instr = build_instr(6'b011000, 1'b1, 5'd2, 5'd10, 3'b000, 5'd11);
    valid = 1;
    @(posedge clk); #1;
    check_1("VMSEQ todos done",      done,      1'b1);
    check_1("VMSEQ todos tmr_error", tmr_error, 1'b0);
    valid = 0;
    @(posedge clk); #1;
    check("VMSEQ.VV SEW32 todos iguales",
          dut.regfile.regs[11].i128b,
          {112'b0, 16'h000F});

    // Instrucción ilegal
    @(posedge clk);
    instr = 32'h00000013;
    valid = 1;
    @(posedge clk); #1;
    check_1("Instrucción ilegal",        illegal, 1'b1);
    check_1("Instrucción ilegal done=0", done,    1'b0);
    check_1("Instrucción ilegal tmr=0",  tmr_error, 1'b0);
    valid = 0;

    // ========================================
    // PARTE 2: Inyección de fallos
    // ========================================
    $display("---- PARTE 2: Inyección de fallos ----");

   // ----------------------------------------
    // TEST A: Fallo en carril B (addsub)
    // vadd.vv v12, v2, v1
    // Forzar rd_data_b a valor erróneo
    // Voter corrige con A y C
    // ----------------------------------------
    $display("---- TEST A: Fallo en carril B ----");
    @(posedge clk);
    instr = build_instr(6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd12);
    valid = 1;
    force dut.tmr_block.rd_data_b = 128'hDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
    @(posedge clk); #1;
    check_1("Fallo B: tmr_error detectado", tmr_error, 1'b1);
    check_1("Fallo B: done correcto",       done,      1'b1);
    release dut.tmr_block.rd_data_b;
    valid = 0;
    instr = 32'h00000013; // NOP → todos los carriles dan 0 → error=0
    @(posedge clk); #1;
    check("Fallo B: resultado correcto en regfile",
          dut.regfile.regs[12].i128b,
          {32'd11, 32'd22, 32'd33, 32'd44});
    check_1("Fallo B: tmr_error=0 tras liberar", tmr_error, 1'b0);

    // ----------------------------------------
    // TEST B: Fallo en carril C (logic)
    // vand.vv v13, v1, v2
    // Forzar rd_data_c a valor erróneo
    // Voter corrige con A y B
    // ----------------------------------------
    $display("---- TEST B: Fallo en carril C ----");
    @(posedge clk);
    instr = build_instr(6'b001001, 1'b1, 5'd1, 5'd2, 3'b000, 5'd13);
    valid = 1;
    force dut.tmr_block.rd_data_c = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    @(posedge clk); #1;
    check_1("Fallo C: tmr_error detectado", tmr_error, 1'b1);
    check_1("Fallo C: done correcto",       done,      1'b1);
    release dut.tmr_block.rd_data_c;
    valid = 0;
    instr = 32'h00000013;
    @(posedge clk); #1;
    check("Fallo C: resultado correcto en regfile",
          dut.regfile.regs[13].i128b,
          {32'd10&32'd1, 32'd20&32'd2, 32'd30&32'd3, 32'd40&32'd4});
    check_1("Fallo C: tmr_error=0 tras liberar", tmr_error, 1'b0);

    // ----------------------------------------
    // TEST C: Dos fallos simultáneos (B y C)
    // vmul.vv v14, v2, v1
    // B y C erróneos → voter da resultado de A (único correcto)
    // pero tmr_error=1 porque B!=C
    // ----------------------------------------
    $display("---- TEST C: Dos fallos simultáneos B y C ----");
    @(posedge clk);
    instr = build_instr(6'b100101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd14);
    valid = 1;
    force dut.tmr_block.rd_data_b = 128'h0;
    force dut.tmr_block.rd_data_c = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    @(posedge clk); #1;
    check_1("Dos fallos B+C: tmr_error detectado", tmr_error, 1'b1);
    release dut.tmr_block.rd_data_b;
    release dut.tmr_block.rd_data_c;
    valid = 0;
    instr = 32'h00000013;
    @(posedge clk); #1;
    check_1("Dos fallos B+C: tmr_error=0 tras liberar", tmr_error, 1'b0);

    // ----------------------------------------
    // TEST D: Sistema se recupera tras fallos
    // vadd.vv v15, v2, v1 sin fallos
    // ----------------------------------------
    $display("---- TEST D: Recuperación tras fallos ----");
    @(posedge clk);
    instr = build_instr(6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd15);
    valid = 1;
    @(posedge clk); #1;
    check_1("Recuperación: tmr_error=0", tmr_error, 1'b0);
    check_1("Recuperación: done=1",      done,      1'b1);
    valid = 0;
    @(posedge clk); #1;
    check("Recuperación: resultado correcto",
          dut.regfile.regs[15].i128b,
          {32'd11, 32'd22, 32'd33, 32'd44});

    $display("---- Tests completados ----");
    $finish;
end

endmodule