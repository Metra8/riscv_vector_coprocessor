module imem #(
    parameter DEPTH = 1024
)(
    input  logic [31:0] addr_i,
    output logic [31:0] data_o
);

logic [31:0] mem [DEPTH];

initial $readmemh("program.hex", mem);

// Acceso word-aligned: ignoramos los 2 bits bajos
// Índice acotado con $clog2(DEPTH) --> Ceiling Logarithm base 2 (num bits según memoria)
assign data_o = mem[addr_i[$clog2(DEPTH)+1:2]];

endmodule