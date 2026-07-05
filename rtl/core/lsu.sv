import core_pkg::*;

module lsu (
    // Interfaz con core_top
    input  logic [31:0] addr_i,      // dirección calculada por ALU
    input  logic [31:0] wdata_i,     // dato a escribir (rs2)
    input  logic        we_i,        // write enable
    input  mem_width_t  width_i,     // byte, half, word
    input  logic        sign_i,      // extensión de signo en loads

    // Resultado del load
    output logic [31:0] rdata_o,

    // Interfaz con dmem
    output logic [31:0] dmem_addr_o,
    output logic [31:0] dmem_wdata_o,
    output logic        dmem_we_o,
    output logic [3:0]  dmem_be_o,   // byte enable
    input  logic [31:0] dmem_rdata_i
);

// ---- Byte enable según width y dirección ----
always_comb begin
    dmem_addr_o  = {addr_i[31:2], 2'b00}; // word-aligned
    dmem_we_o    = we_i;
    dmem_wdata_o = '0;
    dmem_be_o    = '0;
    rdata_o      = '0;

    case (width_i)
        MEM_BYTE: begin
            case (addr_i[1:0])
                2'b00: begin
                    dmem_be_o    = 4'b0001;
                    dmem_wdata_o = {24'b0, wdata_i[7:0]};
                    rdata_o      = sign_i ? {{24{dmem_rdata_i[7]}},  dmem_rdata_i[7:0]}
                                          : {24'b0,                  dmem_rdata_i[7:0]};
                end
                2'b01: begin
                    dmem_be_o    = 4'b0010;
                    dmem_wdata_o = {16'b0, wdata_i[7:0], 8'b0};
                    rdata_o      = sign_i ? {{24{dmem_rdata_i[15]}}, dmem_rdata_i[15:8]}
                                          : {24'b0,                  dmem_rdata_i[15:8]};
                end
                2'b10: begin
                    dmem_be_o    = 4'b0100;
                    dmem_wdata_o = {8'b0, wdata_i[7:0], 16'b0};
                    rdata_o      = sign_i ? {{24{dmem_rdata_i[23]}}, dmem_rdata_i[23:16]}
                                          : {24'b0,                  dmem_rdata_i[23:16]};
                end
                2'b11: begin
                    dmem_be_o    = 4'b1000;
                    dmem_wdata_o = {wdata_i[7:0], 24'b0};
                    rdata_o      = sign_i ? {{24{dmem_rdata_i[31]}}, dmem_rdata_i[31:24]}
                                          : {24'b0,                  dmem_rdata_i[31:24]};
                end
            endcase
        end

        MEM_HALF: begin
            case (addr_i[1])
                1'b0: begin
                    dmem_be_o    = 4'b0011;
                    dmem_wdata_o = {16'b0, wdata_i[15:0]};
                    rdata_o      = sign_i ? {{16{dmem_rdata_i[15]}}, dmem_rdata_i[15:0]}
                                          : {16'b0,                  dmem_rdata_i[15:0]};
                end
                1'b1: begin
                    dmem_be_o    = 4'b1100;
                    dmem_wdata_o = {wdata_i[15:0], 16'b0};
                    rdata_o      = sign_i ? {{16{dmem_rdata_i[31]}}, dmem_rdata_i[31:16]}
                                          : {16'b0,                  dmem_rdata_i[31:16]};
                end
            endcase
        end

        MEM_WORD: begin
            dmem_be_o    = 4'b1111;
            dmem_wdata_o = wdata_i;
            rdata_o      = dmem_rdata_i;
        end

        default: begin
            dmem_be_o    = '0;
            dmem_wdata_o = '0;
            rdata_o      = '0;
        end
    endcase
end

endmodule