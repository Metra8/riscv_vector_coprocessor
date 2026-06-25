import core_pkg::*;

module regfile (
    input  logic        clk_i,
    input  logic        rst_i,

    // Puerto de lectura 1
    input  logic [4:0]  rs1_addr_i,
    output logic [31:0] rs1_data_o,

    // Puerto de lectura 2
    input  logic [4:0]  rs2_addr_i,
    output logic [31:0] rs2_data_o,

    // Puerto de escritura
    input  logic [4:0]  rd_addr_i,
    input  logic [31:0] rd_data_i,
    input  logic        we_i
);

// Banco de 32 registros de 32 bits
logic [31:0] regs [32];

// x0 siempre es 0
assign rs1_data_o = (rs1_addr_i == 5'd0) ? 32'h0 : regs[rs1_addr_i];
assign rs2_data_o = (rs2_addr_i == 5'd0) ? 32'h0 : regs[rs2_addr_i];

// Escritura síncrona, x0 no se puede escribir
always_ff @(posedge clk_i) begin
    if (rst_i) begin
        for (int i = 0; i < 32; i++)
            regs[i] <= '0;
    end
    else if (we_i && rd_addr_i != 5'd0)
        regs[rd_addr_i] <= rd_data_i;
end

endmodule