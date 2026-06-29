import core_pkg::*;

module tb_core_decoder;

// ---- Señales ----
logic        clk;
logic [31:0] instr;
alu_op_t     alu_op;
alu_src_t    alu_src;
logic        rd_we;
wb_src_t     wb_src;
logic        mem_we;
mem_width_t  mem_width;
logic        mem_sign;
branch_t     branch;
logic        jump;
logic [31:0] imm;
logic [4:0]  rs1_addr, rs2_addr, rd_addr;
logic        vpu_en;
logic        illegal;

// ---- DUT ----
decoder dut (
    .instr_i      (instr),
    .alu_op_o     (alu_op),
    .alu_src_o    (alu_src),
    .rd_we_o      (rd_we),
    .wb_src_o     (wb_src),
    .mem_we_o     (mem_we),
    .mem_width_o  (mem_width),
    .mem_sign_o   (mem_sign),
    .branch_o     (branch),
    .jump_o       (jump),
    .imm_o        (imm),
    .rs1_addr_o   (rs1_addr),
    .rs2_addr_o   (rs2_addr),
    .rd_addr_o    (rd_addr),
    .vpu_en_o     (vpu_en),
    .illegal_o    (illegal)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Tareas de verificación ----
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

task check_alu;
    input string  test_name;
    input alu_op_t got;
    input alu_op_t expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %0d | expected: %0d",
                      test_name, got, expected);
    end
endtask

task check_branch;
    input string   test_name;
    input branch_t got;
    input branch_t expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %0d | expected: %0d",
                      test_name, got, expected);
    end
endtask

// ---- Tests ----
initial begin

    // ----------------------------------------
    // ADD x3, x1, x2
    // funct7=0, rs2=x2, rs1=x1, funct3=000, rd=x3, opcode=OP_REG
    // ----------------------------------------
    instr = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011}; #1;
    check_alu("ADD alu_op",   alu_op,  ALU_ADD);
    check_1  ("ADD rd_we",    rd_we,   1'b1);
    check_1  ("ADD mem_we",   mem_we,  1'b0);
    check_1  ("ADD illegal",  illegal, 1'b0);
    check_1  ("ADD vpu_en",   vpu_en,  1'b0);

    // ----------------------------------------
    // SUB x3, x1, x2
    // funct7=0100000
    // ----------------------------------------
    instr = {7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011}; #1;
    check_alu("SUB alu_op",  alu_op,  ALU_SUB);
    check_1  ("SUB rd_we",   rd_we,   1'b1);
    check_1  ("SUB illegal", illegal, 1'b0);

    // ----------------------------------------
    // ADDI x1, x2, 100
    // imm=100, rs1=x2, funct3=000, rd=x1, opcode=OP_IMM
    // ----------------------------------------
    instr = {12'd100, 5'd2, 3'b000, 5'd1, 7'b0010011}; #1;
    check_alu("ADDI alu_op",  alu_op,  ALU_ADD);
    check_1  ("ADDI rd_we",   rd_we,   1'b1);
    check_32 ("ADDI imm",     imm,     32'd100);
    check_1  ("ADDI illegal", illegal, 1'b0);

    // ADDI con inmediato negativo
    instr = {12'hFFF, 5'd2, 3'b000, 5'd1, 7'b0010011}; #1;
    check_32("ADDI imm negativo", imm, 32'hFFFFFFFF);

    // ----------------------------------------
    // SLTI x1, x2, 50
    // ----------------------------------------
    instr = {12'd50, 5'd2, 3'b010, 5'd1, 7'b0010011}; #1;
    check_alu("SLTI alu_op", alu_op, ALU_SLT);
    check_32 ("SLTI imm",    imm,    32'd50);

    // ----------------------------------------
    // ANDI x1, x2, 0xFF
    // ----------------------------------------
    instr = {12'hFF, 5'd2, 3'b111, 5'd1, 7'b0010011}; #1;
    check_alu("ANDI alu_op", alu_op, ALU_AND);
    check_32 ("ANDI imm",    imm,    32'hFF);

    // ----------------------------------------
    // SLLI x1, x2, 4
    // ----------------------------------------
    instr = {7'b0000000, 5'd4, 5'd2, 3'b001, 5'd1, 7'b0010011}; #1;
    check_alu("SLLI alu_op", alu_op, ALU_SLL);
    check_32 ("SLLI imm",    imm,    32'd4);

    // ----------------------------------------
    // SRLI x1, x2, 4
    // ----------------------------------------
    instr = {7'b0000000, 5'd4, 5'd2, 3'b101, 5'd1, 7'b0010011}; #1;
    check_alu("SRLI alu_op", alu_op, ALU_SRL);
    check_32 ("SRLI imm",    imm,    32'd4);

    // ----------------------------------------
    // SRAI x1, x2, 4
    // funct7[5]=1
    // ----------------------------------------
    instr = {7'b0100000, 5'd4, 5'd2, 3'b101, 5'd1, 7'b0010011}; #1;
    check_alu("SRAI alu_op", alu_op, ALU_SRA);
    check_32 ("SRAI imm",    imm,    32'd4);

    // ----------------------------------------
    // LUI x1, 0xABCDE
    // ----------------------------------------
    instr = {20'hABCDE, 5'd1, 7'b0110111}; #1;
    check_alu("LUI alu_op", alu_op, ALU_LUI);
    check_1  ("LUI rd_we",  rd_we,  1'b1);
    check_32 ("LUI imm",    imm,    32'hABCDE000);
    check_1  ("LUI illegal",illegal, 1'b0);

    // ----------------------------------------
    // AUIPC x1, 0x1000
    // ----------------------------------------
    instr = {20'h1000, 5'd1, 7'b0010111}; #1;
    check_alu("AUIPC alu_op",  alu_op,  ALU_ADD);
    check_1  ("AUIPC rd_we",   rd_we,   1'b1);
    check_32 ("AUIPC imm",     imm,     32'h1000000);
    check_1  ("AUIPC illegal", illegal, 1'b0);

    // ----------------------------------------
    // JAL x1, offset=8
    // ----------------------------------------
    // imm_j con offset=8: bit20=0, bits10:1=0b0000000100, bit11=0, bits19:12=0
    instr = {1'b0, 10'b0000000100, 1'b0, 8'b0, 5'd1, 7'b1101111}; #1;
    check_1  ("JAL jump",    jump,   1'b1);
    check_1  ("JAL rd_we",   rd_we,  1'b1);
    check_1  ("JAL illegal", illegal,1'b0);
    check_32 ("JAL imm",     imm,    32'd8);

    // ----------------------------------------
    // JALR x1, x2, 4
    // ----------------------------------------
    instr = {12'd4, 5'd2, 3'b000, 5'd1, 7'b1100111}; #1;
    check_1  ("JALR jump",    jump,    1'b1);
    check_1  ("JALR rd_we",   rd_we,   1'b1);
    check_32 ("JALR imm",     imm,     32'd4);
    check_1  ("JALR illegal", illegal, 1'b0);

    // ----------------------------------------
    // BEQ x1, x2, offset=16
    // ----------------------------------------
    // imm_b con offset=16: bit12=0, bits10:5=0, bit4:1=1000, bit11=0
    instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b1000, 1'b0, 7'b1100011}; #1;
    check_branch("BEQ branch",   branch,  BR_EQ);
    check_1     ("BEQ rd_we",    rd_we,   1'b0);
    check_1     ("BEQ mem_we",   mem_we,  1'b0);
    check_32    ("BEQ imm",      imm,     32'd16);
    check_1     ("BEQ illegal",  illegal, 1'b0);

    // ----------------------------------------
    // BNE x1, x2
    // ----------------------------------------
    instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b001, 4'b0000, 1'b0, 7'b1100011}; #1;
    check_branch("BNE branch", branch, BR_NE);

    // ----------------------------------------
    // BLT x1, x2
    // ----------------------------------------
    instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b100, 4'b0000, 1'b0, 7'b1100011}; #1;
    check_branch("BLT branch", branch, BR_LT);

    // ----------------------------------------
    // BGE x1, x2
    // ----------------------------------------
    instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b101, 4'b0000, 1'b0, 7'b1100011}; #1;
    check_branch("BGE branch", branch, BR_GE);

    // ----------------------------------------
    // LW x1, 8(x2)
    // ----------------------------------------
    instr = {12'd8, 5'd2, 3'b010, 5'd1, 7'b0000011}; #1;
    check_alu("LW alu_op",    alu_op,    ALU_ADD);
    check_1  ("LW rd_we",     rd_we,     1'b1);
    check_1  ("LW mem_we",    mem_we,    1'b0);
    check_32 ("LW imm",       imm,       32'd8);
    check_1  ("LW illegal",   illegal,   1'b0);

    // ----------------------------------------
    // LB x1, 4(x2) signed
    // ----------------------------------------
    instr = {12'd4, 5'd2, 3'b000, 5'd1, 7'b0000011}; #1;
    check_1("LB mem_sign", mem_sign, 1'b1);

    // ----------------------------------------
    // LBU x1, 4(x2) unsigned
    // ----------------------------------------
    instr = {12'd4, 5'd2, 3'b100, 5'd1, 7'b0000011}; #1;
    check_1("LBU mem_sign", mem_sign, 1'b0);

    // ----------------------------------------
    // SW x2, 12(x1)
    // imm_s: imm[11:5]=0, imm[4:0]=12
    // ----------------------------------------
    instr = {7'b0000000, 5'd2, 5'd1, 3'b010, 5'd01100, 7'b0100011}; #1;
    check_alu("SW alu_op",  alu_op,  ALU_ADD);
    check_1  ("SW mem_we",  mem_we,  1'b1);
    check_1  ("SW rd_we",   rd_we,   1'b0);
    check_32 ("SW imm",     imm,     32'd12);
    check_1  ("SW illegal", illegal, 1'b0);

    // ----------------------------------------
    // Instrucción vectorial → vpu_en
    // ----------------------------------------
    instr = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111}; #1;
    check_1("VECTOR vpu_en",  vpu_en,  1'b1);
    check_1("VECTOR rd_we",   rd_we,   1'b0);
    check_1("VECTOR illegal", illegal, 1'b0);

    // ----------------------------------------
    // Instrucción ilegal
    // ----------------------------------------
    instr = 32'hFFFFFFFF; #1;
    check_1("Ilegal illegal", illegal, 1'b1);
    check_1("Ilegal rd_we",   rd_we,   1'b0);
    check_1("Ilegal vpu_en",  vpu_en,  1'b0);

    $display("---- Tests completados ----");
    $finish;
end

endmodule