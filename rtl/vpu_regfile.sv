import vpu_pkg::*;

module vpu_regfile (
    input  logic        clk_i,
    input  logic        rst_i,

    // Puerto de lectura 1 (vs1)
    input  logic [4:0]  rs1_addr_i,
    output vector_t     rs1_data_o,

    // Puerto de lectura 2 (vs2)
    input  logic [4:0]  rs2_addr_i,
    output vector_t     rs2_data_o,

    // Puerto de lectura 3 (v0, para máscara)
    output vector_t     v0_data_o,

    // Puerto de escritura
    input  logic [4:0]  rd_addr_i,
    input  vector_t     rd_data_i,
    input  logic        we_i,        // write enable global
    input  logic [15:0] elem_we_i,   // write enable por elemento
    input  sew_t        sew_i
);

// Banco de 32 registros de 128 bits
vector_t regs [32];

// Lecturas asíncronas
assign rs1_data_o = regs[rs1_addr_i];
assign rs2_data_o = regs[rs2_addr_i];
assign v0_data_o  = regs[0];  // v0 siempre es el registro de máscara

// Escritura síncrona con write enable por elemento
always_ff @(posedge clk_i) begin
    if (rst_i) begin
        for (int i = 0; i < 32; i++)
            regs[i] <= '0;
    end
    else if (we_i) begin
        case (sew_i)
            SEW8: begin
                for (int i = 0; i < 16; i++) begin
                    if (elem_we_i[i])
                        regs[rd_addr_i].i8b[i] <= rd_data_i.i8b[i];
                end
            end
            SEW16: begin
                for (int i = 0; i < 8; i++) begin
                    if (elem_we_i[i])
                        regs[rd_addr_i].i16b[i] <= rd_data_i.i16b[i];
                end
            end
            SEW32: begin
                for (int i = 0; i < 4; i++) begin
                    if (elem_we_i[i])
                        regs[rd_addr_i].i32b[i] <= rd_data_i.i32b[i];
                end
            end
            SEW64: begin
                for (int i = 0; i < 2; i++) begin
                    if (elem_we_i[i])
                        regs[rd_addr_i].i64b[i] <= rd_data_i.i64b[i];
                end
            end
        endcase
    end
end

endmodule

/*
Los dos módulos están diseñados para trabajar juntos: `vpu_mask` genera `elem_we_i` y `vpu_regfile`
lo usa para decidir qué elementos escribir. En `vpu_top.sv` la conexión será simplemente:
vpu_mask  → elem_we_i → vpu_regfile
*/