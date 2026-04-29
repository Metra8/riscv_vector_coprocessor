import vpu_pkg::*;

module vpu_csr (
    input  logic        clk_i,
    input  logic        rst_i,

    // Interfaz de escritura
    input  logic        we_i,
    input  logic [11:0] addr_i,
    input  logic [31:0] data_i,

    // Salidas directas de los CSRs más usados
    output sew_t        sew_o,
    output logic [31:0] vl_o,
    output logic [31:0] vstart_o,
    output logic        vxsat_o,    // vector fixed-point saturation
    output logic [2:0]  vlmul_o,
    output logic [31:0] vlmax_o,
    output logic        vill_o,     // vector invalid layout

    // Lectura genérica
    input  logic [11:0] raddr_i,
    output logic [31:0] rdata_o
);

// LMUL fijo a 1 (3'b000) hasta que se implemente
localparam logic [2:0] VLMUL_FIXED = 3'b000;

// Registros CSR --> control and status register
logic [31:0] vstart;    // índice de inicio
logic [31:0] vxsat;
logic [31:0] vxrm;      // vector fixed-point rounding mode
logic [31:0] vcsr;      // vector control and status register
logic [31:0] vl;
logic [31:0] vtype;

// ---- Señales derivadas ----

// vlenb: VLEN/8 = 128/8 = 16 bytes, solo lectura
logic [31:0] vlenb;
assign vlenb = 32'd16;

// vlmul fijo
assign vlmul_o = VLMUL_FIXED;

// vill: bit 31 de vtype, se activa si vsew no está soportado
assign vill_o  = (vtype[5:3] > 3'b011);

// SEW extraído de vtype[5:3]
always_comb begin
    if (vill_o) begin
        sew_o   = SEW8;   // valor por defecto si configuración inválida
        vlmax_o = 32'd16; // valor por defecto
    end
    else begin
        case (vtype[5:3])
            3'b000: begin sew_o = SEW8;  vlmax_o = 32'd16; end
            3'b001: begin sew_o = SEW16; vlmax_o = 32'd8;  end
            3'b010: begin sew_o = SEW32; vlmax_o = 32'd4;  end
            3'b011: begin sew_o = SEW64; vlmax_o = 32'd2;  end
            default: begin sew_o = SEW8; vlmax_o = 32'd16; end
        endcase
    end
end

// Salidas directas
assign vl_o     = vl;
assign vstart_o = vstart;
assign vxsat_o  = vxsat[0];

// Escritura síncrona
always_ff @(posedge clk_i) begin
    if (rst_i) begin
        vstart <= '0;
        vxsat  <= '0;
        vxrm   <= '0;
        vcsr   <= '0;
        vl     <= '0;
        vtype  <= '0;
    end
    else if (we_i) begin
        case (addr_i)
            12'h008: vstart <= data_i;
            12'h009: vxsat  <= data_i;
            12'h00A: vxrm   <= data_i;
            12'h00F: vcsr   <= data_i;
            12'hC20: vl     <= data_i;
            12'hC21: begin
                // Forzar vlmul a 000 y actualizar vill en bit 31
                vtype <= {(data_i[5:3] > 3'b011), data_i[30:6], data_i[5:3], VLMUL_FIXED};
            end
            default: ;
        endcase
    end
end

// Lectura genérica
always_comb begin
    case (raddr_i)
        12'h008: rdata_o = vstart;
        12'h009: rdata_o = vxsat;
        12'h00A: rdata_o = vxrm;
        12'h00F: rdata_o = vcsr;
        12'hC20: rdata_o = vl;
        12'hC21: rdata_o = vtype;
        12'hC22: rdata_o = vlenb;
        default: rdata_o = '0;
    endcase
end

endmodule