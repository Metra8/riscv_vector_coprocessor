// core/core_top.sv
import core_pkg::*;

module core_top (
    input  logic        clk_i,
    input  logic        rst_i,

    // Interfaz con imem
    output logic [31:0] imem_addr_o,
    input  logic [31:0] imem_data_i,

    // Interfaz con dmem
    output logic [31:0] dmem_addr_o,
    output logic [31:0] dmem_wdata_o,
    output logic        dmem_we_o,
    output logic [3:0]  dmem_be_o,
    input  logic [31:0] dmem_rdata_i,

    // Interfaz con VPU
    output logic [31:0] vpu_instr_o,
    output logic [31:0] vpu_rs1_o,
    output logic        vpu_valid_o,
    input  logic        vpu_done_i,
    input  logic        vpu_illegal_i
);

// ---- Señales internas ----

// Fetch
logic [31:0] pc, pc_plus4, instr;

// Decoder
alu_op_t     alu_op;
alu_src_t    alu_src;
logic        rd_we;
wb_src_t     wb_src;
logic        mem_we;
mem_width_t  mem_width;
logic        mem_sign;
branch_t     branch;
logic        jump;
logic        jalr;
logic [31:0] jalr_target;
logic [31:0] imm;
logic [4:0]  rs1_addr, rs2_addr, rd_addr;
logic        vpu_en;
logic        illegal;

// Regfile
logic [31:0] rs1_data, rs2_data;
logic [31:0] rd_data;
logic        reg_we;

// ALU
logic [31:0] alu_a, alu_b, alu_result;
logic        alu_zero, alu_neg, alu_carry;

// LSU
logic [31:0] mem_rdata;

// Branch/Jump control
logic        branch_taken;
logic [31:0] branch_target;

// Stall
logic        stall;

// ---- Lógica de stall ----
always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
        stall <= 0;
    else if (vpu_en && !stall)
        stall <= 1;
    else if (vpu_done_i)
        stall <= 0;
end

// ---- Control de branch/jump ----
always_comb begin
    branch_taken = 0;
    jalr_target   = rs1_data + imm;

    // Cálculo del destino del salto
    if (jalr)
        branch_target = {jalr_target[31:1], 1'b0}; // JALR: rs1+imm
    else
        branch_target = pc + imm; // JAL y branches: PC+imm

    // Condición de branch
    case (branch)
        BR_EQ:  branch_taken = alu_zero;
        BR_NE:  branch_taken = ~alu_zero;
        BR_LT:  branch_taken = alu_neg;
        BR_GE:  branch_taken = ~alu_neg;
        BR_LTU: branch_taken = alu_carry;
        BR_GEU: branch_taken = ~alu_carry;
        default: branch_taken = 0;
    endcase
end

// ---- Operando A de la ALU ----
assign alu_a = (alu_src == SRC_PC) ? pc : rs1_data;

// ---- Operando B de la ALU ----
always_comb begin
    case (alu_src)
        SRC_REG: alu_b = rs2_data;
        SRC_IMM: alu_b = imm;
        SRC_PC:  alu_b = imm;  // AUIPC: PC + imm
        default: alu_b = rs2_data;
    endcase
end

// ---- Dato a escribir en rd ----
always_comb begin
    case (wb_src)
        WB_ALU: rd_data = alu_result;
        WB_MEM: rd_data = mem_rdata;
        WB_PC4: rd_data = pc_plus4;   // JAL/JALR guardan PC+4
        default: rd_data = alu_result;
    endcase
end

// ---- Write enable regfile ----
assign reg_we = rd_we & ~stall & ~illegal;

// ---- Señales hacia el VPU ----
assign vpu_instr_o = instr;
assign vpu_rs1_o   = rs1_data;
assign vpu_valid_o = vpu_en & ~stall;

// ---- Instancias ----

fetch fetch_inst (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .branch_taken_i (branch_taken | jump),
    .branch_target_i(branch_target),
    .stall_i        (stall),
    .pc_o           (pc),
    .pc_plus4_o     (pc_plus4),
    .instr_o        (instr),
    .imem_addr_o    (imem_addr_o),
    .imem_data_i    (imem_data_i)
);

decoder decoder_inst (
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
    .jalr_o       (jalr),
    .imm_o        (imm),
    .rs1_addr_o   (rs1_addr),
    .rs2_addr_o   (rs2_addr),
    .rd_addr_o    (rd_addr),
    .vpu_en_o     (vpu_en),
    .illegal_o    (illegal)
);

regfile regfile_inst (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .rs1_addr_i (rs1_addr),
    .rs2_addr_i (rs2_addr),
    .rd_addr_i  (rd_addr),
    .rs1_data_o (rs1_data),
    .rs2_data_o (rs2_data),
    .rd_data_i  (rd_data),
    .we_i       (reg_we)
);

alu alu_inst (
    .a_i      (alu_a),
    .b_i      (alu_b),
    .op_i     (alu_op),
    .result_o (alu_result),
    .zero_o   (alu_zero),
    .neg_o    (alu_neg),
    .carry_o  (alu_carry)
);

lsu lsu_inst (
    .addr_i       (alu_result),
    .wdata_i      (rs2_data),
    .we_i         (mem_we & ~stall),
    .width_i      (mem_width),
    .sign_i       (mem_sign),
    .rdata_o      (mem_rdata),
    .dmem_addr_o  (dmem_addr_o),
    .dmem_wdata_o (dmem_wdata_o),
    .dmem_we_o    (dmem_we_o),
    .dmem_be_o    (dmem_be_o),
    .dmem_rdata_i (dmem_rdata_i)
);

endmodule