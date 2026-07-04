import core_pkg::*;

module fetch (
    input  logic        clk_i,
    input  logic        rst_i,

    // Control de salto (viene de core_top)
    input  logic        branch_taken_i,
    input  logic [31:0] branch_target_i,

    // Stall del VPU
    input  logic        stall_i,

    // Salidas hacia core_top
    output logic [31:0] pc_o,
    output logic [31:0] pc_plus4_o,
    output logic [31:0] instr_o,

    // Interfaz con imem
    output logic [31:0] imem_addr_o,
    input  logic [31:0] imem_data_i
);

logic [31:0] pc;

// Dirección de memoria = PC actual
assign imem_addr_o = pc;
assign pc_o        = pc;
assign pc_plus4_o  = pc + 32'd4;
assign instr_o     = imem_data_i;

// Actualización del PC
always_ff @(posedge clk_i) begin
    if (rst_i)
        pc <= 32'h0;
    else if (!stall_i) begin
        if (branch_taken_i)
            pc <= branch_target_i;
        else
            pc <= pc + 32'd4;
    end
    // Si stall_i=1 el PC no avanza (esperando al VPU)
end

endmodule