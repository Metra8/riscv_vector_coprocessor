package core_pkg;

parameter XLEN = 32;

// ---- Opcodes ----
typedef enum logic [6:0] {
    OP_LUI    = 7'b0110111,
    OP_AUIPC  = 7'b0010111,
    OP_JAL    = 7'b1101111,
    OP_JALR   = 7'b1100111,
    OP_BRANCH = 7'b1100011,
    OP_LOAD   = 7'b0000011,
    OP_STORE  = 7'b0100011,
    OP_IMM    = 7'b0010011,
    OP_REG    = 7'b0110011,
    OP_VECTOR = 7'b1010111  // despacho al VPU
} opcode_t;

// ---- Operaciones ALU ----
typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_AND  = 4'b0010,
    ALU_OR   = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_SLL  = 4'b0101,
    ALU_SRL  = 4'b0110,
    ALU_SRA  = 4'b0111,
    ALU_SLT  = 4'b1000,
    ALU_SLTU = 4'b1001,
    ALU_LUI  = 4'b1010   // pasa operando B directamente (para LUI)
} alu_op_t;

// ---- Fuente del operando B de la ALU ----
typedef enum logic [1:0] {
    SRC_REG = 2'b00,  // rs2
    SRC_IMM = 2'b01,  // inmediato
    SRC_PC  = 2'b10   // PC (para AUIPC)
} alu_src_t;

// ---- Fuente del dato a escribir en rd ----
typedef enum logic [1:0] {
    WB_ALU = 2'b00,  // resultado ALU
    WB_MEM = 2'b01,  // dato de memoria (load)
    WB_PC4 = 2'b10   // PC+4 (para JAL/JALR)
} wb_src_t;

// ---- Tipo de rama (branch) ----
typedef enum logic [2:0] {
    BR_NONE = 3'b000,  // no es salto
    BR_EQ   = 3'b001,  // BEQ
    BR_NE   = 3'b010,  // BNE
    BR_LT   = 3'b011,  // BLT
    BR_GE   = 3'b100,  // BGE
    BR_LTU  = 3'b101,  // BLTU
    BR_GEU  = 3'b110   // BGEU
} branch_t;

// ---- Ancho de acceso a memoria ----
typedef enum logic [1:0] {
    MEM_BYTE  = 2'b00,  // LB / SB
    MEM_HALF  = 2'b01,  // LH / SH
    MEM_WORD  = 2'b10   // LW / SW
} mem_width_t;

endpackage