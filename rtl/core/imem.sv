// imem.sv
module imem #(
    parameter DEPTH    = 1024,
    parameter MEM_FILE = "program.hex"
)(
    input  logic [31:0] addr_i,
    output logic [31:0] data_o
);

logic [31:0] mem [DEPTH];

initial begin
    for (int i = 0; i < DEPTH; i++)
        mem[i] = 32'h00000013; // NOP por defecto
    if (MEM_FILE != "")
        $readmemh(MEM_FILE, mem);
end

// Acceso word-aligned: ignoramos los 2 bits bajos
// Índice acotado con $clog2(DEPTH) --> Ceiling Logarithm base 2 (num bits según memoria)
assign data_o = mem[addr_i[$clog2(DEPTH)+1:2]];

endmodule