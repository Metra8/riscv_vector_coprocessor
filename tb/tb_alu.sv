import core_pkg::*;

module tb_alu;

// ---- Señales ----
logic        clk;
logic [31:0] a, b, result;
alu_op_t     op;
logic        zero, neg, carry;

// ---- DUT ----
alu dut (
    .a_i      (a),
    .b_i      (b),
    .op_i     (op),
    .result_o (result),
    .zero_o   (zero),
    .neg_o    (neg),
    .carry_o  (carry)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tareas de verificación ----
// Sin @posedge porque la ALU es combinacional
task check;
    input string       test_name;
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

    // ----------------------------------------
    // ADD
    // ----------------------------------------
    op = ALU_ADD; a = 32'd10; b = 32'd20; #1;
    check  ("ADD 10+20",    result, 32'd30);
    check_1("ADD zero=0",   zero,   1'b0);
    check_1("ADD neg=0",    neg,    1'b0);
    check_1("ADD carry=0",  carry,  1'b0);

    // ADD con overflow
    op = ALU_ADD; a = 32'hFFFFFFFF; b = 32'd1; #1;
    check  ("ADD overflow",         result, 32'h0);
    check_1("ADD overflow zero=1",  zero,   1'b1);
    check_1("ADD overflow carry=1", carry,  1'b1);

    // ----------------------------------------
    // SUB
    // ----------------------------------------
    op = ALU_SUB; a = 32'd30; b = 32'd10; #1;
    check  ("SUB 30-10",  result, 32'd20);
    check_1("SUB zero=0", zero,   1'b0);
    check_1("SUB neg=0",  neg,    1'b0);

    // SUB resultado negativo
    op = ALU_SUB; a = 32'd5; b = 32'd10; #1;
    check  ("SUB 5-10",  result, 32'hFFFFFFFB);
    check_1("SUB neg=1", neg,    1'b1);

    // SUB resultado cero
    op = ALU_SUB; a = 32'd42; b = 32'd42; #1;
    check  ("SUB igual",  result, 32'h0);
    check_1("SUB zero=1", zero,   1'b1);

    // ----------------------------------------
    // AND
    // ----------------------------------------
    op = ALU_AND;
    a = 32'hFF00FF00; b = 32'h0F0F0F0F; #1;
    check("AND", result, 32'h0F000F00);

    // ----------------------------------------
    // OR
    // ----------------------------------------
    op = ALU_OR;
    a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; #1;
    check("OR", result, 32'hFFFFFFFF);

    // ----------------------------------------
    // XOR
    // ----------------------------------------
    op = ALU_XOR;
    a = 32'hFFFFFFFF; b = 32'h0F0F0F0F; #1;
    check("XOR", result, 32'hF0F0F0F0);

    // ----------------------------------------
    // SLL
    // ----------------------------------------
    op = ALU_SLL; a = 32'd1; b = 32'd8; #1;
    check("SLL 1<<8", result, 32'd256);

    op = ALU_SLL; a = 32'd1; b = 32'd31; #1;
    check("SLL 1<<31", result, 32'h80000000);

    // ----------------------------------------
    // SRL
    // ----------------------------------------
    op = ALU_SRL; a = 32'h80000000; b = 32'd1; #1;
    check("SRL lógico", result, 32'h40000000);

    op = ALU_SRL; a = 32'hFFFFFFFF; b = 32'd4; #1;
    check("SRL 0xFFFFFFFF>>4", result, 32'h0FFFFFFF);

    // ----------------------------------------
    // SRA
    // ----------------------------------------
    op = ALU_SRA; a = 32'h80000000; b = 32'd1; #1;
    check("SRA aritmético", result, 32'hC0000000);

    op = ALU_SRA; a = 32'hFFFFFFFF; b = 32'd4; #1;
    check("SRA -1>>>4", result, 32'hFFFFFFFF);

    // ----------------------------------------
    // SLT (signed)
    // ----------------------------------------
    op = ALU_SLT; a = 32'hFFFFFFFF; b = 32'd1; #1;
    check("SLT -1 < 1", result, 32'd1);

    op = ALU_SLT; a = 32'd10; b = 32'd5; #1;
    check("SLT 10 < 5", result, 32'd0);

    // ----------------------------------------
    // SLTU (unsigned)
    // ----------------------------------------
    op = ALU_SLTU; a = 32'hFFFFFFFF; b = 32'd1; #1;
    check("SLTU 0xFFFFFFFF < 1", result, 32'd0);

    op = ALU_SLTU; a = 32'd1; b = 32'hFFFFFFFF; #1;
    check("SLTU 1 < 0xFFFFFFFF", result, 32'd1);

    // ----------------------------------------
    // LUI: pasa B directamente
    // ----------------------------------------
    op = ALU_LUI; a = 32'hDEADBEEF; b = 32'hABCDE000; #1;
    check("LUI pasa B", result, 32'hABCDE000);

    // ----------------------------------------
    // Flags de branch via SUB
    // ----------------------------------------
    op = ALU_SUB; a = 32'd5; b = 32'd5; #1;
    check  ("BEQ: SUB igual", result, 32'h0);
    check_1("BEQ: zero=1",    zero,   1'b1);

    op = ALU_SUB; a = 32'd5; b = 32'd10; #1;
    check_1("BLT: neg=1",  neg,  1'b1);
    check_1("BLT: zero=0", zero, 1'b0);

    op = ALU_SUB; a = 32'd10; b = 32'd5; #1;
    check_1("BGE: neg=0",  neg,  1'b0);
    check_1("BGE: zero=0", zero, 1'b0);

    $display("---- Tests completados ----");
    $finish;
end

endmodule