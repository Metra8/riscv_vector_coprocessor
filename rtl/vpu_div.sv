// vpu_div.sv
import vpu_pkg::*;

module vpu_div (
    input  vector_t      vs1_i,
    input  vector_t      vs2_i,
    input  sew_t         sew_i,
    input  funct6_opm_t  op_i,
    output vector_t      result_o
);

// Variables para división signed SEW8
logic        sign_vs2_8  [16], sign_vs1_8  [16], sign_res_8  [16];
logic [7:0]  abs_vs2_8   [16], abs_vs1_8   [16], abs_res_8   [16];

// Variables para división signed SEW16
logic        sign_vs2_16 [8],  sign_vs1_16 [8],  sign_res_16 [8];
logic [15:0] abs_vs2_16  [8],  abs_vs1_16  [8],  abs_res_16  [8];

// Variables para división signed SEW32
logic        sign_vs2_32 [4],  sign_vs1_32 [4],  sign_res_32 [4];
logic [31:0] abs_vs2_32  [4],  abs_vs1_32  [4],  abs_res_32  [4];

// Variables para división signed SEW64
logic        sign_vs2_64 [2],  sign_vs1_64 [2],  sign_res_64 [2];
logic [63:0] abs_vs2_64  [2],  abs_vs1_64  [2],  abs_res_64  [2];

always_comb begin
    result_o = '0;

    // Inicializar variables
    for (int i = 0; i < 16; i++) begin
        sign_vs2_8[i] = '0; sign_vs1_8[i] = '0; sign_res_8[i] = '0;
        abs_vs2_8[i]  = '0; abs_vs1_8[i]  = '0; abs_res_8[i]  = '0;
    end
    for (int i = 0; i < 8; i++) begin
        sign_vs2_16[i] = '0; sign_vs1_16[i] = '0; sign_res_16[i] = '0;
        abs_vs2_16[i]  = '0; abs_vs1_16[i]  = '0; abs_res_16[i]  = '0;
    end
    for (int i = 0; i < 4; i++) begin
        sign_vs2_32[i] = '0; sign_vs1_32[i] = '0; sign_res_32[i] = '0;
        abs_vs2_32[i]  = '0; abs_vs1_32[i]  = '0; abs_res_32[i]  = '0;
    end
    for (int i = 0; i < 2; i++) begin
        sign_vs2_64[i] = '0; sign_vs1_64[i] = '0; sign_res_64[i] = '0;
        abs_vs2_64[i]  = '0; abs_vs1_64[i]  = '0; abs_res_64[i]  = '0;
    end

    case (sew_i)

        SEW8: begin
            for (int i = 0; i < 16; i++) begin
                // Calcular signos y valores absolutos
                sign_vs2_8[i] = vs2_i.i8b[i][7];
                sign_vs1_8[i] = vs1_i.i8b[i][7];
                sign_res_8[i] = sign_vs2_8[i] ^ sign_vs1_8[i];
                abs_vs2_8[i]  = sign_vs2_8[i] ? (~vs2_i.i8b[i] + 1) : vs2_i.i8b[i];
                abs_vs1_8[i]  = sign_vs1_8[i] ? (~vs1_i.i8b[i] + 1) : vs1_i.i8b[i];
                abs_res_8[i]  = abs_vs2_8[i] / abs_vs1_8[i];

                case (op_i)
                    OPM_VDIVU: result_o.i8b[i] = (vs1_i.i8b[i] == '0) ? '1 :
                                                   vs2_i.i8b[i] / vs1_i.i8b[i];
                    OPM_VDIV:  result_o.i8b[i] = (vs1_i.i8b[i] == '0) ? '1 :
                                                   sign_res_8[i] ? (~abs_res_8[i] + 1) : abs_res_8[i];
                    OPM_VREMU: result_o.i8b[i] = (vs1_i.i8b[i] == '0) ? vs2_i.i8b[i] :
                                                   vs2_i.i8b[i] % vs1_i.i8b[i];
                    OPM_VREM:  result_o.i8b[i] = (vs1_i.i8b[i] == '0) ? vs2_i.i8b[i] :
                                                   sign_vs2_8[i] ? (~(abs_vs2_8[i] % abs_vs1_8[i]) + 1) :
                                                                     (abs_vs2_8[i] % abs_vs1_8[i]);
                    default:   result_o.i8b[i] = '0;
                endcase
            end
        end

        SEW16: begin
            for (int i = 0; i < 8; i++) begin
                sign_vs2_16[i] = vs2_i.i16b[i][15];
                sign_vs1_16[i] = vs1_i.i16b[i][15];
                sign_res_16[i] = sign_vs2_16[i] ^ sign_vs1_16[i];
                abs_vs2_16[i]  = sign_vs2_16[i] ? (~vs2_i.i16b[i] + 1) : vs2_i.i16b[i];
                abs_vs1_16[i]  = sign_vs1_16[i] ? (~vs1_i.i16b[i] + 1) : vs1_i.i16b[i];
                abs_res_16[i]  = abs_vs2_16[i] / abs_vs1_16[i];

                case (op_i)
                    OPM_VDIVU: result_o.i16b[i] = (vs1_i.i16b[i] == '0) ? '1 :
                                                    vs2_i.i16b[i] / vs1_i.i16b[i];
                    OPM_VDIV:  result_o.i16b[i] = (vs1_i.i16b[i] == '0) ? '1 :
                                                    sign_res_16[i] ? (~abs_res_16[i] + 1) : abs_res_16[i];
                    OPM_VREMU: result_o.i16b[i] = (vs1_i.i16b[i] == '0) ? vs2_i.i16b[i] :
                                                    vs2_i.i16b[i] % vs1_i.i16b[i];
                    OPM_VREM:  result_o.i16b[i] = (vs1_i.i16b[i] == '0) ? vs2_i.i16b[i] :
                                                    sign_vs2_16[i] ? (~(abs_vs2_16[i] % abs_vs1_16[i]) + 1) :
                                                                      (abs_vs2_16[i] % abs_vs1_16[i]);
                    default:   result_o.i16b[i] = '0;
                endcase
            end
        end

        SEW32: begin
            for (int i = 0; i < 4; i++) begin
                sign_vs2_32[i] = vs2_i.i32b[i][31];
                sign_vs1_32[i] = vs1_i.i32b[i][31];
                sign_res_32[i] = sign_vs2_32[i] ^ sign_vs1_32[i];
                abs_vs2_32[i]  = sign_vs2_32[i] ? (~vs2_i.i32b[i] + 1) : vs2_i.i32b[i];
                abs_vs1_32[i]  = sign_vs1_32[i] ? (~vs1_i.i32b[i] + 1) : vs1_i.i32b[i];
                abs_res_32[i]  = abs_vs2_32[i] / abs_vs1_32[i];

                case (op_i)
                    OPM_VDIVU: result_o.i32b[i] = (vs1_i.i32b[i] == '0) ? '1 :
                                                    vs2_i.i32b[i] / vs1_i.i32b[i];
                    OPM_VDIV:  result_o.i32b[i] = (vs1_i.i32b[i] == '0) ? '1 :
                                                    sign_res_32[i] ? (~abs_res_32[i] + 1) : abs_res_32[i];
                    OPM_VREMU: result_o.i32b[i] = (vs1_i.i32b[i] == '0) ? vs2_i.i32b[i] :
                                                    vs2_i.i32b[i] % vs1_i.i32b[i];
                    OPM_VREM:  result_o.i32b[i] = (vs1_i.i32b[i] == '0) ? vs2_i.i32b[i] :
                                                    sign_vs2_32[i] ? (~(abs_vs2_32[i] % abs_vs1_32[i]) + 1) :
                                                                      (abs_vs2_32[i] % abs_vs1_32[i]);
                    default:   result_o.i32b[i] = '0;
                endcase
            end
        end

        SEW64: begin
            for (int i = 0; i < 2; i++) begin
                sign_vs2_64[i] = vs2_i.i64b[i][63];
                sign_vs1_64[i] = vs1_i.i64b[i][63];
                sign_res_64[i] = sign_vs2_64[i] ^ sign_vs1_64[i];
                abs_vs2_64[i]  = sign_vs2_64[i] ? (~vs2_i.i64b[i] + 1) : vs2_i.i64b[i];
                abs_vs1_64[i]  = sign_vs1_64[i] ? (~vs1_i.i64b[i] + 1) : vs1_i.i64b[i];
                abs_res_64[i]  = abs_vs2_64[i] / abs_vs1_64[i];

                case (op_i)
                    OPM_VDIVU: result_o.i64b[i] = (vs1_i.i64b[i] == '0) ? '1 :
                                                    vs2_i.i64b[i] / vs1_i.i64b[i];
                    OPM_VDIV:  result_o.i64b[i] = (vs1_i.i64b[i] == '0) ? '1 :
                                                    sign_res_64[i] ? (~abs_res_64[i] + 1) : abs_res_64[i];
                    OPM_VREMU: result_o.i64b[i] = (vs1_i.i64b[i] == '0) ? vs2_i.i64b[i] :
                                                    vs2_i.i64b[i] % vs1_i.i64b[i];
                    OPM_VREM:  result_o.i64b[i] = (vs1_i.i64b[i] == '0) ? vs2_i.i64b[i] :
                                                    sign_vs2_64[i] ? (~(abs_vs2_64[i] % abs_vs1_64[i]) + 1) :
                                                                      (abs_vs2_64[i] % abs_vs1_64[i]);
                    default:   result_o.i64b[i] = '0;
                endcase
            end
        end

        default: result_o = '0;

    endcase
end

endmodule