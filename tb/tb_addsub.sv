import vpu_pkg::*;

module tb_addsub;

// ---- Señales ----
logic       clk;
vector_t    vs1, vs2, result;
sew_t       sew;
funct6_opi_t op;

// ---- DUT ----
vpu_addsub dut (
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

    // --- SEW8: suma ---
    @(posedge clk);
    sew = SEW8; op = OPI_VADD;
    vs1.i8b = '{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
    vs2.i8b = '{1,1,1,1,1,1,1,1,1, 1, 1, 1, 1, 1, 1, 1};
    check("SEW8  VADD", {8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8,8'd9,
                         8'd10,8'd11,8'd12,8'd13,8'd14,8'd15,8'd16,8'd17});

    // --- SEW8: resta ---
    @(posedge clk);
    sew = SEW8; op = OPI_VSUB;
    vs2.i8b = '{10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10};
    vs1.i8b = '{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 9, 9, 9, 9, 9};
    check("SEW8  VSUB", {8'd9,8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2,
                         8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1});

    // --- SEW8: resta inversa ---
    @(posedge clk);
    sew = SEW8; op = OPI_VRSUB;
    vs1.i8b = '{10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10};
    vs2.i8b = '{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 9, 9, 9, 9, 9};
    check("SEW8  VRSUB", {8'd9,8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2,
                          8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1,8'd1});

    // --- SEW16: vminu ---
    @(posedge clk);
    sew = SEW16; op = OPI_VMINU;
    vs1.i16b = '{16'd10, 16'd20, 16'd30, 16'd40, 16'd50, 16'd60, 16'd70, 16'd80};
    vs2.i16b = '{16'd15, 16'd15, 16'd15, 16'd15, 16'd15, 16'd15, 16'd15, 16'd15};
    check("SEW16 VMINU", {16'd10,16'd15,16'd15,16'd15,
                          16'd15,16'd15,16'd15,16'd15});

    // --- SEW32: vmax con signo ---
    @(posedge clk);
    sew = SEW32; op = OPI_VMAX;
    vs1.i32b = '{32'hFFFFFFFF, 32'd200, 32'd300, 32'd400}; // -1 en signed
    vs2.i32b = '{32'd1,        32'd100, 32'd400, 32'd300};
    check("SEW32 VMAX", {32'd1, 32'd200, 32'd400, 32'd400});

    // --- SEW64: suma ---
    @(posedge clk);
    sew = SEW64; op = OPI_VADD;
    vs1.i64b = '{64'hFFFFFFFF, 64'h1};
    vs2.i64b = '{64'h1,        64'hFFFFFFFF};
    check("SEW64 VADD", {64'h100000000, 64'h100000000});

    $display("---- Tests completados ----");
    $finish;
end

endmodule