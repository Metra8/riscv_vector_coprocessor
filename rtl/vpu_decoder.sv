import vpu_pkg::*;

module vpu_decoder (
    input  logic [31:0]     instr_i,

    // Registros
    output logic [4:0]      vs1_addr_o,
    output logic [4:0]      vs2_addr_o,
    output logic [4:0]      vd_addr_o,
    output logic            vm_o,
    output logic [4:0]      imm_o,

    // Tipo de fuente
    output logic            src_vv_o,
    output logic            src_vx_o,
    output logic            src_vi_o,

    // Habilitación de unidades funcionales
    output logic            addsub_en_o,
    output logic            logic_en_o,
    output logic            mult_en_o,
    output logic            div_en_o,
    output logic            compare_en_o,

    // Opcodes para cada unidad
    output funct6_opi_t     opi_op_o,
    output funct6_opm_t     opm_op_o,

    // CSR
    output logic            csr_we_o,

    // Control
    output logic            illegal_o
);

// ---- Extracción de campos ----
logic [6:0] opcode;
logic [2:0] funct3;
logic [5:0] funct6;

assign opcode     = instr_i[6:0];
assign vd_addr_o  = instr_i[11:7];
assign funct3     = instr_i[14:12];
assign vs1_addr_o = instr_i[19:15];
assign imm_o      = instr_i[19:15];
assign vs2_addr_o = instr_i[24:20];
assign vm_o       = instr_i[25];
assign funct6     = instr_i[31:26];

// ---- Decodificación ----
always_comb begin
    // Valores por defecto
    src_vv_o     = 0;
    src_vx_o     = 0;
    src_vi_o     = 0;
    addsub_en_o  = 0;
    logic_en_o   = 0;
    mult_en_o    = 0;
    div_en_o     = 0;
    compare_en_o = 0;
    opi_op_o     = OPI_VADD;  // valor neutro
    opm_op_o     = OPM_VMUL;  // valor neutro
    csr_we_o     = 0;
    illegal_o    = 0;

    if (opcode == 7'b1010111) begin
        case (funct3)

            // ---- Grupo OPI ----
            3'b000,  // OPIVV
            3'b100,  // OPIVX
            3'b011:  // OPIVI
            begin
                // Tipo de fuente
                case (funct3)
                    3'b000: src_vv_o = 1;
                    3'b100: src_vx_o = 1;
                    3'b011: src_vi_o = 1;
                    default: ;
                endcase

                // Asignar opcode OPI y habilitar unidad
                opi_op_o = funct6_opi_t'(funct6);
                case (funct6_opi_t'(funct6))
                    OPI_VADD,
                    OPI_VSUB,
                    OPI_VRSUB,
                    OPI_VMINU,
                    OPI_VMIN,
                    OPI_VMAXU,
                    OPI_VMAX:   addsub_en_o  = 1;

                    OPI_VAND,
                    OPI_VOR,
                    OPI_VXOR,
                    OPI_VSLL,
                    OPI_VSRL,
                    OPI_VSRA:   logic_en_o   = 1;

                    OPI_VMSEQ,
                    OPI_VMSNE,
                    OPI_VMSLTU,
                    OPI_VMSLT,
                    OPI_VMSLEU,
                    OPI_VMSLE,
                    OPI_VMSGTU,
                    OPI_VMSGT:  compare_en_o = 1;

                    default:    illegal_o    = 1;
                endcase
            end

            // ---- Grupo OPM ----
            3'b010,  // OPMVV
            3'b110:  // OPMVX
            begin
                case (funct3)
                    3'b010: src_vv_o = 1;
                    3'b110: src_vx_o = 1;
                    default: ;
                endcase

                // Asignar opcode OPM y habilitar unidad
                opm_op_o = funct6_opm_t'(funct6);
                case (funct6_opm_t'(funct6))
                    OPM_VMUL,
                    OPM_VMULHU,
                    OPM_VMULHSU,
                    OPM_VMULH:  mult_en_o = 1;

                    OPM_VDIVU,
                    OPM_VDIV,
                    OPM_VREMU,
                    OPM_VREM:   div_en_o  = 1;

                    default:    illegal_o = 1;
                endcase
            end

            // ---- OPCFG: vsetvl / vsetvli ----
            3'b111: csr_we_o = 1;

            default: illegal_o = 1;
        endcase
    end
    else begin
        illegal_o = 1;
    end
end

endmodule