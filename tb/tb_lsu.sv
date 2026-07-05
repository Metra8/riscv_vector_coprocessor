import core_pkg::*;

module tb_lsu;

// ---- Señales ----
logic        clk;
logic [31:0] addr, wdata, rdata;
logic        we, sign;
mem_width_t  width;
logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
logic        dmem_we;
logic [3:0]  dmem_be;

// ---- DUT ----
lsu dut (
    .addr_i       (addr),
    .wdata_i      (wdata),
    .we_i         (we),
    .width_i      (width),
    .sign_i       (sign),
    .rdata_o      (rdata),
    .dmem_addr_o  (dmem_addr),
    .dmem_wdata_o (dmem_wdata),
    .dmem_we_o    (dmem_we),
    .dmem_be_o    (dmem_be),
    .dmem_rdata_i (dmem_rdata)
);

// ---- Generador de reloj ----
initial clk = 0;
always #5 clk = ~clk;

// ---- Modelo simple de dmem ----
// Simula una palabra de 32 bits en cada dirección
logic [31:0] mem_model [4];

// Lectura asíncrona
assign dmem_rdata = mem_model[dmem_addr[3:2]];

// Escritura síncrona con byte enable
always_ff @(posedge clk) begin
    if (dmem_we) begin
        if (dmem_be[0]) mem_model[dmem_addr[3:2]][7:0]   <= dmem_wdata[7:0];
        if (dmem_be[1]) mem_model[dmem_addr[3:2]][15:8]  <= dmem_wdata[15:8];
        if (dmem_be[2]) mem_model[dmem_addr[3:2]][23:16] <= dmem_wdata[23:16];
        if (dmem_be[3]) mem_model[dmem_addr[3:2]][31:24] <= dmem_wdata[31:24];
    end
end

// ---- Tareas de verificación ----
task check_32;
    input string     test_name;
    input logic [31:0] got;
    input logic [31:0] expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %h | expected: %h",
                      test_name, got, expected);
    end
endtask

task check_4;
    input string    test_name;
    input logic [3:0] got;
    input logic [3:0] expected;
    begin
        if (got === expected)
            $display("PASS | %s", test_name);
        else
            $display("FAIL | %s | got: %b | expected: %b",
                      test_name, got, expected);
    end
endtask

// ---- Tests ----
initial begin
    we = 0; sign = 1;
    addr = '0; wdata = '0;
    width = MEM_WORD;

    // Inicializar memoria modelo
    mem_model[0] = 32'hAABBCCDD;
    mem_model[1] = 32'h11223344;
    mem_model[2] = 32'h55667788;
    mem_model[3] = 32'hDEADBEEF;

    // ----------------------------------------
    // LW: load word
    // ----------------------------------------
    addr = 32'h0; we = 0; width = MEM_WORD; sign = 1; #1;
    check_32("LW addr=0x00", rdata, 32'hAABBCCDD);

    addr = 32'h4; #1;
    check_32("LW addr=0x04", rdata, 32'h11223344);

    addr = 32'h8; #1;
    check_32("LW addr=0x08", rdata, 32'h55667788);

    // ----------------------------------------
    // LB signed: load byte con extensión de signo
    // ----------------------------------------
    addr = 32'h0; width = MEM_BYTE; sign = 1; #1;
    // mem[0] = 0xAABBCCDD → byte0 = 0xDD = -35 signed
    check_32("LB signed byte0", rdata, 32'hFFFFFFDD);
    check_4 ("LB be byte0",     dmem_be, 4'b0001);

    addr = 32'h1; #1;
    // byte1 = 0xCC = -52 signed
    check_32("LB signed byte1", rdata, 32'hFFFFFFCC);
    check_4 ("LB be byte1",     dmem_be, 4'b0010);

    addr = 32'h2; #1;
    // byte2 = 0xBB = -69 signed
    check_32("LB signed byte2", rdata, 32'hFFFFFFBB);
    check_4 ("LB be byte2",     dmem_be, 4'b0100);

    addr = 32'h3; #1;
    // byte3 = 0xAA = -86 signed
    check_32("LB signed byte3", rdata, 32'hFFFFFFAA);
    check_4 ("LB be byte3",     dmem_be, 4'b1000);

    // ----------------------------------------
    // LBU: load byte sin extensión de signo
    // ----------------------------------------
    addr = 32'h0; width = MEM_BYTE; sign = 0; #1;
    check_32("LBU byte0", rdata, 32'h000000DD);

    addr = 32'h3; #1;
    check_32("LBU byte3", rdata, 32'h000000AA);

    // ----------------------------------------
    // LH signed: load halfword
    // ----------------------------------------
    addr = 32'h0; width = MEM_HALF; sign = 1; #1;
    // half0 = 0xCCDD = -13091 signed
    check_32("LH signed half0", rdata, 32'hFFFFCCDD);
    check_4 ("LH be half0",     dmem_be, 4'b0011);

    addr = 32'h2; #1;
    // half1 = 0xAABB = -21829 signed
    check_32("LH signed half1", rdata, 32'hFFFFAABB);
    check_4 ("LH be half1",     dmem_be, 4'b1100);

    // ----------------------------------------
    // LHU: load halfword sin extensión de signo
    // ----------------------------------------
    addr = 32'h0; width = MEM_HALF; sign = 0; #1;
    check_32("LHU half0", rdata, 32'h0000CCDD);

    addr = 32'h2; sign = 0; #1;
    check_32("LHU half1", rdata, 32'h0000AABB);

    // ----------------------------------------
    // SW: store word
    // ----------------------------------------
    @(posedge clk);
    addr = 32'h0; wdata = 32'hDEADBEEF; we = 1; width = MEM_WORD; #1;
    check_4("SW be", dmem_be, 4'b1111);
    @(posedge clk); #1;
    we = 0; addr = 32'h0; width = MEM_WORD; #1;
    check_32("SW resultado", rdata, 32'hDEADBEEF);

    // ----------------------------------------
    // SB: store byte en distintas posiciones
    // ----------------------------------------
    @(posedge clk);
    // Primero escribir palabra conocida
    addr = 32'h4; wdata = 32'hFFFFFFFF; we = 1; width = MEM_WORD;
    @(posedge clk); #1;
    // Ahora escribir solo byte0
    addr = 32'h4; wdata = 32'hABCDEF12; we = 1; width = MEM_BYTE; #1;
    check_4("SB be byte0", dmem_be, 4'b0001);
    @(posedge clk); #1;
    we = 0; addr = 32'h4; width = MEM_WORD; #1;
    // Solo byte0 cambia a 0x12, resto sigue 0xFF
    check_32("SB byte0 resultado", rdata, 32'hFFFFFF12);

    // Store byte en posicion 2
    @(posedge clk);
    addr = 32'h6; wdata = 32'hABCDEF99; we = 1; width = MEM_BYTE; #1;
    check_4("SB be byte2", dmem_be, 4'b0100);
    @(posedge clk); #1;
    we = 0; addr = 32'h4; width = MEM_WORD; #1;
    // byte2 cambia a 0x99
    check_32("SB byte2 resultado", rdata, 32'hFF99FF12);

    // ----------------------------------------
    // SH: store halfword
    // ----------------------------------------
    @(posedge clk);
    addr = 32'h8; wdata = 32'hFFFFFFFF; we = 1; width = MEM_WORD;
    @(posedge clk); #1;
    addr = 32'h8; wdata = 32'hABCD1234; we = 1; width = MEM_HALF; #1;
    check_4("SH be half0", dmem_be, 4'b0011);
    @(posedge clk); #1;
    we = 0; addr = 32'h8; width = MEM_WORD; #1;
    // half0 cambia a 0x1234, half1 sigue 0xFFFF
    check_32("SH half0 resultado", rdata, 32'hFFFF1234);

    $display("---- Tests completados ----");
    $finish;
end

endmodule