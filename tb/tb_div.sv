
import vpu_pkg::*;

module tb_div;

// ---- Señales ----
logic        clk;
vector_t     vs1, vs2, result;
sew_t        sew;
funct6_opm_t op;

// ---- DUT ----
vpu_div dut (
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

    // --- VDIVU SEW8 ---
    @(posedge clk);
    sew = SEW8; op = OPM_VDIVU;
    vs2.i8b = '{16{8'd100}};
    vs1.i8b = '{16{8'd10}};
    // 100 / 10 = 10
    check("VDIVU SEW8", {16{8'd10}});

    // --- VDIV SEW8 signed ---
    @(posedge clk);
    sew = SEW8; op = OPM_VDIV;
    vs2.i8b = '{16{8'hF6}};  // -10 en signed
    vs1.i8b = '{16{8'd2}};
    // -10 / 2 = -5 = 0xFB
    check("VDIV SEW8", {16{8'hFB}});

    //$display("vs2.i8b[0] = %0d (signed: %0d)", vs2.i8b[0], $signed(vs2.i8b[0]));
    //$display("vs1.i8b[0] = %0d", vs1.i8b[0]);
    //$display("result.i8b[0] = %h (signed: %0d)", result.i8b[0], $signed(result.i8b[0]));


    // --- VREMU SEW8 ---
    @(posedge clk);
    sew = SEW8; op = OPM_VREMU;
    vs2.i8b = '{16{8'd10}};
    vs1.i8b = '{16{8'd3}};
    // 10 % 3 = 1
    check("VREMU SEW8", {16{8'd1}});

    // --- VREM SEW8 signed ---
    @(posedge clk);
    sew = SEW8; op = OPM_VREM;
    vs2.i8b = '{16{8'hF6}};  // -10 en signed
    vs1.i8b = '{16{8'd3}};
    // -10 % 3 = -1 = 0xFF
    check("VREM SEW8", {16{8'hFF}});

    // --- VDIVU SEW8 división por cero ---
    @(posedge clk);
    sew = SEW8; op = OPM_VDIVU;
    vs2.i8b = '{16{8'd42}};
    vs1.i8b = '{16{8'd0}};
    // división por cero → todos unos
    check("VDIVU SEW8 div/0", {16{8'hFF}});

    // --- VREMU SEW8 división por cero ---
    @(posedge clk);
    sew = SEW8; op = OPM_VREMU;
    vs2.i8b = '{16{8'd42}};
    vs1.i8b = '{16{8'd0}};
    // división por cero → devuelve vs2
    check("VREMU SEW8 div/0", {16{8'd42}});

    // ----------------------------------------
    // SEW16
    // ----------------------------------------

    // --- VDIVU SEW16 ---
    @(posedge clk);
    sew = SEW16; op = OPM_VDIVU;
    vs2.i16b = '{8{16'd1000}};
    vs1.i16b = '{8{16'd10}};
    // 1000 / 10 = 100
    check("VDIVU SEW16", {8{16'd100}});

    // --- VDIV SEW16 signed ---
    @(posedge clk);
    sew = SEW16; op = OPM_VDIV;
    vs2.i16b = '{8{16'hFF9C}};  // -100 en signed
    vs1.i16b = '{8{16'd10}};
    // -100 / 10 = -10 = 0xFFF6
    check("VDIV SEW16", {8{16'hFFF6}});

    //$display("vs2.i16b[0] = %0d (signed: %0d)", vs2.i16b[0], $signed(vs2.i16b[0]));
    //$display("vs1.i16b[0] = %0d", vs1.i16b[0]);
    //$display("result.i16b[0] = %h (signed: %0d)", result.i16b[0], $signed(result.i16b[0]));
    //$display("dut.sew_i = %0d", dut.sew_i);
    //$display("dut.op_i = %0d", dut.op_i);

    // --- VREMU SEW16 ---
    @(posedge clk);
    sew = SEW16; op = OPM_VREMU;
    vs2.i16b = '{8{16'd1001}};
    vs1.i16b = '{8{16'd10}};
    // 1001 % 10 = 1
    check("VREMU SEW16", {8{16'd1}});

    // --- VDIVU SEW16 división por cero ---
    @(posedge clk);
    sew = SEW16; op = OPM_VDIVU;
    vs2.i16b = '{8{16'd1234}};
    vs1.i16b = '{8{16'd0}};
    // división por cero → todos unos
    check("VDIVU SEW16 div/0", {8{16'hFFFF}});

    // ----------------------------------------
    // SEW32
    // ----------------------------------------

    // --- VDIVU SEW32 ---
    @(posedge clk);
    sew = SEW32; op = OPM_VDIVU;
    vs2.i32b = '{4{32'd1000000}};
    vs1.i32b = '{4{32'd1000}};
    // 1000000 / 1000 = 1000
    check("VDIVU SEW32", {4{32'd1000}});

    // --- VDIV SEW32 signed ---
    @(posedge clk);
    sew = SEW32; op = OPM_VDIV;
    vs2.i32b = '{4{32'hFFFFFC18}};  // -1000 en signed
    vs1.i32b = '{4{32'd10}};
    // -1000 / 10 = -100 = 0xFFFFFF9C
    check("VDIV SEW32", {4{32'hFFFFFF9C}});

    // --- VREMU SEW32 ---
    @(posedge clk);
    sew = SEW32; op = OPM_VREMU;
    vs2.i32b = '{4{32'd1000001}};
    vs1.i32b = '{4{32'd1000}};
    // 1000001 % 1000 = 1
    check("VREMU SEW32", {4{32'd1}});

    // --- VREM SEW32 signed ---
    @(posedge clk);
    sew = SEW32; op = OPM_VREM;
    vs2.i32b = '{4{32'hFFFFFC18}};  // -1000 en signed
    vs1.i32b = '{4{32'd7}};
    // -1000 % 7 = -6 = 0xFFFFFFFA
    check("VREM SEW32", {4{32'hFFFFFFFA}});

    // --- VDIVU SEW32 división por cero ---
    @(posedge clk);
    sew = SEW32; op = OPM_VDIVU;
    vs2.i32b = '{4{32'd99999}};
    vs1.i32b = '{4{32'd0}};
    // división por cero → todos unos
    check("VDIVU SEW32 div/0", {4{32'hFFFFFFFF}});

    // --- VREMU SEW32 división por cero ---
    @(posedge clk);
    sew = SEW32; op = OPM_VREMU;
    vs2.i32b = '{4{32'd99999}};
    vs1.i32b = '{4{32'd0}};
    // división por cero → devuelve vs2
    check("VREMU SEW32 div/0", {4{32'd99999}});

    // ----------------------------------------
    // SEW64
    // ----------------------------------------

    // --- VDIVU SEW64 ---
    @(posedge clk);
    sew = SEW64; op = OPM_VDIVU;
    vs2.i64b = '{2{64'd1000000000}};
    vs1.i64b = '{2{64'd1000}};
    // 1000000000 / 1000 = 1000000
    check("VDIVU SEW64", {2{64'd1000000}});

    // --- VDIV SEW64 signed ---
    @(posedge clk);
    sew = SEW64; op = OPM_VDIV;
    vs2.i64b = '{2{64'hFFFFFFFFC4653600}};  // -1000000000 en signed
    vs1.i64b = '{2{64'd1000}};
    // -1000000000 / 1000 = -1000000 = 0xFFFFFFFFFFF0BDC0
    check("VDIV SEW64", {2{64'hFFFFFFFFFFF0BDC0}});

    // --- VDIVU SEW64 división por cero ---
    @(posedge clk);
    sew = SEW64; op = OPM_VDIVU;
    vs2.i64b = '{2{64'd123456789}};
    vs1.i64b = '{2{64'd0}};
    // división por cero → todos unos
    check("VDIVU SEW64 div/0", {2{64'hFFFFFFFFFFFFFFFF}});

    // --- VREMU SEW64 división por cero ---
    @(posedge clk);
    sew = SEW64; op = OPM_VREMU;
    vs2.i64b = '{2{64'd123456789}};
    vs1.i64b = '{2{64'd0}};
    // división por cero → devuelve vs2
    check("VREMU SEW64 div/0", {2{64'd123456789}});

    $display("---- Tests completados ----");
    $finish;
end

endmodule