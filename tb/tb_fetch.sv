import core_pkg::*;

module tb_fetch;

// ---- Señales ----
logic        clk, rst;
logic        branch_taken, stall;
logic [31:0] branch_target;
logic [31:0] pc, pc_plus4, instr;
logic [31:0] imem_addr;
logic [31:0] imem_data;

// ---- DUT ----
fetch dut (
    .clk_i          (clk),
    .rst_i          (rst),
    .branch_taken_i (branch_taken),
    .branch_target_i(branch_target),
    .stall_i        (stall),
    .pc_o           (pc),
    .pc_plus4_o     (pc_plus4),
    .instr_o        (instr),
    .imem_addr_o    (imem_addr),
    .imem_data_i    (imem_data)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tarea de verificación ----
task check_32;
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

// ---- Modelo simple de imem ----
// Devuelve una instrucción distinta según la dirección
always_comb begin
    case (imem_addr)
        32'h00: imem_data = 32'hAABBCCDD; // instr en 0x00
        32'h04: imem_data = 32'h11223344; // instr en 0x04
        32'h08: imem_data = 32'h55667788; // instr en 0x08
        32'h0C: imem_data = 32'hDEADBEEF; // instr en 0x0C
        32'h10: imem_data = 32'hCAFEBABE; // instr en 0x10
        default: imem_data = 32'h00000013; // NOP (ADDI x0, x0, 0)
    endcase
end

// ---- Tests ----
initial begin
    rst = 1; branch_taken = 0; stall = 0;
    branch_target = '0;
    @(posedge clk); #1;
    rst = 0;

    // ----------------------------------------
    // Secuencia normal: PC avanza de 4 en 4
    // ----------------------------------------
    #1;
    check_32("PC inicial",      pc,       32'h0);
    check_32("PC+4 inicial",    pc_plus4, 32'h4);
    check_32("Instr en 0x00",   instr,    32'hAABBCCDD);

    @(posedge clk); #1;
    check_32("PC tras clk1",    pc,       32'h4);
    check_32("PC+4 tras clk1",  pc_plus4, 32'h8);
    check_32("Instr en 0x04",   instr,    32'h11223344);

    @(posedge clk); #1;
    check_32("PC tras clk2",    pc,       32'h8);
    check_32("Instr en 0x08",   instr,    32'h55667788);

    // ----------------------------------------
    // Branch taken: PC salta a 0x10
    // ----------------------------------------
    @(posedge clk);
    branch_taken  = 1;
    branch_target = 32'h10;
    @(posedge clk); #1;
    branch_taken = 0;
    check_32("PC tras branch",   pc,    32'h10);
    check_32("Instr tras branch",instr, 32'hCAFEBABE);

    // ----------------------------------------
    // Continúa secuencial tras branch
    // ----------------------------------------
    @(posedge clk); #1;
    check_32("PC tras branch+1", pc, 32'h14);

    // ----------------------------------------
    // Stall: PC no avanza
    // ----------------------------------------
    @(posedge clk);
    stall = 1;
    @(posedge clk); #1;
    check_32("PC con stall clk1", pc, 32'h14);

    @(posedge clk); #1;
    check_32("PC con stall clk2", pc, 32'h14);

    // ----------------------------------------
    // Stall liberado: PC avanza
    // ----------------------------------------
    @(posedge clk); #1;
    stall = 0;
    @(posedge clk); #1;
    check_32("PC tras stall", pc, 32'h18);

    // ----------------------------------------
    // Reset vuelve a 0
    // ----------------------------------------
    @(posedge clk);
    rst = 1;
    @(posedge clk); #1;
    rst = 0;
    check_32("PC tras reset", pc, 32'h0);
    check_32("Instr tras reset", instr, 32'hAABBCCDD);

    $display("---- Tests completados ----");
    $finish;
end

endmodule