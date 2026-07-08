module imem #(
    parameter DEPTH    = 1024,
    parameter MEM_FILE = "program.hex"
)(
    input  logic        clk_i,
    input  logic [31:0] addr_i,
    output logic [31:0] data_o,

    // Puerto de escritura para inicialización en simulación
    input  logic        init_we_i,
    input  logic [31:0] init_addr_i,
    input  logic [31:0] init_data_i
);

logic [31:0] mem [DEPTH];

initial begin
    for (int i = 0; i < DEPTH; i++)
        mem[i] = 32'h00000013; // NOP por defecto
    if (MEM_FILE != "")
        $readmemh(MEM_FILE, mem);
end

// Lectura asíncrona
assign data_o = mem[addr_i[$clog2(DEPTH)+1:2]];

// Escritura síncrona para inicialización
always_ff @(posedge clk_i) begin
    if (init_we_i)
        // Acceso word-aligned: ignoramos los 2 bits bajos
        // Índice acotado con $clog2(DEPTH) --> Ceiling Logarithm base 2 (num bits según memoria)
        mem[init_addr_i[$clog2(DEPTH)+1:2]] <= init_data_i;
end

endmodule