// vpu_top.sv
import vpu_pkg::*;

module vpu_top (
    input  logic        clk_i,
    input  logic        rst_i,

    // Interfaz con el core
    input  logic [31:0] instr_i,
    input  logic [31:0] rs1_data_i,  // registro escalar para VX
    input  logic        valid_i,
    output logic        done_o,
    output logic        illegal_o,
    output logic        stall_o
);

// ---- Señales del decoder ----
logic [4:0]      vs1_addr, vs2_addr, vd_addr;
logic            vm;
logic [4:0]      imm;
logic            src_vv, src_vx, src_vi;
logic            addsub_en, logic_en, mult_en, div_en, compare_en;
funct6_opi_t     opi_op;
funct6_opm_t     opm_op;
logic            csr_we;

// ---- Señales del regfile ----
vector_t         vs1_data, vs2_data, v0_data;
vector_t         rd_data;
logic            reg_we;
logic [15:0]     elem_we;

// ---- Señales de las unidades funcionales ----
vector_t         addsub_result;
vector_t         logic_result;
vector_t         mult_result;
vector_t         div_result;
logic [15:0]     compare_result;

// ---- Señales del CSR ----
sew_t            sew;
logic [31:0]     vl, vstart, vlmax;
logic            vxsat, vill;
logic [2:0]      vlmul;
logic            csr_we_int;
logic [11:0]     csr_addr;
logic [31:0]     csr_data;
logic [11:0]     csr_raddr;
logic [31:0]     csr_rdata;

// ---- Operando vs1 efectivo (VV, VX o VI) ----
vector_t vs1_eff;

// Replicar rs1 o inmediato en todos los elementos según SEW
always_comb begin
    vs1_eff = vs1_data; // por defecto VV
    if (src_vx) begin
        case (sew)
            SEW8:  for (int i = 0; i < 16; i++) vs1_eff.i8b[i]  = rs1_data_i[7:0];
            SEW16: for (int i = 0; i < 8;  i++) vs1_eff.i16b[i] = rs1_data_i[15:0];
            SEW32: for (int i = 0; i < 4;  i++) vs1_eff.i32b[i] = rs1_data_i[31:0];
            SEW64: for (int i = 0; i < 2;  i++) vs1_eff.i64b[i] = {32'b0, rs1_data_i};
            default: vs1_eff = vs1_data;
        endcase
    end
    else if (src_vi) begin
        case (sew)
            SEW8:  for (int i = 0; i < 16; i++) vs1_eff.i8b[i]  = {{3{imm[4]}}, imm};
            SEW16: for (int i = 0; i < 8;  i++) vs1_eff.i16b[i] = {{11{imm[4]}}, imm};
            SEW32: for (int i = 0; i < 4;  i++) vs1_eff.i32b[i] = {{27{imm[4]}}, imm};
            SEW64: for (int i = 0; i < 2;  i++) vs1_eff.i64b[i] = {{59{imm[4]}}, imm};
            default: vs1_eff = vs1_data;
        endcase
    end
end

// ---- Selección del resultado final ----
always_comb begin
    rd_data = '0;
    if      (addsub_en)  rd_data = addsub_result;
    else if (logic_en)   rd_data = logic_result;
    else if (mult_en)    rd_data = mult_result;
    else if (div_en)     rd_data = div_result;
    else if (compare_en) begin
        // resultado de comparación va a los bits bajos de vd (formato máscara)
        rd_data.i128b = {112'b0, compare_result};
    end
end

// ---- Write enable del regfile ----
// Para comparaciones siempre escribimos los 16 bits del resultado
assign reg_we = valid_i & ~illegal_o & ~csr_we;

// ---- CSR: decodificar vsetvl/vsetvli ----
// En OPCFG: rs1 lleva AVL, rd lleva nueva vtype
// vl = min(AVL, vlmax)
always_comb begin
    csr_we_int = valid_i & csr_we;
    csr_addr   = 12'hC21; // vtype por defecto
    csr_data = {20'b0, instr_i[31:20]};
    csr_raddr  = 12'hC20;
end

// ---- Instancias ----

vpu_decoder decoder (
    .instr_i      (instr_i),
    .vs1_addr_o   (vs1_addr),
    .vs2_addr_o   (vs2_addr),
    .vd_addr_o    (vd_addr),
    .vm_o         (vm),
    .imm_o        (imm),
    .src_vv_o     (src_vv),
    .src_vx_o     (src_vx),
    .src_vi_o     (src_vi),
    .addsub_en_o  (addsub_en),
    .logic_en_o   (logic_en),
    .mult_en_o    (mult_en),
    .div_en_o     (div_en),
    .compare_en_o (compare_en),
    .opi_op_o     (opi_op),
    .opm_op_o     (opm_op),
    .csr_we_o     (csr_we),
    .illegal_o    (illegal_o)
);

vpu_regfile regfile (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .rs1_addr_i (vs1_addr),
    .rs2_addr_i (vs2_addr),
    .rd_addr_i  (vd_addr),
    .rs1_data_o (vs1_data),
    .rs2_data_o (vs2_data),
    .v0_data_o  (v0_data),
    .rd_data_i  (rd_data),
    .we_i       (reg_we),
    .elem_we_i  (elem_we),
    .sew_i      (sew)
);

vpu_csr csr (
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .we_i     (csr_we_int),
    .addr_i   (csr_addr),
    .data_i   (csr_data),
    .sew_o    (sew),
    .vl_o     (vl),
    .vstart_o (vstart),
    .vxsat_o  (vxsat),
    .vlmul_o  (vlmul),
    .vlmax_o  (vlmax),
    .vill_o   (vill),
    .raddr_i  (csr_raddr),
    .rdata_o  (csr_rdata)
);

vpu_addsub addsub (
    .vs1_i    (vs1_eff),
    .vs2_i    (vs2_data),
    .sew_i    (sew),
    .op_i     (opi_op),
    .result_o (addsub_result)
);

vpu_logic logic_unit (
    .vs1_i    (vs1_eff),
    .vs2_i    (vs2_data),
    .sew_i    (sew),
    .op_i     (opi_op),
    .result_o (logic_result)
);

vpu_mult mult (
    .vs1_i    (vs1_eff),
    .vs2_i    (vs2_data),
    .sew_i    (sew),
    .op_i     (opm_op),
    .result_o (mult_result)
);

vpu_div div (
    .vs1_i    (vs1_eff),
    .vs2_i    (vs2_data),
    .sew_i    (sew),
    .op_i     (opm_op),
    .result_o (div_result)
);

vpu_compare compare (
    .vs1_i    (vs1_eff),
    .vs2_i    (vs2_data),
    .sew_i    (sew),
    .op_i     (opi_op),
    .result_o (compare_result)
);

vpu_mask mask (
    .v0_i  (v0_data),
    .sew_i (sew),
    .vm_i  (vm),
    .we_o  (elem_we)
);

// ---- Control de done y stall ----
always_ff @(posedge clk_i) begin
    if (rst_i) begin
        done_o  <= 0;
        stall_o <= 0;
    end
    else begin
        done_o  <= valid_i & ~illegal_o;
        stall_o <= 0; // single-cycle, nunca hay stall
    end
end

endmodule