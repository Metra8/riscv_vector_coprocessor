import vpu_pkg::*;

module vpu_tmr (
    input  logic        clk_i,
    input  logic        rst_i,

    // Interfaz con el core (igual que vpu_top)
    input  logic [31:0] instr_i,
    input  logic [31:0] rs1_data_i,
    input  logic        valid_i,
    output logic        done_o,
    output logic        illegal_o,
    output logic        stall_o,

    // Señal de error TMR
    output logic        tmr_error_o
);

// ---- Salidas de cada copia ----
logic done_a,    done_b,    done_c;
logic illegal_a, illegal_b, illegal_c;
logic stall_a,   stall_b,   stall_c;

// ---- Tres copias del VPU ----
vpu_top vpu_a (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .instr_i    (instr_i),
    .rs1_data_i (rs1_data_i),
    .valid_i    (valid_i),
    .done_o     (done_a),
    .illegal_o  (illegal_a),
    .stall_o    (stall_a)
);

vpu_top vpu_b (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .instr_i    (instr_i),
    .rs1_data_i (rs1_data_i),
    .valid_i    (valid_i),
    .done_o     (done_b),
    .illegal_o  (illegal_b),
    .stall_o    (stall_b)
);

vpu_top vpu_c (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .instr_i    (instr_i),
    .rs1_data_i (rs1_data_i),
    .valid_i    (valid_i),
    .done_o     (done_c),
    .illegal_o  (illegal_c),
    .stall_o    (stall_c)
);

// ---- Votación mayoritaria de señales de control ----
assign done_o    = (done_a    & done_b)    | (done_b    & done_c)    | (done_a    & done_c);
assign illegal_o = (illegal_a & illegal_b) | (illegal_b & illegal_c) | (illegal_a & illegal_c);
assign stall_o   = (stall_a   & stall_b)   | (stall_b   & stall_c)   | (stall_a   & stall_c);

// ---- Detección de error ----
assign tmr_error_o = (done_a    != done_b)    || (done_b    != done_c)    ||
                     (illegal_a != illegal_b) || (illegal_b != illegal_c) ||
                     (stall_a   != stall_b)   || (stall_b   != stall_c);

endmodule