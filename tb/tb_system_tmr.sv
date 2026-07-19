// tb_system_tmr.sv
import core_pkg::*;
import vpu_pkg::*;

module tb_system_tmr;

logic clk, rst;
logic tmr_error;

system_top #(.TMR_ENABLE(1)) dut (
    .clk_i       (clk),
    .rst_i       (rst),
    .tmr_error_o (tmr_error)
);

initial clk = 0;
always #5 clk = ~clk;

task check_32;
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

initial begin
    rst = 1;
    #1;

    // ---- Cargar programa completo antes del reset ----
    dut.imem_inst.mem[0] = {12'd4,   5'd0, 3'b000, 5'd1, 7'b0010011}; // addi x1,x0,4
    dut.imem_inst.mem[1] = {12'd2,   5'd0, 3'b000, 5'd2, 7'b0010011}; // addi x2,x0,2
    dut.imem_inst.mem[2] = {12'h010, 5'd1, 3'b111, 5'd0, 7'b1010111}; // vsetvli e32
    dut.imem_inst.mem[3] = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111}; // vadd v3
    dut.imem_inst.mem[4] = {6'b000010, 1'b1, 5'd2, 5'd1, 3'b000, 5'd4, 7'b1010111}; // vsub v4
    dut.imem_inst.mem[5] = {6'b100101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd5, 7'b1010111}; // vmul v5
    dut.imem_inst.mem[6] = {12'd99,  5'd0, 3'b000, 5'd3, 7'b0010011}; // addi x3,x0,99
    dut.imem_inst.mem[7] = {12'd1,   5'd0, 3'b000, 5'd4, 7'b0010011}; // addi x4,x0,1
    dut.imem_inst.mem[8] = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd6, 7'b1010111}; // vadd v6
    dut.imem_inst.mem[9] = {6'b000010, 1'b1, 5'd2, 5'd1, 3'b000, 5'd7, 7'b1010111}; // vsub v7
    for (int i = 10; i < 1024; i++)
        dut.imem_inst.mem[i] = 32'h00000013;

    @(posedge clk); #1;
    rst = 0;

    // ---- Cargar registros vectoriales ----
    dut.vpu.regfile.regs[1] = {32'd40, 32'd30, 32'd20, 32'd10};
    dut.vpu.regfile.regs[2] = {32'd4,  32'd3,  32'd2,  32'd1};

    // ========================================
    // PARTE 1: Operación normal con TMR
    // ========================================
    $display("---- PARTE 1: Operación normal con TMR ----");

    @(posedge clk); #1;
    check_32("x1 = 4", dut.core.regfile_inst.regs[1], 32'd4);

    @(posedge clk); #1;
    check_32("x2 = 2", dut.core.regfile_inst.regs[2], 32'd2);

    @(posedge clk); #1;
    check_32("SEW = 2 (SEW32)", {30'b0, dut.vpu.csr.sew_o}, 32'd2);
    check_32("vl = 4",           dut.vpu.csr.vl_o,           32'd4);
    check_1 ("stall tras vsetvli",  dut.core.stall, 1'b1);
    check_1 ("tmr_error=0 vsetvli", tmr_error,      1'b0);

    @(posedge clk); #1;
    check_1("stall liberado tras vsetvli", dut.core.stall, 1'b0);

    @(posedge clk); #1;
    check_1 ("stall tras vadd",  dut.core.stall,                  1'b1);
    check_1 ("tmr_error=0 vadd", tmr_error,                       1'b0);
    check_32("v3[0] = 11",       dut.vpu.regfile.regs[3].i32b[0], 32'd11);
    check_32("v3[1] = 22",       dut.vpu.regfile.regs[3].i32b[1], 32'd22);
    check_32("v3[2] = 33",       dut.vpu.regfile.regs[3].i32b[2], 32'd33);
    check_32("v3[3] = 44",       dut.vpu.regfile.regs[3].i32b[3], 32'd44);

    @(posedge clk); #1;
    check_1("stall liberado tras vadd", dut.core.stall, 1'b0);

    @(posedge clk); #1;
    check_1 ("stall tras vsub",  dut.core.stall,                  1'b1);
    check_1 ("tmr_error=0 vsub", tmr_error,                       1'b0);
    check_32("v4[0] = -9",       dut.vpu.regfile.regs[4].i32b[0], 32'hFFFFFFF7);
    check_32("v4[3] = -36",      dut.vpu.regfile.regs[4].i32b[3], 32'hFFFFFFDC);

    @(posedge clk); #1;
    check_1("stall liberado tras vsub", dut.core.stall, 1'b0);

    @(posedge clk); #1;
    check_1 ("stall tras vmul",  dut.core.stall,                  1'b1);
    check_1 ("tmr_error=0 vmul", tmr_error,                       1'b0);
    check_32("v5[0] = 10",       dut.vpu.regfile.regs[5].i32b[0], 32'd10);
    check_32("v5[1] = 40",       dut.vpu.regfile.regs[5].i32b[1], 32'd40);
    check_32("v5[2] = 90",       dut.vpu.regfile.regs[5].i32b[2], 32'd90);
    check_32("v5[3] = 160",      dut.vpu.regfile.regs[5].i32b[3], 32'd160);

    @(posedge clk); #1;
    check_1("stall liberado tras vmul", dut.core.stall, 1'b0);

    @(posedge clk); #1;
    check_32("x3 = 99 (escalar tras VPU)", dut.core.regfile_inst.regs[3], 32'd99);

    @(posedge clk); #1;
    check_32("x4 = 1 (escalar tras VPU)", dut.core.regfile_inst.regs[4], 32'd1);

    // ========================================
    // PARTE 2: Inyección de fallos
    // ========================================
    $display("---- PARTE 2: Inyección de fallos ----");

    // ---- TEST A: Fallo en carril B durante vadd v6 ----
    $display("---- TEST A: Fallo en carril B ----");
    force dut.vpu.tmr_block.rd_data_b = 128'hDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
    @(posedge clk); #1; // vadd v6 ejecuta con fallo en B
    check_1("Fallo B: tmr_error detectado", tmr_error,      1'b1);
    check_1("Fallo B: stall activo",        dut.core.stall, 1'b1);
    release dut.vpu.tmr_block.rd_data_b;
    @(posedge clk); #1; // stall liberado
    @(posedge clk); #1; // ciclo extra para que vsub v7 estabilice
    check_1 ("Fallo B: tmr_error=0 tras liberar",  tmr_error,                        1'b0);
    check_32("Fallo B: v6[0]=11 correcto",          dut.vpu.regfile.regs[6].i32b[0], 32'd11);
    check_32("Fallo B: v6[3]=44 correcto",          dut.vpu.regfile.regs[6].i32b[3], 32'd44);

    // ---- TEST B: Fallo en carril C durante vsub v7 ----
    $display("---- TEST B: Fallo en carril C ----");
    @(posedge clk); #1;
    force dut.vpu.tmr_block.rd_data_c = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    @(posedge clk); #1;
    check_1("Fallo C: tmr_error detectado", tmr_error, 1'b1);
    release dut.vpu.tmr_block.rd_data_c;
    @(posedge clk); #1;
    @(posedge clk); #1;
    check_32("Fallo C: v7[0]=-9 correcto",
             dut.vpu.regfile.regs[7].i32b[0], 32'hFFFFFFF7);

    $display("---- Tests completados ----");
    $finish;
end

endmodule