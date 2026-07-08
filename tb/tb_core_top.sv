import core_pkg::*;

module tb_core_top;

// ---- Señales ----
logic        clk, rst;
logic [31:0] imem_addr, imem_data;
logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
logic        dmem_we;
logic [3:0]  dmem_be;
logic [31:0] vpu_instr, vpu_rs1;
logic        vpu_valid, vpu_done, vpu_illegal;

// ---- DUT ----
core_top dut (
    .clk_i          (clk),
    .rst_i          (rst),
    .imem_addr_o    (imem_addr),
    .imem_data_i    (imem_data),
    .dmem_addr_o    (dmem_addr),
    .dmem_wdata_o   (dmem_wdata),
    .dmem_we_o      (dmem_we),
    .dmem_be_o      (dmem_be),
    .dmem_rdata_i   (dmem_rdata),
    .vpu_instr_o    (vpu_instr),
    .vpu_rs1_o      (vpu_rs1),
    .vpu_valid_o    (vpu_valid),
    .vpu_done_i     (vpu_done),
    .vpu_illegal_i  (vpu_illegal)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Modelo de imem ----
logic [31:0] imem [32];

initial begin
    // addi x1, x0, 10
    imem[0]  = {12'd10,  5'd0, 3'b000, 5'd1,  7'b0010011};
    // addi x2, x0, 20
    imem[1]  = {12'd20,  5'd0, 3'b000, 5'd2,  7'b0010011};
    // add x3, x1, x2
    imem[2]  = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
    // sw x3, 0(x0)
    imem[3]  = {7'b0000000, 5'd3, 5'd0, 3'b010, 5'd0, 7'b0100011};
    // lw x4, 0(x0)
    imem[4]  = {12'd0, 5'd0, 3'b010, 5'd4, 7'b0000011};
    // beq x1, x1, +8 → de 0x14 a 0x1C
    // imm=8: imm[12]=0, imm[10:5]=000000, imm[4:1]=0100, imm[11]=0
    imem[5]  = {1'b0, 6'b000000, 5'd1, 5'd1, 3'b000, 4'b0100, 1'b0, 7'b1100011};
    // addi x5, x0, 99 (NO ejecutado, saltado por BEQ)
    imem[6]  = {12'd99, 5'd0, 3'b000, 5'd5, 7'b0010011};
    // addi x6, x0, 42
    imem[7]  = {12'd42, 5'd0, 3'b000, 5'd6, 7'b0010011};
    // jal x7, +8 → de 0x20 a 0x28, x7=0x24
    imem[8]  = {1'b0, 10'b0000000100, 1'b0, 8'b0, 5'd7, 7'b1101111};
    // addi x8, x0, 77 (NO ejecutado, saltado por JAL)
    imem[9]  = {12'd77, 5'd0, 3'b000, 5'd8, 7'b0010011};
    // addi x9, x0, 55
    imem[10] = {12'd55, 5'd0, 3'b000, 5'd9, 7'b0010011};
    // vadd.vv v3, v2, v1
    imem[11] = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};
    // addi x10, x0, 1
    imem[12] = {12'd1, 5'd0, 3'b000, 5'd10, 7'b0010011};
    for (int i = 13; i < 32; i++)
        imem[i] = {12'd0, 5'd0, 3'b000, 5'd0, 7'b0010011}; // NOP
end

assign imem_data = imem[imem_addr[6:2]];

// ---- Modelo de dmem ----
logic [31:0] dmem_mem [16];

initial begin
    for (int i = 0; i < 16; i++)
        dmem_mem[i] = '0;
end

assign dmem_rdata = dmem_mem[dmem_addr[5:2]];

always_ff @(posedge clk) begin
    if (dmem_we) begin
        if (dmem_be[0]) dmem_mem[dmem_addr[5:2]][7:0]   <= dmem_wdata[7:0];
        if (dmem_be[1]) dmem_mem[dmem_addr[5:2]][15:8]  <= dmem_wdata[15:8];
        if (dmem_be[2]) dmem_mem[dmem_addr[5:2]][23:16] <= dmem_wdata[23:16];
        if (dmem_be[3]) dmem_mem[dmem_addr[5:2]][31:24] <= dmem_wdata[31:24];
    end
end

// ---- Modelo de VPU (3 ciclos) ----
logic [2:0] vpu_counter;

initial begin
    vpu_done    = 0;
    vpu_illegal = 0;
    vpu_counter = 0;
end

always_ff @(posedge clk) begin
    if (vpu_valid) begin
        vpu_counter <= 3'd3;
        vpu_done    <= 0;
    end
    else if (vpu_counter > 0) begin
        vpu_counter <= vpu_counter - 1;
        if (vpu_counter == 3'd1)
            vpu_done <= 1;
        else
            vpu_done <= 0;
    end
    else
        vpu_done <= 0;
end

// ---- Latch para capturar vpu_valid ----
// vpu_valid es combinacional y cae al siguiente ciclo (stall=1)
// este latch lo captura para poder verificarlo después del posedge
logic vpu_launched;
always_ff @(posedge clk or posedge rst) begin
    if (rst)            vpu_launched <= 0;
    else if (vpu_valid) vpu_launched <= 1;
end

// ---- Tareas de verificación ----
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

// ---- Tests ----
// Nota de timing: después de cada @(posedge clk); #1;
// - Los registros muestran lo que se escribió en ESE ciclo
// - imem_addr muestra el PC de la SIGUIENTE instrucción a ejecutar
initial begin
    rst = 1; vpu_done = 0; vpu_illegal = 0;
    @(posedge clk); #1;
    rst = 0;

    // Round 1: ADDI x1 ejecutado (PC=0x00→0x04)
    @(posedge clk); #1;
    check_32("x1 = 10",           dut.regfile_inst.regs[1], 32'd10);
    check_32("PC siguiente = 0x04", imem_addr,               32'h4);

    // Round 2: ADDI x2 ejecutado (PC=0x04→0x08)
    @(posedge clk); #1;
    check_32("x2 = 20", dut.regfile_inst.regs[2], 32'd20);

    // Round 3: ADD x3 ejecutado (PC=0x08→0x0C)
    @(posedge clk); #1;
    check_32("x3 = 30", dut.regfile_inst.regs[3], 32'd30);

    // Round 4: SW ejecutado (PC=0x0C→0x10)
    @(posedge clk); #1;
    check_32("dmem[0] = 30", dmem_mem[0], 32'd30);

    // Round 5: LW ejecutado (PC=0x10→0x14)
    @(posedge clk); #1;
    check_32("x4 = 30 (LW)", dut.regfile_inst.regs[4], 32'd30);

    // Round 6: BEQ ejecutado (PC=0x14→0x1C, branch taken)
    @(posedge clk); #1;
    check_32("PC tras BEQ = 0x1C",    imem_addr,                     32'h1C);
    check_32("x5 = 0 (no ejecutado)", dut.regfile_inst.regs[5],      32'd0);

    // Round 7: ADDI x6 ejecutado (PC=0x1C→0x20)
    @(posedge clk); #1;
    check_32("x6 = 42",           dut.regfile_inst.regs[6], 32'd42);
    check_32("PC siguiente = 0x20", imem_addr,               32'h20);

    // Round 8: JAL ejecutado (PC=0x20→0x28, x7=PC+4=0x24)
    @(posedge clk); #1;
    check_32("x7 = 0x24 (retorno JAL)", dut.regfile_inst.regs[7], 32'h24);
    check_32("PC tras JAL = 0x28",      imem_addr,                 32'h28);
    check_32("x8 = 0 (no ejecutado)",   dut.regfile_inst.regs[8], 32'd0);

    // Round 9: ADDI x9 ejecutado (PC=0x28→0x2C)
    @(posedge clk); #1;
    check_32("x9 = 55", dut.regfile_inst.regs[9], 32'd55);

    // Round 10: VADD.VV en PC=0x2C
    // vpu_valid=1 justo antes del posedge → capturado por vpu_launched
    // tras posedge: stall=1, PC avanza a 0x30 (ADDI x10)
    @(posedge clk); #1;
    check_1 ("vpu_launched",        vpu_launched, 1'b1);
    check_1 ("stall activo",        dut.stall,    1'b1);
    check_32("PC congelado = 0x30", imem_addr,    32'h30);

    // Round 11: stall, VPU contando (counter 3→2)
    @(posedge clk); #1;
    check_1("stall sigue activo", dut.stall, 1'b1);
    check_1("vpu_done = 0",       vpu_done,  1'b0);

    // Round 12: stall, VPU contando (counter 2→1)
    @(posedge clk); #1;
    check_1("stall sigue activo 2", dut.stall, 1'b1);
    check_1("vpu_done = 0 (2)",     vpu_done,  1'b0);

    // Round 13: VPU termina (counter 1→0, vpu_done→1)
    @(posedge clk); #1;
    check_1("vpu_done = 1", vpu_done, 1'b1);
    check_1("stall aun activo (ve done del ciclo anterior)", dut.stall, 1'b1);

    // Round 14: stall liberado (ve vpu_done=1)
    @(posedge clk); #1;
    check_1("stall liberado", dut.stall, 1'b0);

    // Round 15: ADDI x10 ejecutado (PC=0x30→0x34)
    @(posedge clk); #1;
    check_32("x10 = 1 (tras VPU)", dut.regfile_inst.regs[10], 32'd1);

    $display("---- Tests completados ----");
    $finish;
end

endmodule