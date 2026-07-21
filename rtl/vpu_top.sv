// vpu_top.sv
import vpu_pkg::*;

module vpu_top #(
    parameter TMR_ENABLE = 0,  // 0 = sin TMR, 1 = con TMR (3 carriles)
    parameter DIV_ENABLE = 1   // 0 = sin división (síntesis), 1 = con división (simulación)
)(
    input  logic        clk_i,
    input  logic        rst_i,

    // Interfaz con el core
    input  logic [31:0] instr_i,
    input  logic [31:0] rs1_data_i,
    input  logic        valid_i,
    output logic        done_o,
    output logic        illegal_o,
    output logic        stall_o,
    output logic        tmr_error_o
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
logic            vl_we;
logic [31:0]     vl_data;

assign vl_we   = valid_i & csr_we;
assign vl_data = (rs1_data_i > vlmax) ? vlmax : rs1_data_i;

// ---- Operando vs1 efectivo (VV, VX o VI) ----
vector_t vs1_eff;

always_comb begin
    vs1_eff = vs1_data;
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
            SEW8:  for (int i = 0; i < 16; i++) vs1_eff.i8b[i]  = {{3{imm[4]}},  imm};
            SEW16: for (int i = 0; i < 8;  i++) vs1_eff.i16b[i] = {{11{imm[4]}}, imm};
            SEW32: for (int i = 0; i < 4;  i++) vs1_eff.i32b[i] = {{27{imm[4]}}, imm};
            SEW64: for (int i = 0; i < 2;  i++) vs1_eff.i64b[i] = {{59{imm[4]}}, imm};
            default: vs1_eff = vs1_data;
        endcase
    end
end

// ---- Resultados del carril A ----
vector_t     addsub_result_a, logic_result_a, mult_result_a, div_result_a;
logic [15:0] compare_result_a;
vector_t     rd_data_a;

always_comb begin
    rd_data_a = '0;
    if      (addsub_en)  rd_data_a = addsub_result_a;
    else if (logic_en)   rd_data_a = logic_result_a;
    else if (mult_en)    rd_data_a = mult_result_a;
    else if (div_en)     rd_data_a = div_result_a;
    else if (compare_en) rd_data_a.i128b = {112'b0, compare_result_a};
end

// ---- Generate DIV carril A ----
generate
    if (DIV_ENABLE) begin : div_a_block
        vpu_div div_a (.vs1_i(vs1_eff), .vs2_i(vs2_data),
                       .sew_i(sew), .op_i(opm_op), .result_o(div_result_a));
    end
    else begin : no_div_a_block
        assign div_result_a = '0;
    end
endgenerate

// ---- Generate TMR ----
generate
    if (TMR_ENABLE) begin : tmr_block

        // Resultados carriles B y C
        vector_t     addsub_result_b, logic_result_b, mult_result_b, div_result_b;
        logic [15:0] compare_result_b;
        vector_t     rd_data_b;

        vector_t     addsub_result_c, logic_result_c, mult_result_c, div_result_c;
        logic [15:0] compare_result_c;
        vector_t     rd_data_c;

        always_comb begin
            rd_data_b = '0;
            if      (addsub_en)  rd_data_b = addsub_result_b;
            else if (logic_en)   rd_data_b = logic_result_b;
            else if (mult_en)    rd_data_b = mult_result_b;
            else if (div_en)     rd_data_b = div_result_b;
            else if (compare_en) rd_data_b.i128b = {112'b0, compare_result_b};
        end

        always_comb begin
            rd_data_c = '0;
            if      (addsub_en)  rd_data_c = addsub_result_c;
            else if (logic_en)   rd_data_c = logic_result_c;
            else if (mult_en)    rd_data_c = mult_result_c;
            else if (div_en)     rd_data_c = div_result_c;
            else if (compare_en) rd_data_c.i128b = {112'b0, compare_result_c};
        end

        // Carril B (sin div)
        (* dont_touch = "true" *) vpu_addsub addsub_b (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(addsub_result_b));
        (* dont_touch = "true" *) vpu_logic  logic_b  (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(logic_result_b));
        (* dont_touch = "true" *) vpu_mult   mult_b   (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opm_op), .result_o(mult_result_b));
        (* dont_touch = "true" *) vpu_compare compare_b (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(compare_result_b));

        // Carril C (sin div)
        vpu_addsub addsub_c (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(addsub_result_c));
        vpu_logic  logic_c  (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(logic_result_c));
        vpu_mult   mult_c   (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opm_op), .result_o(mult_result_c));
        vpu_compare compare_c (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(compare_result_c));

        // DIV en carriles B y C condicionado por DIV_ENABLE
        if (DIV_ENABLE) begin : div_bc_block
            vpu_div div_b (.vs1_i(vs1_eff), .vs2_i(vs2_data),
                           .sew_i(sew), .op_i(opm_op), .result_o(div_result_b));
            vpu_div div_c (.vs1_i(vs1_eff), .vs2_i(vs2_data),
                           .sew_i(sew), .op_i(opm_op), .result_o(div_result_c));
        end
        else begin : no_div_bc_block
            assign div_result_b = '0;
            assign div_result_c = '0;
        end

        // Voter sobre rd_data
        voter #(.WIDTH(128)) voter_inst (
            .a_i      (rd_data_a.i128b),
            .b_i      (rd_data_b.i128b),
            .c_i      (rd_data_c.i128b),
            .result_o (rd_data.i128b),
            .error_o  (tmr_error_o)
        );

    end
    else begin : no_tmr_block
        assign rd_data     = rd_data_a;
        assign tmr_error_o = 1'b0;
    end
endgenerate

// ---- Write enable del regfile ----
assign reg_we = valid_i & ~illegal_o & ~csr_we;

// ---- CSR ----
always_comb begin
    csr_we_int = valid_i & csr_we;
    csr_raddr  = 12'hC20;
    if (csr_we) begin
        csr_addr = 12'hC21;
        csr_data = {20'b0, instr_i[31:20]};
    end
    else begin
        csr_addr = 12'hC21;
        csr_data = '0;
    end
end

// ---- Instancias compartidas ----
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
    .clk_i     (clk_i),
    .rst_i     (rst_i),
    .we_i      (csr_we_int),
    .addr_i    (csr_addr),
    .data_i    (csr_data),
    .sew_o     (sew),
    .vl_o      (vl),
    .vstart_o  (vstart),
    .vxsat_o   (vxsat),
    .vlmul_o   (vlmul),
    .vlmax_o   (vlmax),
    .vill_o    (vill),
    .raddr_i   (csr_raddr),
    .rdata_o   (csr_rdata),
    .vl_we_i   (vl_we),
    .vl_data_i (vl_data)
);

// ---- Carril A (siempre presente, sin div que va en generate) ----
vpu_addsub addsub_a (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(addsub_result_a));
vpu_logic  logic_a  (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(logic_result_a));
vpu_mult   mult_a   (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opm_op), .result_o(mult_result_a));
vpu_compare compare_a (.vs1_i(vs1_eff), .vs2_i(vs2_data), .sew_i(sew), .op_i(opi_op), .result_o(compare_result_a));

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
        done_o  <= valid_i;
        stall_o <= 0;
    end
end

endmodule