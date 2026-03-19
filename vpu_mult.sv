import vpu_pkg::*;

module vpu_mult (
    input  vector_t      vs1_i,
    input  vector_t      vs2_i,
    input  sew_t         sew_i,
    input  funct6_opm_t  op_i,
    output vector_t      result_o
);

always_comb begin
    result_o = '0;
    case (sew_i)

        SEW8: begin
            for (int i = 0; i < 16; i++) begin
                logic [15:0] temp_uu; // unsigned x unsigned
                logic [15:0] temp_ss; // signed x signed
                logic [15:0] temp_su; // signed x unsigned

                temp_uu = vs2_i.i8b[i] * vs1_i.i8b[i];
                temp_ss = signed'(vs2_i.i8b[i]) * signed'(vs1_i.i8b[i]);
                temp_su = signed'(vs2_i.i8b[i]) * vs1_i.i8b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i8b[i] = temp_uu[7:0];
                    OPM_VMULHU:  result_o.i8b[i] = temp_uu[15:8];   //high unsigned
                    OPM_VMULH:   result_o.i8b[i] = temp_ss[15:8];   //high signed
                    OPM_VMULHSU: result_o.i8b[i] = temp_su[15:8];   //high signed unsigned
                    default:     result_o.i8b[i] = '0;
                endcase
            end
        end

        SEW16: begin
            for (int i = 0; i < 8; i++) begin
                logic [31:0] temp_uu;
                logic [31:0] temp_ss;
                logic [31:0] temp_su;

                temp_uu = vs2_i.i16b[i] * vs1_i.i16b[i];
                temp_ss = signed'(vs2_i.i16b[i]) * signed'(vs1_i.i16b[i]);
                temp_su = signed'(vs2_i.i16b[i]) * vs1_i.i16b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i16b[i] = temp_uu[15:0];
                    OPM_VMULHU:  result_o.i16b[i] = temp_uu[31:16];
                    OPM_VMULH:   result_o.i16b[i] = temp_ss[31:16];
                    OPM_VMULHSU: result_o.i16b[i] = temp_su[31:16];
                    default:     result_o.i16b[i] = '0;
                endcase
            end
        end

        SEW32: begin
            for (int i = 0; i < 4; i++) begin
                logic [63:0] temp_uu;
                logic [63:0] temp_ss;
                logic [63:0] temp_su;

                temp_uu = vs2_i.i32b[i] * vs1_i.i32b[i];
                temp_ss = signed'(vs2_i.i32b[i]) * signed'(vs1_i.i32b[i]);
                temp_su = signed'(vs2_i.i32b[i]) * vs1_i.i32b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i32b[i] = temp_uu[31:0];
                    OPM_VMULHU:  result_o.i32b[i] = temp_uu[63:32];
                    OPM_VMULH:   result_o.i32b[i] = temp_ss[63:32];
                    OPM_VMULHSU: result_o.i32b[i] = temp_su[63:32];
                    default:     result_o.i32b[i] = '0;
                endcase
            end
        end

        SEW64: begin
            for (int i = 0; i < 2; i++) begin
                logic [127:0] temp_uu;
                logic [127:0] temp_ss;
                logic [127:0] temp_su;

                temp_uu = vs2_i.i64b[i] * vs1_i.i64b[i];
                temp_ss = signed'(vs2_i.i64b[i]) * signed'(vs1_i.i64b[i]);
                temp_su = signed'(vs2_i.i64b[i]) * vs1_i.i64b[i];

                case (op_i)
                    OPM_VMUL:    result_o.i64b[i] = temp_uu[63:0];
                    OPM_VMULHU:  result_o.i64b[i] = temp_uu[127:64];
                    OPM_VMULH:   result_o.i64b[i] = temp_ss[127:64];
                    OPM_VMULHSU: result_o.i64b[i] = temp_su[127:64];
                    default:     result_o.i64b[i] = '0;
                endcase
            end
        end

        default: result_o = '0;

    endcase
end

endmodule