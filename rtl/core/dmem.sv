// dmem.sv
module dmem #(
    parameter DEPTH = 1024
)(
    input  logic        clk_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,      // byte enable
    output logic [31:0] rdata_o
);

logic [31:0] mem [DEPTH];

// Lectura asíncrona
assign rdata_o = mem[addr_i[$clog2(DEPTH)+1:2]];

// Escritura síncrona con byte enable
always_ff @(posedge clk_i) begin
    if (we_i) begin
        if (be_i[0]) mem[addr_i[$clog2(DEPTH)+1:2]][7:0]   <= wdata_i[7:0];
        if (be_i[1]) mem[addr_i[$clog2(DEPTH)+1:2]][15:8]  <= wdata_i[15:8];
        if (be_i[2]) mem[addr_i[$clog2(DEPTH)+1:2]][23:16] <= wdata_i[23:16];
        if (be_i[3]) mem[addr_i[$clog2(DEPTH)+1:2]][31:24] <= wdata_i[31:24];
    end
end

endmodule