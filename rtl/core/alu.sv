import core_pkg::*;

// completamente combinacional, sin reloj. Los flags zero_o y neg_o los usará core_top.sv para evaluar las condiciones de branch:

// BEQ → zero_o tras SUB
// BNE → ~zero_o tras SUB
// BLT → neg_o tras SUB (signed)
// BGE → ~neg_o tras SUB (signed)
// BLTU → carry_o tras SUB (unsigned)
// BGEU → ~carry_o tras SUB (unsigned)

module alu (
    input  logic [31:0] a_i,      // operando A (siempre rs1 o PC)
    input  logic [31:0] b_i,      // operando B (rs2, inmediato o PC)
    input  alu_op_t     op_i,     // operación
    output logic [31:0] result_o, // resultado
    output logic        zero_o,   // result == 0 (para branches)
    output logic        neg_o,    // result < 0  (para branches)
    output logic        carry_o   // carry out   (para SLTU)
);

always_comb begin
    result_o = '0;
    carry_o  = '0;

    case (op_i)
        ALU_ADD:  {carry_o, result_o} = a_i + b_i;
        ALU_SUB:  {carry_o, result_o} = a_i - b_i;
        ALU_AND:  result_o = a_i & b_i;
        ALU_OR:   result_o = a_i | b_i;
        ALU_XOR:  result_o = a_i ^ b_i;
        ALU_SLL:  result_o = a_i << b_i[4:0];
        ALU_SRL:  result_o = a_i >> b_i[4:0];
        ALU_SRA:  result_o = $signed(a_i) >>> b_i[4:0];
        ALU_SLT:  result_o = ($signed(a_i) < $signed(b_i)) ? 32'd1 : 32'd0;
        ALU_SLTU: result_o = (a_i < b_i) ? 32'd1 : 32'd0;
        ALU_LUI:  result_o = b_i; // pasa B directamente
        default:  result_o = '0;
    endcase
end

// Flags para el control de branches
assign zero_o  = (result_o == 32'h0);
assign neg_o   = result_o[31];

endmodule