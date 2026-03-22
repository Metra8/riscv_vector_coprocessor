import vpu_pkg::*;

module vpu_mask (
    input  vector_t     v0_i,   // registro de máscara
    input  sew_t        sew_i,
    input  logic        vm_i,   // bit vm de la instrucción (0=usar máscara, 1=no usar máscara)
    output logic [15:0] we_o // write enable por elemento
);

always_comb begin
    if (vm_i) begin
        // Sin máscara, los elementos se escriben
        we_o = 16'hFFFF;
    end
    else begin
        // Con máscara, usamos v0 según el SEW
        case (sew_i)
            SEW8:  we_o = v0_i.i8b[0];  // 16 bits, un bit por elemento
            SEW16: we_o = {8'b0,  v0_i.i8b[0][7:0]};  // 8 bits válidos
            SEW32: we_o = {12'b0, v0_i.i8b[0][3:0]};  // 4 bits válidos
            SEW64: we_o = {14'b0, v0_i.i8b[0][1:0]};  // 2 bits válidos
            default: we_o = 16'hFFFF;
        endcase
    end
end

endmodule