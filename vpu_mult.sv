// vpu_mult.sv
import vpu_pkg::*;

module vpu_mult (
    input  vector_t      vs1_i,
    input  vector_t      vs2_i,
    input  sew_t         sew_i,
    input  funct6_opm_t  op_i,
    output vector_t      result_o
);

// Temporales para productos parciales declarados fuera del always_comb
logic [15:0]  temp_uu_8  [16];
logic [15:0]  temp_ss_8  [16];
logic [15:0]  temp_su_8  [16];

logic [31:0]  temp_uu_16 [8];
logic [31:0]  temp_ss_16 [8];
logic [31:0]  temp_su_16 [8];

logic [63:0]  temp_uu_32 [4];
logic [63:0]  temp_ss_32 [4];
logic [63:0]  temp_su_32 [4];

logic [127:0] temp_uu_64 [2];
logic [127:0] temp_ss_64 [2];
logic [127:0] temp_su_64 [2];

always_comb begin
    result_o    = '0;

    // Inicializar todos los temporales
    for (int i = 0; i < 16; i++) begin
        temp_uu_8[i] = '0;
        temp_ss_8[i] = '0;
        temp_su_8[i] = '0;
    end
    for (int i = 0; i < 8; i++) begin
        temp_uu_16[i] = '0;
        temp_ss_16[i] = '0;
        temp_su_16[i] = '0;
    end
    for (int i = 0; i < 4; i++) begin
        temp_uu_32[i] = '0;
        temp_ss_32[i] = '0;
        temp_su_32[i] = '0;
    end
    for (int i = 0; i < 2; i++) begin
        temp_uu_64[i] = '0;
        temp_ss_64[i] = '0;
        temp_su_64[i] = '0;
    end

    case (sew_i)

        SEW8: begin
            for (int i = 0; i < 16; i++) begin
                temp_uu_8[i] = vs2_i.i8b[i] * vs1_i.i8b[i];
                temp_ss_8[i] = signed'(vs2_i.i8b[i]) * signed'(vs1_i.i8b[i]);
                temp_su_8[i] = signed'(vs2_i.i8b[i]) * vs1_i.i8b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i8b[i] = temp_uu_8[i][7:0];
                    OPM_VMULHU:  result_o.i8b[i] = temp_uu_8[i][15:8];
                    OPM_VMULH:   result_o.i8b[i] = temp_ss_8[i][15:8];
                    OPM_VMULHSU: result_o.i8b[i] = temp_su_8[i][15:8];
                    default:     result_o.i8b[i] = '0;
                endcase
            end
        end

        SEW16: begin
            for (int i = 0; i < 8; i++) begin
                temp_uu_16[i] = vs2_i.i16b[i] * vs1_i.i16b[i];
                temp_ss_16[i] = signed'(vs2_i.i16b[i]) * signed'(vs1_i.i16b[i]);
                temp_su_16[i] = signed'(vs2_i.i16b[i]) * vs1_i.i16b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i16b[i] = temp_uu_16[i][15:0];
                    OPM_VMULHU:  result_o.i16b[i] = temp_uu_16[i][31:16];
                    OPM_VMULH:   result_o.i16b[i] = temp_ss_16[i][31:16];
                    OPM_VMULHSU: result_o.i16b[i] = temp_su_16[i][31:16];
                    default:     result_o.i16b[i] = '0;
                endcase
            end
        end

        SEW32: begin
            for (int i = 0; i < 4; i++) begin
                temp_uu_32[i] = vs2_i.i32b[i] * vs1_i.i32b[i];
                temp_ss_32[i] = signed'(vs2_i.i32b[i]) * signed'(vs1_i.i32b[i]);
                temp_su_32[i] = signed'(vs2_i.i32b[i]) * vs1_i.i32b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i32b[i] = temp_uu_32[i][31:0];
                    OPM_VMULHU:  result_o.i32b[i] = temp_uu_32[i][63:32];
                    OPM_VMULH:   result_o.i32b[i] = temp_ss_32[i][63:32];
                    OPM_VMULHSU: result_o.i32b[i] = temp_su_32[i][63:32];
                    default:     result_o.i32b[i] = '0;
                endcase
            end
        end

        SEW64: begin
            for (int i = 0; i < 2; i++) begin
                temp_uu_64[i] = vs2_i.i64b[i] * vs1_i.i64b[i];
                temp_ss_64[i] = signed'(vs2_i.i64b[i]) * signed'(vs1_i.i64b[i]);
                temp_su_64[i] = signed'(vs2_i.i64b[i]) * vs1_i.i64b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i64b[i] = temp_uu_64[i][63:0];
                    OPM_VMULHU:  result_o.i64b[i] = temp_uu_64[i][127:64];
                    OPM_VMULH:   result_o.i64b[i] = temp_ss_64[i][127:64];
                    OPM_VMULHSU: result_o.i64b[i] = temp_su_64[i][127:64];
                    default:     result_o.i64b[i] = '0;
                endcase
            end
        end

        default: result_o = '0;

    endcase
end

endmodule