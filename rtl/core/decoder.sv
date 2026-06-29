import core_pkg::*;

module decoder (
    input  logic [31:0] instr_i,

    // Control ALU
    output alu_op_t     alu_op_o,
    output alu_src_t    alu_src_o,

    // Control regfile
    output logic        rd_we_o,
    output wb_src_t     wb_src_o,

    // Control LSU
    output logic        mem_we_o,
    output mem_width_t  mem_width_o,
    output logic        mem_sign_o,   // 1 = signed, 0 = unsigned

    // Control saltos
    output branch_t     branch_o,
    output logic        jump_o,       // JAL/JALR

    // Inmediato extendido a 32 bits
    output logic [31:0] imm_o,

    // Direcciones de registros
    output logic [4:0]  rs1_addr_o,
    output logic [4:0]  rs2_addr_o,
    output logic [4:0]  rd_addr_o,

    // VPU
    output logic        vpu_en_o,

    // Control
    output logic        illegal_o
);

// ---- Extracción de campos ----
logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode     = instr_i[6:0];
assign funct3     = instr_i[14:12];
assign funct7     = instr_i[31:25];
assign rs1_addr_o = instr_i[19:15];
assign rs2_addr_o = instr_i[24:20];
assign rd_addr_o  = instr_i[11:7];

// ---- Generación de inmediatos ----
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

// Tipo I
assign imm_i = {{20{instr_i[31]}}, instr_i[31:20]};
// Tipo S
assign imm_s = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
// Tipo B
assign imm_b = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                instr_i[30:25], instr_i[11:8], 1'b0};
// Tipo U
assign imm_u = {instr_i[31:12], 12'b0};
// Tipo J
assign imm_j = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                instr_i[20], instr_i[30:21], 1'b0};

// ---- Decodificación ----
always_comb begin
    // Valores por defecto
    alu_op_o    = ALU_ADD;
    alu_src_o   = SRC_REG;
    rd_we_o     = 0;
    wb_src_o    = WB_ALU;
    mem_we_o    = 0;
    mem_width_o = MEM_WORD;
    mem_sign_o  = 1;
    branch_o    = BR_NONE;
    jump_o      = 0;
    imm_o       = '0;
    vpu_en_o    = 0;
    illegal_o   = 0;

    case (opcode_t'(opcode))

        // ---- LUI ----
        OP_LUI: begin
            alu_op_o  = ALU_LUI;
            alu_src_o = SRC_IMM;
            rd_we_o   = 1;
            wb_src_o  = WB_ALU;
            imm_o     = imm_u;
        end

        // ---- AUIPC ----
        OP_AUIPC: begin
            alu_op_o  = ALU_ADD;
            alu_src_o = SRC_PC;
            rd_we_o   = 1;
            wb_src_o  = WB_ALU;
            imm_o     = imm_u;
        end

        // ---- JAL ----
        OP_JAL: begin
            alu_op_o  = ALU_ADD;
            alu_src_o = SRC_PC;
            rd_we_o   = 1;
            wb_src_o  = WB_PC4;
            jump_o    = 1;
            imm_o     = imm_j;
        end

        // ---- JALR ----
        OP_JALR: begin
            alu_op_o  = ALU_ADD;
            alu_src_o = SRC_IMM;
            rd_we_o   = 1;
            wb_src_o  = WB_PC4;
            jump_o    = 1;
            imm_o     = imm_i;
        end

        // ---- BRANCH ----
        OP_BRANCH: begin
            alu_op_o  = ALU_SUB;
            alu_src_o = SRC_REG;
            rd_we_o   = 0;
            imm_o     = imm_b;
            case (funct3)
                3'b000: branch_o = BR_EQ;
                3'b001: branch_o = BR_NE;
                3'b100: branch_o = BR_LT;
                3'b101: branch_o = BR_GE;
                3'b110: branch_o = BR_LTU;
                3'b111: branch_o = BR_GEU;
                default: illegal_o = 1;
            endcase
        end

        // ---- LOAD ----
        OP_LOAD: begin
            alu_op_o  = ALU_ADD;
            alu_src_o = SRC_IMM;
            rd_we_o   = 1;
            wb_src_o  = WB_MEM;
            imm_o     = imm_i;
            case (funct3)
                3'b000: begin mem_width_o = MEM_BYTE; mem_sign_o = 1; end // LB
                3'b001: begin mem_width_o = MEM_HALF; mem_sign_o = 1; end // LH
                3'b010: begin mem_width_o = MEM_WORD; mem_sign_o = 1; end // LW
                3'b100: begin mem_width_o = MEM_BYTE; mem_sign_o = 0; end // LBU
                3'b101: begin mem_width_o = MEM_HALF; mem_sign_o = 0; end // LHU
                default: illegal_o = 1;
            endcase
        end

        // ---- STORE ----
        OP_STORE: begin
            alu_op_o  = ALU_ADD;
            alu_src_o = SRC_IMM;
            rd_we_o   = 0;
            mem_we_o  = 1;
            imm_o     = imm_s;
            case (funct3)
                3'b000: mem_width_o = MEM_BYTE; // SB
                3'b001: mem_width_o = MEM_HALF; // SH
                3'b010: mem_width_o = MEM_WORD; // SW
                default: illegal_o = 1;
            endcase
        end

        // ---- OP-IMM (instrucciones I con inmediato) ----
        OP_IMM: begin
            alu_src_o = SRC_IMM;
            rd_we_o   = 1;
            wb_src_o  = WB_ALU;
            imm_o     = imm_i;
            case (funct3)
                3'b000: alu_op_o = ALU_ADD;  // ADDI
                3'b010: alu_op_o = ALU_SLT;  // SLTI
                3'b011: alu_op_o = ALU_SLTU; // SLTIU
                3'b100: alu_op_o = ALU_XOR;  // XORI
                3'b110: alu_op_o = ALU_OR;   // ORI
                3'b111: alu_op_o = ALU_AND;  // ANDI
                3'b001: begin                 // SLLI
                    alu_op_o = ALU_SLL;
                    imm_o    = {27'b0, instr_i[24:20]};
                end
                3'b101: begin                 // SRLI / SRAI
                    imm_o = {27'b0, instr_i[24:20]};
                    if (funct7[5]) alu_op_o = ALU_SRA;
                    else           alu_op_o = ALU_SRL;
                end
                default: illegal_o = 1;
            endcase
        end

        // ---- OP (instrucciones R) ----
        OP_REG: begin
            alu_src_o = SRC_REG;
            rd_we_o   = 1;
            wb_src_o  = WB_ALU;
            case ({funct7[5], funct3})
                4'b0000: alu_op_o = ALU_ADD;  // ADD
                4'b1000: alu_op_o = ALU_SUB;  // SUB
                4'b0001: alu_op_o = ALU_SLL;  // SLL
                4'b0010: alu_op_o = ALU_SLT;  // SLT
                4'b0011: alu_op_o = ALU_SLTU; // SLTU
                4'b0100: alu_op_o = ALU_XOR;  // XOR
                4'b0101: alu_op_o = ALU_SRL;  // SRL
                4'b1101: alu_op_o = ALU_SRA;  // SRA
                4'b0110: alu_op_o = ALU_OR;   // OR
                4'b0111: alu_op_o = ALU_AND;  // AND
                default: illegal_o = 1;
            endcase
        end

        // ---- VECTOR: despacho al VPU ----
        OP_VECTOR: begin
            vpu_en_o = 1;
            rd_we_o  = 0;
        end

        default: illegal_o = 1;

    endcase
end

endmodule