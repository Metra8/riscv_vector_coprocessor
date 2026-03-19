// tb_mult.sv
import vpu_pkg::*;

module tb_mult;

// ---- Señales ----
logic        clk;
vector_t     vs1, vs2, result;
sew_t        sew;
funct6_opm_t op;

// ---- DUT ----
vpu_mult dut (
    .vs1_i    (vs1),
    .vs2_i    (vs2),
    .sew_i    (sew),
    .op_i     (op),
    .result_o (result)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tarea de verificación ----
task check;
    input string test_name;
    input logic [127:0] expected;
    begin
        @(posedge clk); #1;
        if (result.i128b === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %h | expected: %h",
                      test_name, result.i128b, expected);
    end
endtask

// ---- Tests ----
initial begin

    // ----------------------------------------
    // SEW8
    // ----------------------------------------

    // --- VMUL SEW8: mitad baja ---
    @(posedge clk);
    sew = SEW8; op = OPM_VMUL;
    vs2.i8b = '{8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3,
                8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3};
    vs1.i8b = '{8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4,
                8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4};
    // 3*4 = 12 → mitad baja = 12
    check("VMUL SEW8", {16{8'd12}});

    // --- VMULHU SEW8: mitad alta unsigned ---
    @(posedge clk);
    sew = SEW8; op = OPM_VMULHU;
    vs2.i8b = '{16{8'hFF}};  // 255
    vs1.i8b = '{16{8'hFF}};  // 255
    // 255*255 = 65025 = 0xFE01 → mitad alta = 0xFE
    check("VMULHU SEW8", {16{8'hFE}});

    // --- VMULH SEW8: mitad alta signed ---
    @(posedge clk);
    sew = SEW8; op = OPM_VMULH;
    vs2.i8b = '{16{8'hFF}};  // -1 en signed
    vs1.i8b = '{16{8'hFF}};  // -1 en signed
    // -1 * -1 = 1 → mitad alta = 0x00
    check("VMULH SEW8", {16{8'h00}});

    // --- VMULHSU SEW8: mitad alta signed x unsigned ---
    @(posedge clk);
    sew = SEW8; op = OPM_VMULHSU;
    vs2.i8b = '{16{8'hFF}};  // -1 en signed
    vs1.i8b = '{16{8'd2}};   // 2 unsigned
    // -1 * 2 = -2 = 0xFFFE → mitad alta = 0xFF
    check("VMULHSU SEW8", {16{8'hFF}});

    // ----------------------------------------
    // SEW16
    // ----------------------------------------

    // --- VMUL SEW16 ---
    @(posedge clk);
    sew = SEW16; op = OPM_VMUL;
    vs2.i16b = '{8{16'd100}};
    vs1.i16b = '{8{16'd200}};
    // 100*200 = 20000 = 0x4E20 → mitad baja = 0x4E20
    check("VMUL SEW16", {8{16'h4E20}});

    // --- VMULHU SEW16 ---
    @(posedge clk);
    sew = SEW16; op = OPM_VMULHU;
    vs2.i16b = '{8{16'hFFFF}};  // 65535
    vs1.i16b = '{8{16'hFFFF}};  // 65535
    // 65535*65535 = 0xFFFE0001 → mitad alta = 0xFFFE
    check("VMULHU SEW16", {8{16'hFFFE}});

    // --- VMULH SEW16 ---
    @(posedge clk);
    sew = SEW16; op = OPM_VMULH;
    vs2.i16b = '{8{16'hFFFF}};  // -1 signed
    vs1.i16b = '{8{16'hFFFF}};  // -1 signed
    // -1 * -1 = 1 → mitad alta = 0x0000
    check("VMULH SEW16", {8{16'h0000}});

    // ----------------------------------------
    // SEW32
    // ----------------------------------------

    // --- VMUL SEW32 ---
    @(posedge clk);
    sew = SEW32; op = OPM_VMUL;
    vs2.i32b = '{4{32'd1000}};
    vs1.i32b = '{4{32'd2000}};
    // 1000*2000 = 2000000 = 0x1E8480
    check("VMUL SEW32", {4{32'h001E8480}});

    // --- VMULHU SEW32 ---
    @(posedge clk);
    sew = SEW32; op = OPM_VMULHU;
    vs2.i32b = '{4{32'hFFFFFFFF}};
    vs1.i32b = '{4{32'hFFFFFFFF}};
    // 0xFFFFFFFF * 0xFFFFFFFF = 0xFFFFFFFE00000001 → mitad alta = 0xFFFFFFFE
    check("VMULHU SEW32", {4{32'hFFFFFFFE}});

    // --- VMULH SEW32 ---
    @(posedge clk);
    sew = SEW32; op = OPM_VMULH;
    vs2.i32b = '{4{32'hFFFFFFFF}};  // -1 signed
    vs1.i32b = '{4{32'hFFFFFFFF}};  // -1 signed
    // -1 * -1 = 1 → mitad alta = 0x00000000
    check("VMULH SEW32", {4{32'h00000000}});

    // ----------------------------------------
    // SEW64
    // ----------------------------------------

    // --- VMUL SEW64 ---
    @(posedge clk);
    sew = SEW64; op = OPM_VMUL;
    vs2.i64b = '{2{64'd1000000}};
    vs1.i64b = '{2{64'd1000000}};
    // 1000000 * 1000000 = 1000000000000 = 0xE8D4A51000
    check("VMUL SEW64", {2{64'h000000E8D4A51000}});

    // --- VMULHU SEW64 ---
    @(posedge clk);
    sew = SEW64; op = OPM_VMULHU;
    vs2.i64b = '{2{64'hFFFFFFFFFFFFFFFF}};
    vs1.i64b = '{2{64'hFFFFFFFFFFFFFFFF}};
    // mitad alta = 0xFFFFFFFFFFFFFFFE
    check("VMULHU SEW64", {2{64'hFFFFFFFFFFFFFFFE}});

    // --- VMULH SEW64 ---
    @(posedge clk);
    sew = SEW64; op = OPM_VMULH;
    vs2.i64b = '{2{64'hFFFFFFFFFFFFFFFF}};  // -1 signed
    vs1.i64b = '{2{64'hFFFFFFFFFFFFFFFF}};  // -1 signed
    // -1 * -1 = 1 → mitad alta = 0
    check("VMULH SEW64", {2{64'h0000000000000000}});

    $display("---- Tests completados ----");
    $finish;
end

endmodule