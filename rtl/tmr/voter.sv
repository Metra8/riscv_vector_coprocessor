// OBSOLETE
// module already implemented on vpu_tmr.sv

module voter #(
    parameter WIDTH = 128
)(
    input  logic [WIDTH-1:0] a_i,
    input  logic [WIDTH-1:0] b_i,
    input  logic [WIDTH-1:0] c_i,
    output logic [WIDTH-1:0] result_o,
    output logic             error_o    // 1 si alguna copia difiere
);

// Votación mayoritaria bit a bit
// Resultado = mayoría de (a, b, c) para cada bit
assign result_o = (a_i & b_i) | (b_i & c_i) | (a_i & c_i);

// Error si cualquier copia difiere de las otras
assign error_o = (a_i != b_i) || (b_i != c_i);

endmodule