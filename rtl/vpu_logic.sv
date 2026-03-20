import vpu_pkg::*;

module vpu_logic (
    input  vector_t     vs1_i,
    input  vector_t     vs2_i,
    input  sew_t        sew_i,
    input  funct6_opi_t op_i,
    output vector_t     result_o
);

always_comb begin
    result_o = '0;

    case (op_i)

        // ---- Lógica bit a bit (no dependen del SEW) ----
        OPI_VAND:  result_o.i128b = vs1_i.i128b & vs2_i.i128b;
        OPI_VOR:   result_o.i128b = vs1_i.i128b | vs2_i.i128b;
        OPI_VXOR:  result_o.i128b = vs1_i.i128b ^ vs2_i.i128b;

        // ---- Shifts (dependen del SEW) ----
        OPI_VSLL,           //mult por 2
        OPI_VSRL,           //div por 2
        OPI_VSRA: begin     //div por 2 con signo
            case (sew_i)

                SEW8: begin
                    for (int i = 0; i < 16; i++) begin
                        case (op_i)
                            OPI_VSLL: result_o.i8b[i] = vs2_i.i8b[i] << vs1_i.i8b[i][2:0];
                            OPI_VSRL: result_o.i8b[i] = vs2_i.i8b[i] >> vs1_i.i8b[i][2:0];
                            OPI_VSRA: result_o.i8b[i] = signed'(vs2_i.i8b[i]) >>> vs1_i.i8b[i][2:0];
                            default:  result_o.i8b[i] = '0;
                        endcase
                    end
                end

                SEW16: begin
                    for (int i = 0; i < 8; i++) begin
                        case (op_i)
                            OPI_VSLL: result_o.i16b[i] = vs2_i.i16b[i] << vs1_i.i16b[i][3:0];
                            OPI_VSRL: result_o.i16b[i] = vs2_i.i16b[i] >> vs1_i.i16b[i][3:0];
                            OPI_VSRA: result_o.i16b[i] = signed'(vs2_i.i16b[i]) >>> vs1_i.i16b[i][3:0];
                            default:  result_o.i16b[i] = '0;
                        endcase
                    end
                end

                SEW32: begin
                    for (int i = 0; i < 4; i++) begin
                        case (op_i)
                            OPI_VSLL: result_o.i32b[i] = vs2_i.i32b[i] << vs1_i.i32b[i][4:0];
                            OPI_VSRL: result_o.i32b[i] = vs2_i.i32b[i] >> vs1_i.i32b[i][4:0];
                            OPI_VSRA: result_o.i32b[i] = signed'(vs2_i.i32b[i]) >>> vs1_i.i32b[i][4:0];
                            default:  result_o.i32b[i] = '0;
                        endcase
                    end
                end

                SEW64: begin
                    for (int i = 0; i < 2; i++) begin
                        case (op_i)
                            OPI_VSLL: result_o.i64b[i] = vs2_i.i64b[i] << vs1_i.i64b[i][5:0];
                            OPI_VSRL: result_o.i64b[i] = vs2_i.i64b[i] >> vs1_i.i64b[i][5:0];
                            OPI_VSRA: result_o.i64b[i] = signed'(vs2_i.i64b[i]) >>> vs1_i.i64b[i][5:0];
                            default:  result_o.i64b[i] = '0;
                        endcase
                    end
                end

                default: result_o = '0;

            endcase
        end

        default: result_o = '0;

    endcase
end

endmodule