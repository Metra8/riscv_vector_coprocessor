module tb_core_regfile;

// ---- Señales ----
logic        clk, rst;
logic [4:0]  rs1_addr, rs2_addr, rd_addr;
logic [31:0] rs1_data, rs2_data, rd_data;
logic        we;

// ---- DUT ----
regfile dut (
    .clk_i      (clk),
    .rst_i      (rst),
    .rs1_addr_i (rs1_addr),
    .rs2_addr_i (rs2_addr),
    .rd_addr_i  (rd_addr),
    .rs1_data_o (rs1_data),
    .rs2_data_o (rs2_data),
    .rd_data_i  (rd_data),
    .we_i       (we)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tarea de verificación ----
task check;
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

// ---- Tests ----
initial begin
    rst = 1; we = 0;
    rs1_addr = '0; rs2_addr = '0;
    rd_addr = '0; rd_data = '0;
    @(posedge clk); #1;
    rst = 0;

    // ----------------------------------------
    // x0 siempre es 0
    // ----------------------------------------
    rs1_addr = 5'd0; #1;
    check("x0 lectura siempre 0", rs1_data, 32'h0);

    // Intentar escribir x0
    @(posedge clk);
    rd_addr = 5'd0; rd_data = 32'hDEADBEEF; we = 1;
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd0; #1;
    check("x0 no escribible", rs1_data, 32'h0);

    // ----------------------------------------
    // Escritura y lectura básica
    // ----------------------------------------
    @(posedge clk);
    rd_addr = 5'd1; rd_data = 32'hCAFEBABE; we = 1;
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd1; #1;
    check("Escritura x1", rs1_data, 32'hCAFEBABE);

    @(posedge clk);
    rd_addr = 5'd2; rd_data = 32'h12345678; we = 1;
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd2; #1;
    check("Escritura x2", rs1_data, 32'h12345678);

    // ----------------------------------------
    // Lectura simultánea de dos registros
    // ----------------------------------------
    rs1_addr = 5'd1; rs2_addr = 5'd2; #1;
    check("Lectura simultánea x1", rs1_data, 32'hCAFEBABE);
    check("Lectura simultánea x2", rs2_data, 32'h12345678);

    // ----------------------------------------
    // Escritura sin we no modifica el registro
    // ----------------------------------------
    @(posedge clk);
    rd_addr = 5'd1; rd_data = 32'hFFFFFFFF; we = 0;
    @(posedge clk); #1;
    rs1_addr = 5'd1; #1;
    check("Sin we no escribe", rs1_data, 32'hCAFEBABE);

    // ----------------------------------------
    // Escribir varios registros
    // ----------------------------------------
    @(posedge clk);
    rd_addr = 5'd10; rd_data = 32'd100; we = 1;
    @(posedge clk); #1;
    rd_addr = 5'd11; rd_data = 32'd200; we = 1;
    @(posedge clk); #1;
    rd_addr = 5'd12; rd_data = 32'd300; we = 1;
    @(posedge clk); #1;
    we = 0;
    rs1_addr = 5'd10; rs2_addr = 5'd11; #1;
    check("x10 = 100", rs1_data, 32'd100);
    check("x11 = 200", rs2_data, 32'd200);
    rs1_addr = 5'd12; #1;
    check("x12 = 300", rs1_data, 32'd300);

    // ----------------------------------------
    // Reset limpia todos los registros
    // ----------------------------------------
    @(posedge clk);
    rst = 1;
    @(posedge clk); #1;
    rst = 0;
    rs1_addr = 5'd1; rs2_addr = 5'd2; #1;
    check("Reset limpia x1", rs1_data, 32'h0);
    check("Reset limpia x2", rs2_data, 32'h0);
    rs1_addr = 5'd10; #1;
    check("Reset limpia x10", rs1_data, 32'h0);

    $display("---- Tests completados ----");
    $finish;
end

endmodule