import vpu_pkg::*;

module tb_csr;

// ---- Señales ----
logic        clk, rst;
logic        we;
logic [11:0] addr, raddr;
logic [31:0] data_in, rdata;
sew_t        sew;
logic [31:0] vl, vstart, vlmax;
logic        vxsat, vill;
logic [2:0]  vlmul;

// ---- DUT ----
vpu_csr dut (
    .clk_i    (clk),
    .rst_i    (rst),
    .we_i     (we),
    .addr_i   (addr),
    .data_i   (data_in),
    .sew_o    (sew),
    .vl_o     (vl),
    .vstart_o (vstart),
    .vxsat_o  (vxsat),
    .vlmul_o  (vlmul),
    .vlmax_o  (vlmax),
    .vill_o   (vill),
    .raddr_i  (raddr),
    .rdata_o  (rdata)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tareas de verificación ----
task check_32;
    input string     test_name;
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

task check_1;
    input string   test_name;
    input logic    got;
    input logic    expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %b | expected: %b",
                      test_name, got, expected);
    end
endtask

task check_sew;
    input string test_name;
    input sew_t  got;
    input sew_t  expected;
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

    // Reset
    rst = 1; we = 0;
    addr = '0; raddr = '0; data_in = '0;
    @(posedge clk); #1;
    rst = 0;

    // ----------------------------------------
    // Verificar valores tras reset
    // ----------------------------------------
    check_32("Reset vl",     vl,     32'h0);
    check_32("Reset vstart", vstart, 32'h0);
    check_1 ("Reset vxsat",  vxsat,  1'b0);
    check_1 ("Reset vill",   vill,   1'b0);
    check_32("Reset vlmax",  vlmax,  32'd16); // SEW8 por defecto
    check_sew("Reset sew",   sew,    SEW8);

    // ----------------------------------------
    // Escribir vtype con SEW8
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'hC21;
    data_in = 32'b000_000; // vsew=000 → SEW8
    @(posedge clk); #1;
    we = 0;
    check_sew("SEW8  sew_o",   sew,   SEW8);
    check_32 ("SEW8  vlmax",   vlmax, 32'd16);
    check_1  ("SEW8  vill",    vill,  1'b0);

    // ----------------------------------------
    // Escribir vtype con SEW16
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'hC21;
    data_in = 32'b000_001_000; // vsew=001 → SEW16
    @(posedge clk); #1;
    we = 0;
    check_sew("SEW16 sew_o",   sew,   SEW16);
    check_32 ("SEW16 vlmax",   vlmax, 32'd8);
    check_1  ("SEW16 vill",    vill,  1'b0);

    // ----------------------------------------
    // Escribir vtype con SEW32
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'hC21;
    data_in = 32'b000_010_000; // vsew=010 → SEW32
    @(posedge clk); #1;
    we = 0;
    check_sew("SEW32 sew_o",   sew,   SEW32);
    check_32 ("SEW32 vlmax",   vlmax, 32'd4);
    check_1  ("SEW32 vill",    vill,  1'b0);

    // ----------------------------------------
    // Escribir vtype con SEW64
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'hC21;
    data_in = 32'b000_011_000; // vsew=011 → SEW64
    @(posedge clk); #1;
    we = 0;
    check_sew("SEW64 sew_o",   sew,   SEW64);
    check_32 ("SEW64 vlmax",   vlmax, 32'd2);
    check_1  ("SEW64 vill",    vill,  1'b0);

    // ----------------------------------------
    // vtype inválido → vill = 1
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'hC21;
    data_in = 32'b000_100_000; // vsew=100 → no soportado
    @(posedge clk); #1;
    we = 0;
    check_1("vill activo con SEW inválido", vill, 1'b1);
    check_sew("vill → sew_o por defecto",  sew,  SEW8);
    check_32("vill → vlmax por defecto",   vlmax, 32'd16);

    // ----------------------------------------
    // vlmul siempre 000
    // ----------------------------------------
    check_32("vlmul fijo", {29'b0, vlmul}, 32'h0);

    // ----------------------------------------
    // Escribir y leer vl
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'hC20;
    data_in = 32'd8;
    @(posedge clk); #1;
    we = 0;
    check_32("vl escritura", vl, 32'd8);
    raddr = 12'hC20; #1;
    check_32("vl lectura genérica", rdata, 32'd8);

    // ----------------------------------------
    // Escribir y leer vstart
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'h008;
    data_in = 32'd4;
    @(posedge clk); #1;
    we = 0;
    check_32("vstart escritura", vstart, 32'd4);
    raddr = 12'h008; #1;
    check_32("vstart lectura genérica", rdata, 32'd4);

    // ----------------------------------------
    // Escribir y leer vxsat
    // ----------------------------------------
    @(posedge clk);
    we = 1; addr = 12'h009;
    data_in = 32'd1;
    @(posedge clk); #1;
    we = 0;
    check_1("vxsat escritura", vxsat, 1'b1);
    raddr = 12'h009; #1;
    check_32("vxsat lectura genérica", rdata, 32'd1);

    // ----------------------------------------
    // vlenb solo lectura = 16
    // ----------------------------------------
    raddr = 12'hC22; #1;
    check_32("vlenb solo lectura", rdata, 32'd16);

    // Intentar escribir vlenb (no debería cambiar)
    @(posedge clk);
    we = 1; addr = 12'hC22;
    data_in = 32'd99;
    @(posedge clk); #1;
    we = 0;
    raddr = 12'hC22; #1;
    check_32("vlenb no escribible", rdata, 32'd16);

    // ----------------------------------------
    // Reset limpia todo
    // ----------------------------------------
    @(posedge clk);
    rst = 1;
    @(posedge clk); #1;
    rst = 0;
    check_32("Reset final vl",     vl,     32'h0);
    check_32("Reset final vstart", vstart, 32'h0);
    check_1 ("Reset final vxsat",  vxsat,  1'b0);
    check_1 ("Reset final vill",   vill,   1'b0);

    $display("---- Tests completados ----");
    $finish;
end

endmodule