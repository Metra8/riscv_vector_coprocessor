import vpu_pkg::*;

module tb_logic;

// ---- Señales ----
logic        clk;
vector_t     vs1, vs2, result;
sew_t        sew;
funct6_opi_t op;

// ---- DUT ----
vpu_logic dut (
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
    // LÓGICA BIT A BIT (independiente del SEW)
    // ----------------------------------------

    // --- VAND ---
    @(posedge clk);
    op = OPI_VAND; sew = SEW32;
    vs1.i128b = 128'hFFFFFFFF_FFFFFFFF_00000000_FFFFFFFF;
    vs2.i128b = 128'h0F0F0F0F_0F0F0F0F_0F0F0F0F_0F0F0F0F;
    check("VAND", 128'h0F0F0F0F_0F0F0F0F_00000000_0F0F0F0F);

    // --- VOR ---
    @(posedge clk);
    op = OPI_VOR; sew = SEW32;
    vs1.i128b = 128'hF0F0F0F0_F0F0F0F0_F0F0F0F0_F0F0F0F0;
    vs2.i128b = 128'h0F0F0F0F_0F0F0F0F_0F0F0F0F_0F0F0F0F;
    check("VOR",  128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF);

    // --- VXOR ---
    @(posedge clk);
    op = OPI_VXOR; sew = SEW32;
    vs1.i128b = 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;
    vs2.i128b = 128'h0F0F0F0F_0F0F0F0F_0F0F0F0F_0F0F0F0F;
    check("VXOR", 128'hF0F0F0F0_F0F0F0F0_F0F0F0F0_F0F0F0F0);

    // ----------------------------------------
    // SHIFTS SEW8
    // ----------------------------------------

    // --- VSLL SEW8 ---
    @(posedge clk);
    op = OPI_VSLL; sew = SEW8;
    vs2.i8b = '{8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1,
                8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1};
    vs1.i8b = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd1, 8'd2, 8'd3, 8'd4,
                8'd1, 8'd2, 8'd3, 8'd4, 8'd1, 8'd2, 8'd3, 8'd4};
    // esperado: 1<<1=2, 1<<2=4, 1<<3=8, 1<<4=16 ...
    check("VSLL SEW8", {8'd2,8'd4,8'd8,8'd16,8'd2,8'd4,8'd8,8'd16,
                        8'd2,8'd4,8'd8,8'd16,8'd2,8'd4,8'd8,8'd16});

    // --- VSRL SEW8 ---
    @(posedge clk);
    op = OPI_VSRL; sew = SEW8;
    vs2.i8b = '{8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16,
                8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16, 8'd16};
    vs1.i8b = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd1, 8'd2, 8'd3, 8'd4,
                8'd1, 8'd2, 8'd3, 8'd4, 8'd1, 8'd2, 8'd3, 8'd4};
    // esperado: 16>>1=8, 16>>2=4, 16>>3=2, 16>>4=1 ...
    check("VSRL SEW8", {8'd8,8'd4,8'd2,8'd1,8'd8,8'd4,8'd2,8'd1,
                        8'd8,8'd4,8'd2,8'd1,8'd8,8'd4,8'd2,8'd1});

    // --- VSRA SEW8 (con signo) ---
    @(posedge clk);
    op = OPI_VSRA; sew = SEW8;
    vs2.i8b = '{8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0,
                8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0, 8'hF0};
    vs1.i8b = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd1, 8'd2, 8'd3, 8'd4,
                8'd1, 8'd2, 8'd3, 8'd4, 8'd1, 8'd2, 8'd3, 8'd4};
    // 0xF0 = -16 en signed: -16>>>1=-8(0xF8), >>>2=-4(0xFC), >>>3=-2(0xFE), >>>4=-1(0xFF)
    check("VSRA SEW8", {8'hF8,8'hFC,8'hFE,8'hFF,8'hF8,8'hFC,8'hFE,8'hFF,
                        8'hF8,8'hFC,8'hFE,8'hFF,8'hF8,8'hFC,8'hFE,8'hFF});

    // ----------------------------------------
    // SHIFTS SEW16
    // ----------------------------------------

    // --- VSLL SEW16 ---
    @(posedge clk);
    op = OPI_VSLL; sew = SEW16;
    vs2.i16b = '{16'd1, 16'd1, 16'd1, 16'd1, 16'd1, 16'd1, 16'd1, 16'd1};
    vs1.i16b = '{16'd1, 16'd2, 16'd3, 16'd4, 16'd5, 16'd6, 16'd7, 16'd8};
    // esperado: 2, 4, 8, 16, 32, 64, 128, 256
    check("VSLL SEW16", {16'd2,16'd4,16'd8,16'd16,
                         16'd32,16'd64,16'd128,16'd256});

    // ----------------------------------------
    // SHIFTS SEW32
    // ----------------------------------------

    // --- VSLL SEW32 ---
    @(posedge clk);
    op = OPI_VSLL; sew = SEW32;
    vs2.i32b = '{32'd1, 32'd1, 32'd1, 32'd1};
    vs1.i32b = '{32'd8, 32'd16, 32'd24, 32'd31};
    // esperado: 256, 65536, 16777216, 2147483648
    check("VSLL SEW32", {32'd256, 32'd65536, 32'd16777216, 32'd2147483648});

    // ----------------------------------------
    // SHIFTS SEW64
    // ----------------------------------------

    // --- VSLL SEW64 ---
    @(posedge clk);
    op = OPI_VSLL; sew = SEW64;
    vs2.i64b = '{64'd1, 64'd1};
    vs1.i64b = '{64'd32, 64'd63};
    // esperado: 1<<32, 1<<63
    check("VSLL SEW64", {64'h00000001_00000000, 64'h80000000_00000000});

    // --- VSRA SEW64 (con signo) ---
    @(posedge clk);
    op = OPI_VSRA; sew = SEW64;
    vs2.i64b = '{64'hFFFFFFFF_00000000, 64'hFFFFFFFF_00000000};
    vs1.i64b = '{64'd16, 64'd32};
    // negativo >>> 16 y >>> 32, extiende el signo
    check("VSRA SEW64", {64'hFFFFFFFF_FFFF0000, 64'hFFFFFFFF_FFFFFFFF});

    $display("---- Tests completados ----");
    $finish;
end

endmodule