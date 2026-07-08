import core_pkg::*;
import vpu_pkg::*;

module tb_system_basic;

logic clk, rst;

system_top dut (
    .clk_i (clk),
    .rst_i (rst)
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

    // ----------------------------------------
    // Cargar imem en time=0 con #1 para asegurar
    // que se ejecuta después del initial de imem.sv
    // ----------------------------------------
    #1;
    // addi x1, x0, 4
    dut.imem_inst.mem[0] = {12'd4,   5'd0, 3'b000, 5'd1, 7'b0010011};
    // addi x2, x0, 2
    dut.imem_inst.mem[1] = {12'd2,   5'd0, 3'b000, 5'd2, 7'b0010011};
    // vsetvli x0, x1, e32
    dut.imem_inst.mem[2] = {12'h010, 5'd1, 3'b111, 5'd0, 7'b1010111};
    // vadd.vv v3, v2, v1
    dut.imem_inst.mem[3] = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};
    // vsub.vv v4, v2, v1
    dut.imem_inst.mem[4] = {6'b000010, 1'b1, 5'd2, 5'd1, 3'b000, 5'd4, 7'b1010111};
    // vmul.vv v5, v2, v1
    dut.imem_inst.mem[5] = {6'b100101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd5, 7'b1010111};
    // addi x3, x0, 99
    dut.imem_inst.mem[6] = {12'd99,  5'd0, 3'b000, 5'd3, 7'b0010011};
    // addi x4, x0, 1
    dut.imem_inst.mem[7] = {12'd1,   5'd0, 3'b000, 5'd4, 7'b0010011};
    // NOPs
    for (int i = 8; i < 1024; i++)
        dut.imem_inst.mem[i] = 32'h00000013;

    // ----------------------------------------
    // Reset y arranque
    // ----------------------------------------
    @(posedge clk); #1;
    rst = 0;

    // ----------------------------------------
    // Cargar registros vectoriales DESPUÉS del reset
    // {MSB...LSB} → i32b[3]=MSB, i32b[0]=LSB
    // Queremos: i32b[0]=10, i32b[1]=20, i32b[2]=30, i32b[3]=40
    // ----------------------------------------
    dut.vpu.regfile.regs[1] = {32'd40, 32'd30, 32'd20, 32'd10};
    dut.vpu.regfile.regs[2] = {32'd4,  32'd3,  32'd2,  32'd1};

    // ----------------------------------------
    // Posedge 1: addi x1, x0, 4
    // ----------------------------------------
    @(posedge clk); #1;
    check_32("x1 = 4", dut.core.regfile_inst.regs[1], 32'd4);

    // ----------------------------------------
    // Posedge 2: addi x2, x0, 2
    // ----------------------------------------
    @(posedge clk); #1;
    check_32("x2 = 2", dut.core.regfile_inst.regs[2], 32'd2);

    // ----------------------------------------
    // Posedge 3: vsetvli → stall=1, done=1
    // ----------------------------------------
    @(posedge clk); #1;
    check_32("SEW = 2 (SEW32)", {30'b0, dut.vpu.csr.sew_o}, 32'd2);
    check_32("vl = 4",           dut.vpu.csr.vl_o,           32'd4);
    check_1 ("stall tras vsetvli", dut.core.stall, 1'b1);

    // ----------------------------------------
    // Posedge 4: stall→0 (done de vsetvli lo libera)
    // PC sigue en 0x0C, vadd aún no ejecuta
    // ----------------------------------------
    @(posedge clk); #1;
    check_1("stall liberado tras vsetvli", dut.core.stall, 1'b0);

    // ----------------------------------------
    // Posedge 5: vadd.vv ejecuta → stall=1, v3 escrito
    // v3[i] = v2[i] + v1[i]
    // i32b[0]=1+10=11, [1]=2+20=22, [2]=3+30=33, [3]=4+40=44
    // ----------------------------------------
    @(posedge clk); #1;
    check_1 ("stall tras vadd",  dut.core.stall,                  1'b1);
    check_32("v3[0] = 11",       dut.vpu.regfile.regs[3].i32b[0], 32'd11);
    check_32("v3[1] = 22",       dut.vpu.regfile.regs[3].i32b[1], 32'd22);
    check_32("v3[2] = 33",       dut.vpu.regfile.regs[3].i32b[2], 32'd33);
    check_32("v3[3] = 44",       dut.vpu.regfile.regs[3].i32b[3], 32'd44);

    // ----------------------------------------
    // Posedge 6: stall→0, PC sigue en 0x10
    // ----------------------------------------
    @(posedge clk); #1;
    check_1("stall liberado tras vadd", dut.core.stall, 1'b0);

    // ----------------------------------------
    // Posedge 7: vsub.vv ejecuta → stall=1, v4 escrito
    // v4[i] = v2[i] - v1[i]
    // i32b[0]=1-10=-9=0xFFFFFFF7, [3]=4-40=-36=0xFFFFFFDC
    // ----------------------------------------
    @(posedge clk); #1;
    check_1 ("stall tras vsub",  dut.core.stall,                  1'b1);
    check_32("v4[0] = -9",       dut.vpu.regfile.regs[4].i32b[0], 32'hFFFFFFF7);
    check_32("v4[3] = -36",      dut.vpu.regfile.regs[4].i32b[3], 32'hFFFFFFDC);

    // ----------------------------------------
    // Posedge 8: stall→0, PC sigue en 0x14
    // ----------------------------------------
    @(posedge clk); #1;
    check_1("stall liberado tras vsub", dut.core.stall, 1'b0);

    // ----------------------------------------
    // Posedge 9: vmul.vv ejecuta → stall=1, v5 escrito
    // v5[i] = v2[i] * v1[i]
    // i32b[0]=1*10=10, [1]=2*20=40, [2]=3*30=90, [3]=4*40=160
    // ----------------------------------------
    @(posedge clk); #1;
    check_1 ("stall tras vmul",  dut.core.stall,                  1'b1);
    check_32("v5[0] = 10",       dut.vpu.regfile.regs[5].i32b[0], 32'd10);
    check_32("v5[1] = 40",       dut.vpu.regfile.regs[5].i32b[1], 32'd40);
    check_32("v5[2] = 90",       dut.vpu.regfile.regs[5].i32b[2], 32'd90);
    check_32("v5[3] = 160",      dut.vpu.regfile.regs[5].i32b[3], 32'd160);

    // ----------------------------------------
    // Posedge 10: stall→0, PC sigue en 0x18
    // ----------------------------------------
    @(posedge clk); #1;
    check_1("stall liberado tras vmul", dut.core.stall, 1'b0);

    // ----------------------------------------
    // Posedge 11: addi x3, x0, 99
    // ----------------------------------------
    @(posedge clk); #1;
    check_32("x3 = 99 (escalar tras VPU)", dut.core.regfile_inst.regs[3], 32'd99);

    // ----------------------------------------
    // Posedge 12: addi x4, x0, 1
    // ----------------------------------------
    @(posedge clk); #1;
    check_32("x4 = 1 (escalar tras VPU)", dut.core.regfile_inst.regs[4], 32'd1);

    $display("---- Tests completados ----");
    $finish;
end

endmodule