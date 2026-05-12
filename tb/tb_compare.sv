import vpu_pkg::*;

module tb_compare;

// ---- Señales ----
logic        clk;
vector_t     vs1, vs2;
sew_t        sew;
funct6_opi_t op;
logic [15:0] result;

// ---- DUT ----
vpu_compare dut (
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
    input string      test_name;
    input logic [15:0] expected;
    begin
        @(posedge clk); #1;
        if (result === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %b | expected: %b",
                      test_name, result, expected);
    end
endtask

// ---- Tests ----
initial begin

    // ----------------------------------------
    // SEW8
    // ----------------------------------------

    // --- VMSEQ SEW8 ---
    @(posedge clk);
    sew = SEW8; op = OPI_VMSEQ;
    vs2.i8b = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8,
                8'd9, 8'd10, 8'd11, 8'd12, 8'd13, 8'd14, 8'd15, 8'd16};
    vs1.i8b = '{8'd1, 8'd0, 8'd3, 8'd0, 8'd5, 8'd0, 8'd7, 8'd0,
                8'd9, 8'd0, 8'd11, 8'd0, 8'd13, 8'd0, 8'd15, 8'd0};
    // i8b[0]=1==1, i8b[1]=2!=0... iguales en indices pares → bits altos activos
    check("VMSEQ SEW8", 16'b1010101010101010);

    // --- VMSNE SEW8 ---
    @(posedge clk);
    sew = SEW8; op = OPI_VMSNE;
    check("VMSNE SEW8", 16'b0101010101010101);

    // --- VMSLTU SEW8 unsigned ---
    @(posedge clk);
    sew = SEW8; op = OPI_VMSLTU;
    vs2.i8b = '{8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10,
                8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10};
    vs1.i8b = '{8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,
                8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5};
    // i8b[0]: 5<10=1, i8b[1]: 10<5=0 → bits altos activos
    check("VMSLTU SEW8", 16'b1010101010101010);

    // --- VMSLT SEW8 signed ---
    @(posedge clk);
    sew = SEW8; op = OPI_VMSLT;
    vs2.i8b = '{8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10,
                8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10};
    vs1.i8b = '{8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF,
                8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF};
    // i8b[0]: -1<10=1, i8b[1]: 10<-1=0 → bits altos activos
    check("VMSLT SEW8", 16'b1010101010101010);

    // --- VMSLEU SEW8 unsigned ---
    @(posedge clk);
    sew = SEW8; op = OPI_VMSLEU;
    vs2.i8b = '{8'd5,  8'd10, 8'd10, 8'd5,  8'd5,  8'd10, 8'd10, 8'd5,
                8'd5,  8'd10, 8'd10, 8'd5,  8'd5,  8'd10, 8'd10, 8'd5};
    vs1.i8b = '{8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,
                8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5};
    // i8b[0]: 5<=10=1, i8b[1]: 10<=5=0, i8b[2]: 10<=10=1, i8b[3]: 5<=5=1
    check("VMSLEU SEW8", 16'b1011101110111011);

    // --- VMSGTU SEW8 unsigned ---
    @(posedge clk);
    sew = SEW8; op = OPI_VMSGTU;
    vs2.i8b = '{8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,
                8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5};
    vs1.i8b = '{8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10,
                8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10, 8'd5,  8'd10};
    // i8b[0]: 10>5=1, i8b[1]: 5>10=0 → bits altos activos
    check("VMSGTU SEW8", 16'b1010101010101010);

    // --- VMSGT SEW8 signed ---
    @(posedge clk);
    sew = SEW8; op = OPI_VMSGT;
    vs2.i8b = '{8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF,
                8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF};
    vs1.i8b = '{8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10,
                8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10, 8'hFF, 8'd10};
    // i8b[0]: 10>-1=1, i8b[1]: -1>10=0 → bits altos activos
    check("VMSGT SEW8", 16'b1010101010101010);

    // ----------------------------------------
    // SEW16
    // ----------------------------------------

    // --- VMSEQ SEW16 ---
    @(posedge clk);
    sew = SEW16; op = OPI_VMSEQ;
    vs2.i16b = '{16'd100, 16'd200, 16'd100, 16'd200,
                 16'd100, 16'd200, 16'd100, 16'd200};
    vs1.i16b = '{16'd100, 16'd999, 16'd100, 16'd999,
                 16'd100, 16'd999, 16'd100, 16'd999};
    // i16b[0]=100==100=1, i16b[1]=200!=999=0 → bits altos activos
    check("VMSEQ SEW16", 16'b0000000010101010);

    // --- VMSLT SEW16 signed ---
    @(posedge clk);
    sew = SEW16; op = OPI_VMSLT;
    vs2.i16b = '{16'hFFFF, 16'd100,  16'hFFFF, 16'd100,
                 16'hFFFF, 16'd100,  16'hFFFF, 16'd100};
    vs1.i16b = '{16'd100,  16'hFFFF, 16'd100,  16'hFFFF,
                 16'd100,  16'hFFFF, 16'd100,  16'hFFFF};
    // i16b[0]: -1<100=1, i16b[1]: 100<-1=0 → bits altos activos
    check("VMSLT SEW16", 16'b0000000010101010);

    // ----------------------------------------
    // SEW32
    // ----------------------------------------

    // --- VMSEQ SEW32 ---
    @(posedge clk);
    sew = SEW32; op = OPI_VMSEQ;
    vs2.i32b = '{32'd1000, 32'd2000, 32'd1000, 32'd2000};
    vs1.i32b = '{32'd1000, 32'd9999, 32'd1000, 32'd9999};
    // i32b[0]=1000==1000=1, i32b[1]=2000!=9999=0 → bits altos activos
    check("VMSEQ SEW32", 16'b0000000000001010);

    // --- VMSLTU SEW32 unsigned ---
    @(posedge clk);
    sew = SEW32; op = OPI_VMSLTU;
    vs2.i32b = '{32'd100, 32'd999, 32'd100, 32'd999};
    vs1.i32b = '{32'd999, 32'd100, 32'd999, 32'd100};
    // i32b[0]: 100<999=1, i32b[1]: 999<100=0 → bits altos activos
    check("VMSLTU SEW32", 16'b0000000000001010);

    // --- VMSGT SEW32 signed ---
    @(posedge clk);
    sew = SEW32; op = OPI_VMSGT;
    vs2.i32b = '{32'd999,      32'hFFFFFFFF, 32'd999,      32'hFFFFFFFF};
    vs1.i32b = '{32'hFFFFFFFF, 32'd999,      32'hFFFFFFFF, 32'd999};
    // i32b[0]: 999>-1=1, i32b[1]: -1>999=0 → bits altos activos
    check("VMSGT SEW32", 16'b0000000000001010);

    // ----------------------------------------
    // SEW64
    // ----------------------------------------

    // --- VMSEQ SEW64 ---
    @(posedge clk);
    sew = SEW64; op = OPI_VMSEQ;
    vs2.i64b = '{64'd1000000, 64'd2000000};
    vs1.i64b = '{64'd1000000, 64'd9999999};
    // i64b[0]=igual=1, i64b[1]=distinto=0 → bit alto activo
    check("VMSEQ SEW64", 16'b0000000000000010);

    // --- VMSLT SEW64 signed ---
    @(posedge clk);
    sew = SEW64; op = OPI_VMSLT;
    vs2.i64b = '{64'hFFFFFFFFFFFFFFFF, 64'd100};
    vs1.i64b = '{64'd100,              64'hFFFFFFFFFFFFFFFF};
    // i64b[0]: -1<100=1, i64b[1]: 100<-1=0 → bit alto activo
    check("VMSLT SEW64", 16'b0000000000000010);

    // --- VMSGTU SEW64 unsigned ---
    @(posedge clk);
    sew = SEW64; op = OPI_VMSGTU;
    vs2.i64b = '{64'hFFFFFFFFFFFFFFFF, 64'd100};
    vs1.i64b = '{64'd100,              64'hFFFFFFFFFFFFFFFF};
    // i64b[0]: 0xFFFF>100 unsigned=1, i64b[1]: 100>0xFFFF=0 → bit alto activo
    check("VMSGTU SEW64", 16'b0000000000000010);

    $display("---- Tests completados ----");
    $finish;
end

endmodule