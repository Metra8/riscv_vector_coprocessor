import vpu_pkg::*;

module tb_regfile;

// ---- Señales ----
logic        clk, rst;
logic [4:0]  rs1_addr, rs2_addr, rd_addr;
vector_t     rs1_data, rs2_data, v0_data, rd_data;
logic        we;
logic [15:0] elem_we;
sew_t        sew;

// ---- DUT ----
vpu_regfile dut (
    .clk_i      (clk),
    .rst_i      (rst),
    .rs1_addr_i (rs1_addr),
    .rs2_addr_i (rs2_addr),
    .rd_addr_i  (rd_addr),
    .rs1_data_o (rs1_data),
    .rs2_data_o (rs2_data),
    .v0_data_o  (v0_data),
    .rd_data_i  (rd_data),
    .we_i       (we),
    .elem_we_i  (elem_we),
    .sew_i      (sew)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tarea de verificación ----
task check;
    input string     test_name;
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

// ---- Tests ----
initial begin

    // Reset
    rst = 1; we = 0;
    rs1_addr = 0; rs2_addr = 0; rd_addr = 0;
    rd_data.i128b = '0; elem_we = '0; sew = SEW32;
    @(posedge clk); #1;
    rst = 0;

    // --- Escritura y lectura básica SEW32, todos los elementos ---
    @(posedge clk);
    rd_addr = 5'd1; sew = SEW32;
    rd_data.i32b = '{32'hDEAD, 32'hBEEF, 32'hCAFE, 32'hBABE};
    elem_we = 16'hFFFF; we = 1;
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd1;
    #1;
    check("SEW32 escritura completa",
          rs1_data.i128b,
          {32'hDEAD, 32'hBEEF, 32'hCAFE, 32'hBABE});

    // --- Escritura parcial SEW32: solo elementos 0 y 2 ---
    @(posedge clk);
    rd_addr = 5'd2; sew = SEW32;
    rd_data.i32b = '{32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF};
    elem_we = 16'hFFFF; we = 1; // primero escribir todo
    @(posedge clk); #1;
    // ahora escribir solo elementos 0 y 2
    rd_data.i32b = '{32'hAAAAAAAA, 32'hBBBBBBBB, 32'hCCCCCCCC, 32'hDDDDDDDD};
    elem_we = 16'b0000000000000101; // elementos 0 y 2
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd2; #1;
    // elem 0 y 2 actualizados, 1 y 3 mantienen 0xFFFFFFFF
    check("SEW32 escritura parcial elem 0 y 2",
          rs1_data.i128b,
          {32'hFFFFFFFF, 32'hBBBBBBBB, 32'hFFFFFFFF, 32'hDDDDDDDD});    

    // --- Escritura SEW8: todos los elementos ---
    @(posedge clk);
    rd_addr = 5'd3; sew = SEW8;
    rd_data.i8b = '{8'd1,8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8,
                    8'd9,8'd10,8'd11,8'd12,8'd13,8'd14,8'd15,8'd16};
    elem_we = 16'hFFFF; we = 1;
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd3; #1;
    check("SEW8 escritura completa",
          rs1_data.i128b,
          {8'd1,8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8,
           8'd9,8'd10,8'd11,8'd12,8'd13,8'd14,8'd15,8'd16});

    // --- Escritura SEW64: solo elemento 1 ---
    @(posedge clk);
    rd_addr = 5'd4; sew = SEW64;
    rd_data.i64b = '{64'hFFFFFFFFFFFFFFFF, 64'hFFFFFFFFFFFFFFFF};
    elem_we = 16'hFFFF; we = 1; // primero escribir todo
    @(posedge clk); #1;
    rd_data.i64b = '{64'hAAAAAAAAAAAAAAAA, 64'hBBBBBBBBBBBBBBBB};
    elem_we = 16'h0002; // solo elemento 1
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd4; #1;
    check("SEW64 escritura parcial elem 1",
          rs1_data.i128b,
          {64'hAAAAAAAAAAAAAAAA, 64'hFFFFFFFFFFFFFFFF});

    // --- Lectura de dos registros simultánea ---
    @(posedge clk);
    rd_addr = 5'd5; sew = SEW32;
    rd_data.i32b = '{32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444};
    elem_we = 16'hFFFF; we = 1;
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd1; rs2_addr = 5'd5; #1;
    check("Lectura simultánea rs1",
          rs1_data.i128b,
          {32'hDEAD, 32'hBEEF, 32'hCAFE, 32'hBABE});
    check("Lectura simultánea rs2",
          rs2_data.i128b,
          {32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444});

    // --- v0 siempre accesible como máscara ---
    @(posedge clk);
    rd_addr = 5'd0; sew = SEW32;
    rd_data.i128b = 128'hDEADBEEFCAFEBABE1234567890ABCDEF;
    elem_we = 16'hFFFF; we = 1;
    @(posedge clk); #1;
    we = 0; #1;
    check("v0 lectura como máscara",
          v0_data.i128b,
          128'hDEADBEEFCAFEBABE1234567890ABCDEF);

    // --- Reset limpia todos los registros ---
    @(posedge clk);
    rst = 1;
    @(posedge clk); #1;
    rst = 0;
    rs1_addr = 5'd1; #1;
    check("Reset limpia registros", rs1_data.i128b, 128'h0);

    $display("---- Tests completados ----");
    $finish;
end

endmodule