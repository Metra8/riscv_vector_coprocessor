// tb_tmr.sv
import vpu_pkg::*;

module tb_tmr;

// ---- Señales ----
logic        clk, rst;
logic [31:0] instr, rs1_data;
logic        valid;
logic        done, illegal, stall;
logic        tmr_error;

// ---- DUT ----
vpu_tmr dut (
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

// ---- Tareas de verificación ----
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

task check_32;
    input string       test_name;
    input logic [31:0] got;
    input logic [31:0] expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %h | expected: %h",
                      test_name, got, expected);
    end
endtask

// ---- Tarea para enviar instrucción al VPU y esperar done ----
task send_instr;
    input logic [31:0] i;
    begin
        @(posedge clk);
        instr = i;
        valid = 1;
        @(posedge clk); #1;
        check_1("done activo", done, 1'b1);
        valid = 0;
        @(posedge clk); #1;
    end
endtask

// ---- Tests ----
initial begin
    rst = 1; valid = 0;
    instr = '0; rs1_data = '0;
    @(posedge clk); #1;
    rst = 0;
    @(posedge clk); #1;

    $display("--- Iniciando tb_tmr ---");

    // ----------------------------------------
    // Configurar SEW32: vsetvli x0, x0, e32
    // ----------------------------------------
    $display("---- Configurando SEW32 ----");
    send_instr({12'h010, 5'd0, 3'b111, 5'd0, 7'b1010111});
    check_1("Sin fallo: tmr_error=0 tras vsetvli", tmr_error, 1'b0);
    $display("SEW vpu_a: %0d", dut.vpu_a.sew);
    $display("SEW vpu_b: %0d", dut.vpu_b.sew);
    $display("SEW vpu_c: %0d", dut.vpu_c.sew);

    // ----------------------------------------
    // Cargar datos en las tres copias
    // v1={10,20,30,40}, v2={1,2,3,4}
    // ----------------------------------------
    dut.vpu_a.regfile.regs[1] = {32'd40, 32'd30, 32'd20, 32'd10};
    dut.vpu_a.regfile.regs[2] = {32'd4,  32'd3,  32'd2,  32'd1};
    dut.vpu_b.regfile.regs[1] = {32'd40, 32'd30, 32'd20, 32'd10};
    dut.vpu_b.regfile.regs[2] = {32'd4,  32'd3,  32'd2,  32'd1};
    dut.vpu_c.regfile.regs[1] = {32'd40, 32'd30, 32'd20, 32'd10};
    dut.vpu_c.regfile.regs[2] = {32'd4,  32'd3,  32'd2,  32'd1};
    @(posedge clk); #1;

    // ----------------------------------------
    // TEST 1: Operación normal sin fallos
    // vadd.vv v3, v2, v1
    // ----------------------------------------
    $display("---- TEST 1: Sin fallos ----");
    send_instr({6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111});
    check_1 ("Sin fallo: tmr_error=0",    tmr_error,                          1'b0);
    check_32("Sin fallo: v3_a[0]=11",     dut.vpu_a.regfile.regs[3].i32b[0], 32'd11);
    check_32("Sin fallo: v3_b[0]=11",     dut.vpu_b.regfile.regs[3].i32b[0], 32'd11);
    check_32("Sin fallo: v3_c[0]=11",     dut.vpu_c.regfile.regs[3].i32b[0], 32'd11);
    check_32("Sin fallo: v3_a[3]=44",     dut.vpu_a.regfile.regs[3].i32b[3], 32'd44);

    // ----------------------------------------
    // TEST 2: Fallo en done_b
    // Forzar done_b=0 DURANTE la instrucción (cuando debería ser 1)
    // A y C corrigen el resultado
    // ----------------------------------------
    $display("---- TEST 2: Fallo en done_b ----");
    @(posedge clk);
    instr = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};
    valid = 1;
    force dut.done_b = 1'b0;  // fallo: done_b=0 cuando debería ser 1
    #1;
    check_1("Fallo done_b: done votado=1",   done,      1'b1); // A y C corrigen
    check_1("Fallo done_b: error detectado", tmr_error, 1'b1);
    release dut.done_b;
    @(posedge clk); #1;
    valid = 0;
    @(posedge clk); #1;
    check_1("Tras liberar done_b: error=0",  tmr_error, 1'b0);

    // ----------------------------------------
    // TEST 3: Fallo en stall_a
    // Forzar stall_a=1 cuando debería ser 0
    // B y C corrigen el resultado
    // ----------------------------------------
    $display("---- TEST 3: Fallo en stall_a ----");
    @(posedge clk);
    instr = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};
    valid = 1;
    @(posedge clk); #1;
    valid = 0;
    force dut.stall_a = 1'b1;  // fallo: stall_a=1 cuando debería ser 0
    #1;
    check_1("Fallo stall_a: stall votado=0",  stall,     1'b0); // B y C corrigen
    check_1("Fallo stall_a: error detectado", tmr_error, 1'b1);
    release dut.stall_a;
    @(posedge clk); #1;
    check_1("Tras liberar stall_a: error=0",  tmr_error, 1'b0);

    // ----------------------------------------
    // TEST 4: Fallo en illegal_c con instrucción ilegal
    // Forzar illegal_c=0 cuando debería ser 1
    // A y B corrigen el resultado
    // ----------------------------------------
    $display("---- TEST 4: Fallo en illegal_c ----");
    @(posedge clk);
    instr = 32'hFFFFFFFF; // instrucción ilegal
    valid = 1;
    @(posedge clk); #1;
    // Sin fallo primero
    check_1("Sin fallo illegal: tmr_error=0", tmr_error, 1'b0);
    check_1("Sin fallo illegal: illegal=1",   illegal,   1'b1);
    // Inyectar fallo
    force dut.illegal_c = 1'b0;
    #1;
    check_1("Fallo illegal_c: illegal votado=1",  illegal,   1'b1); // A y B corrigen
    check_1("Fallo illegal_c: error detectado",   tmr_error, 1'b1);
    release dut.illegal_c;
    valid = 0;
    instr = 32'h00000013; // NOP, limpiar instrucción ilegal
    #1;
    check_1("Tras liberar illegal_c: error=0", tmr_error, 1'b0);

    // ----------------------------------------
    // TEST 5: Dos fallos simultáneos (no recuperable)
    // Forzar done_a=0 y done_b=0 cuando deberían ser 1
    // Votador da done=0 (incorrecto, solo C correcto)
    // pero tmr_error sigue detectando
    // ----------------------------------------
    $display("---- TEST 5: Dos fallos simultáneos ----");
    @(posedge clk);
    instr = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};
    valid = 1;
    @(posedge clk); #1;  // esperar a que done sea 1 naturalmente
    // Ahora done_a=1, done_b=1, done_c=1
    // Forzar done_a=0 y done_b=0
    force dut.done_a = 1'b0;  // fallo en A
    force dut.done_b = 1'b0;  // fallo en B
    #1;
    // Solo done_c=1, mayoría=0 → resultado incorrecto
    check_1("Dos fallos: done votado=0 (incorrecto)", done,      1'b0);
    check_1("Dos fallos: error detectado",            tmr_error, 1'b1);
    release dut.done_a;
    release dut.done_b;
    @(posedge clk); #1;
    valid = 0;
    @(posedge clk); #1;
    check_1("Tras liberar dos fallos: error=0", tmr_error, 1'b0);

    $display("---- Tests completados ----");
    $finish;
end

endmodule