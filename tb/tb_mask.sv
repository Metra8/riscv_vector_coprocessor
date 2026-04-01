import vpu_pkg::*;

module tb_mask;

// ---- Señales ----
logic        clk;
vector_t     v0;
sew_t        sew;
logic        vm;
logic [15:0] we;

// ---- DUT ----
vpu_mask dut (
    .v0_i  (v0),
    .sew_i (sew),
    .vm_i  (vm),
    .we_o  (we)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tarea de verificación ----
task check;
    input string      test_name;
    input logic [15:0] expected;
    begin
        @(posedge clk); #1;
        if (we === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %b | expected: %b",
                      test_name, we, expected);
    end
endtask

// ---- Tests ----
initial begin

    // --- vm=1: sin máscara, todos activos independientemente del SEW ---
    @(posedge clk);
    vm = 1; sew = SEW8;
    v0.i128b = '0;
    check("vm=1 SEW8  todos activos", 16'hFFFF);

    @(posedge clk);
    vm = 1; sew = SEW16;
    check("vm=1 SEW16 todos activos", 16'hFFFF);

    @(posedge clk);
    vm = 1; sew = SEW32;
    check("vm=1 SEW32 todos activos", 16'hFFFF);

    @(posedge clk);
    vm = 1; sew = SEW64;
    check("vm=1 SEW64 todos activos", 16'hFFFF);

    // --- vm=0 SEW8: 16 elementos, máscara completa ---
    @(posedge clk);
    vm = 0; sew = SEW8;
    v0.i128b = '0;
    v0.i16b[0] = 16'b1010101010101010; // alternos activos
    check("vm=0 SEW8  alternos",    16'b1010101010101010);

    @(posedge clk);
    vm = 0; sew = SEW8;
    v0.i16b[0] = 16'hFFFF; // todos activos
    check("vm=0 SEW8  todos",       16'hFFFF);

    @(posedge clk);
    vm = 0; sew = SEW8;
    v0.i16b[0] = 16'h0000; // ninguno activo
    check("vm=0 SEW8  ninguno",     16'h0000);

    // --- vm=0 SEW16: 8 elementos, solo bits [7:0] válidos ---
    @(posedge clk);
    vm = 0; sew = SEW16;
    v0.i16b[0] = 16'hFFFF;
    check("vm=0 SEW16 todos",       16'h00FF);

    @(posedge clk);
    vm = 0; sew = SEW16;
    v0.i16b[0] = 16'b0000000010101010; // alternos en bits bajos
    check("vm=0 SEW16 alternos",    16'b0000000010101010);

    @(posedge clk);
    vm = 0; sew = SEW16;
    v0.i16b[0] = 16'h0000;
    check("vm=0 SEW16 ninguno",     16'h0000);

    // --- vm=0 SEW32: 4 elementos, solo bits [3:0] válidos ---
    @(posedge clk);
    vm = 0; sew = SEW32;
    v0.i16b[0] = 16'hFFFF;
    check("vm=0 SEW32 todos",       16'h000F);

    @(posedge clk);
    vm = 0; sew = SEW32;
    v0.i16b[0] = 16'b0000000000001010; // elementos 1 y 3 activos
    check("vm=0 SEW32 alternos",    16'b0000000000001010);

    @(posedge clk);
    vm = 0; sew = SEW32;
    v0.i16b[0] = 16'h0000;
    check("vm=0 SEW32 ninguno",     16'h0000);

    // --- vm=0 SEW64: 2 elementos, solo bits [1:0] válidos ---
    @(posedge clk);
    vm = 0; sew = SEW64;
    v0.i16b[0] = 16'hFFFF;
    check("vm=0 SEW64 todos",       16'h0003);

    @(posedge clk);
    vm = 0; sew = SEW64;
    v0.i16b[0] = 16'b0000000000000001; // solo elemento 0 activo
    check("vm=0 SEW64 solo elem0",  16'h0001);

    @(posedge clk);
    vm = 0; sew = SEW64;
    v0.i16b[0] = 16'h0000;
    check("vm=0 SEW64 ninguno",     16'h0000);

    $display("---- Tests completados ----");
    $finish;
end

endmodule