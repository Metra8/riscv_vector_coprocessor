// tb_vpu_top.sv
import vpu_pkg::*;

module tb_vpu_top;

// ---- Parámetros ----
localparam TMR_ENABLE = 0;

// ---- Señales ----
logic        clk, rst;
logic [31:0] instr;
logic [31:0] rs1_data;
logic        valid;
logic        done, illegal, stall;
logic        tmr_error; //tmr error

// ---- DUT ----
vpu_top #(
    .TMR_ENABLE(TMR_ENABLE)
) dut (
    .clk_i      (clk),
    .rst_i      (rst),
    .instr_i    (instr),
    .rs1_data_i (rs1_data),
    .valid_i    (valid),
    .done_o     (done),
    .illegal_o  (illegal),
    .stall_o    (stall),
    .tmr_error_o(tmr_error)
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

// ---- Tarea de verificación ----
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
    // zimm para SEW32: vsew=010 → bits[5:3]=010
    // instr[31:20] = 12'h010 = 12'b000000010000
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

    // ----------------------------------------
    // VADD.VV v3, v2, v1 → v3 = v2 + v1
    // {1,2,3,4} + {10,20,30,40} = {11,22,33,44}
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3);
    valid = 1;
    @(posedge clk); #1;
    // comprobar done antes de bajar valid
    check_1("VADD.VV done", done, 1'b1);
    valid = 0;
    @(posedge clk); #1;
    check("VADD.VV SEW32",
          dut.regfile.regs[3].i128b,
          {32'd11, 32'd22, 32'd33, 32'd44});

    // ----------------------------------------
    // VSUB.VV v4, v1, v2 → v4 = v1 - v2
    // vs2=v1={10,20,30,40}, vs1=v2={1,2,3,4}
    // resultado = {9,18,27,36}
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(6'b000010, 1'b1, 5'd1, 5'd2, 3'b000, 5'd4);
    valid = 1;
    @(posedge clk); #1;
    check_1("VSUB.VV done", done, 1'b1);
    valid = 0;
    @(posedge clk); #1;
    check("VSUB.VV SEW32",
          dut.regfile.regs[4].i128b,
          {32'd9, 32'd18, 32'd27, 32'd36});

    // ----------------------------------------
    // VADD.VX v5, v2, rs1 → v5 = v2 + 100
    // {1,2,3,4} + 100 = {101,102,103,104}
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(6'b000000, 1'b1, 5'd2, 5'd0, 3'b100, 5'd5);
    valid = 1; rs1_data = 32'd100;
    @(posedge clk); #1;
    check_1("VADD.VX done", done, 1'b1);
    valid = 0; rs1_data = '0;
    @(posedge clk); #1;
    check("VADD.VX SEW32",
          dut.regfile.regs[5].i128b,
          {32'd101, 32'd102, 32'd103, 32'd104});

    // ----------------------------------------
    // VAND.VV v6, v1, v2
    // {10,20,30,40} & {1,2,3,4}
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(6'b001001, 1'b1, 5'd1, 5'd2, 3'b000, 5'd6);
    valid = 1;
    @(posedge clk); #1;
    check_1("VAND.VV done", done, 1'b1);
    valid = 0;
    @(posedge clk); #1;
    check("VAND.VV SEW32",
          dut.regfile.regs[6].i128b,
          {32'd10&32'd1, 32'd20&32'd2, 32'd30&32'd3, 32'd40&32'd4});

    // ----------------------------------------
    // VMUL.VV v7, v2, v1
    // vs2=v2={1,2,3,4} * vs1=v1={10,20,30,40}
    // = {10, 40, 90, 160}
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(6'b100101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd7);
    valid = 1;
    @(posedge clk); #1;
    check_1("VMUL.VV done", done, 1'b1);
    valid = 0;
    @(posedge clk); #1;
    check("VMUL.VV SEW32",
          dut.regfile.regs[7].i128b,
          {32'd10, 32'd40, 32'd90, 32'd160});

    // ----------------------------------------
    // VDIVU.VV v8, v1, v2
    // vs2=v1={10,20,30,40} / vs1=v2={1,2,3,4}
    // = {10, 10, 10, 10}
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(6'b100000, 1'b1, 5'd1, 5'd2, 3'b010, 5'd8);
    valid = 1;
    @(posedge clk); #1;
    check_1("VDIVU.VV done", done, 1'b1);
    valid = 0;
    @(posedge clk); #1;
    check("VDIVU.VV SEW32",
          dut.regfile.regs[8].i128b,
          {32'd10, 32'd10, 32'd10, 32'd10});

    // ----------------------------------------
    // VMSEQ.VV v9, v2, v1 → ninguno igual
    // v2={1,2,3,4} vs v1={10,20,30,40}
    // ----------------------------------------
    @(posedge clk);
    instr = build_instr(6'b011000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd9);
    valid = 1;
    @(posedge clk); #1;
    check_1("VMSEQ ninguno done", done, 1'b1);
    valid = 0;
    @(posedge clk); #1;
    check("VMSEQ.VV SEW32 ninguno igual",
          dut.regfile.regs[9].i128b,
          128'h0);

    // ----------------------------------------
    // VMSEQ con todos iguales: v2 == v10
    // ----------------------------------------
    force dut.regfile.regs[10].i32b = '{32'd1, 32'd2, 32'd3, 32'd4};
    @(posedge clk); #1;
    release dut.regfile.regs[10];

    @(posedge clk);
    instr = build_instr(6'b011000, 1'b1, 5'd2, 5'd10, 3'b000, 5'd11);
    valid = 1;
    @(posedge clk); #1;
    check_1("VMSEQ todos done", done, 1'b1);
    valid = 0;
    @(posedge clk); #1;
    // SEW32: 4 elementos todos iguales → bits [3:0] activos = 0x000F
    check("VMSEQ.VV SEW32 todos iguales",
          dut.regfile.regs[11].i128b,
          {112'b0, 16'h000F});

    // ----------------------------------------
    // Instrucción ilegal
    // ----------------------------------------
    @(posedge clk);
    instr = 32'h00000013; // ADDI escalar
    valid = 1;
    @(posedge clk); #1;
    check_1("Instrucción ilegal",        illegal, 1'b1);
    check_1("Instrucción ilegal done=0", done,    1'b0);
    valid = 0;

    $display("---- Tests completados ----");
    $finish;
end

endmodule