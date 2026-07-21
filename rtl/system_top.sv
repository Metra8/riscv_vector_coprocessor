// system_top.sv
import core_pkg::*;
import vpu_pkg::*;

module system_top #(
    parameter TMR_ENABLE = 0
)(
    input  logic clk_i,
    input  logic rst_i,
    output logic [31:0] core_probe_o,
    output logic tmr_error_o
);

logic [31:0] imem_addr, imem_data;
logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
logic        dmem_we;
logic [3:0]  dmem_be;
logic [31:0] vpu_instr, vpu_rs1;
logic        vpu_valid, vpu_done, vpu_illegal;

(* keep_hierarchy = "yes" *) core_top core (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
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

(* keep_hierarchy = "yes" *) imem #(.DEPTH(1024), .MEM_FILE("program.hex")) imem_inst (
    .addr_i (imem_addr),
    .data_o (imem_data)
);

(* keep_hierarchy = "yes" *) dmem #(.DEPTH(1024)) dmem_inst (
    .clk_i   (clk_i),
    .addr_i  (dmem_addr),
    .wdata_i (dmem_wdata),
    .we_i    (dmem_we),
    .be_i    (dmem_be),
    .rdata_o (dmem_rdata)
);

(* keep_hierarchy = "yes" *) vpu_top #(.TMR_ENABLE(TMR_ENABLE), .DIV_ENABLE(0)) vpu (  // ← sin TMR por defecto
    .clk_i       (clk_i),
    .rst_i       (rst_i),
    .instr_i     (vpu_instr),
    .rs1_data_i  (vpu_rs1),
    .valid_i     (vpu_valid),
    .done_o      (vpu_done),
    .illegal_o   (vpu_illegal),
    .stall_o     (),              // ← coma añadida
    .tmr_error_o (tmr_error_o)
);

assign core_probe_o = dmem_wdata ^ vpu_instr;

endmodule