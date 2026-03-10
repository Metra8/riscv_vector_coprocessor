import vpu_pkg::*;

module vpu_addsub (
    input  vector_t     vs1_i,
    input  vector_t     vs2_i,
    input  sew_t        sew_i,
    input  funct6_opi_t op_i,
    output vector_t     result_o
);

always_comb begin
    result_o = '0;
    case (sew_i)

        SEW8: begin
            for (int i = 0; i < 16; i++) begin
                case (op_i)
                    OPI_VADD:  result_o.i8b[i] = vs1_i.i8b[i] + vs2_i.i8b[i];
                    OPI_VSUB:  result_o.i8b[i] = vs2_i.i8b[i] - vs1_i.i8b[i];
                    OPI_VRSUB: result_o.i8b[i] = vs1_i.i8b[i] - vs2_i.i8b[i];
                    OPI_VMINU: result_o.i8b[i] = (vs1_i.i8b[i] < vs2_i.i8b[i]) ? vs1_i.i8b[i] : vs2_i.i8b[i];
                    OPI_VMIN:  result_o.i8b[i] = ($signed(vs1_i.i8b[i]) < $signed(vs2_i.i8b[i])) ? vs1_i.i8b[i] : vs2_i.i8b[i];
                    OPI_VMAXU: result_o.i8b[i] = (vs1_i.i8b[i] > vs2_i.i8b[i]) ? vs1_i.i8b[i] : vs2_i.i8b[i];
                    OPI_VMAX:  result_o.i8b[i] = ($signed(vs1_i.i8b[i]) > $signed(vs2_i.i8b[i])) ? vs1_i.i8b[i] : vs2_i.i8b[i];
                    default:   result_o.i8b[i] = '0;
                endcase
            end
        end

        SEW16: begin
            for (int i = 0; i < 8; i++) begin
                case (op_i)
                    OPI_VADD:  result_o.i16b[i] = vs1_i.i16b[i] + vs2_i.i16b[i];
                    OPI_VSUB:  result_o.i16b[i] = vs2_i.i16b[i] - vs1_i.i16b[i];
                    OPI_VRSUB: result_o.i16b[i] = vs1_i.i16b[i] - vs2_i.i16b[i];
                    OPI_VMINU: result_o.i16b[i] = (vs1_i.i16b[i] < vs2_i.i16b[i]) ? vs1_i.i16b[i] : vs2_i.i16b[i];
                    OPI_VMIN:  result_o.i16b[i] = ($signed(vs1_i.i16b[i]) < $signed(vs2_i.i16b[i])) ? vs1_i.i16b[i] : vs2_i.i16b[i];
                    OPI_VMAXU: result_o.i16b[i] = (vs1_i.i16b[i] > vs2_i.i16b[i]) ? vs1_i.i16b[i] : vs2_i.i16b[i];
                    OPI_VMAX:  result_o.i16b[i] = ($signed(vs1_i.i16b[i]) > $signed(vs2_i.i16b[i])) ? vs1_i.i16b[i] : vs2_i.i16b[i];
                    default:   result_o.i16b[i] = '0;
                endcase
            end
        end

        SEW32: begin
            for (int i = 0; i < 4; i++) begin
                case (op_i)
                    OPI_VADD:  result_o.i32b[i] = vs1_i.i32b[i] + vs2_i.i32b[i];
                    OPI_VSUB:  result_o.i32b[i] = vs2_i.i32b[i] - vs1_i.i32b[i];
                    OPI_VRSUB: result_o.i32b[i] = vs1_i.i32b[i] - vs2_i.i32b[i];
                    OPI_VMINU: result_o.i32b[i] = (vs1_i.i32b[i] < vs2_i.i32b[i]) ? vs1_i.i32b[i] : vs2_i.i32b[i];
                    OPI_VMIN:  result_o.i32b[i] = ($signed(vs1_i.i32b[i]) < $signed(vs2_i.i32b[i])) ? vs1_i.i32b[i] : vs2_i.i32b[i];
                    OPI_VMAXU: result_o.i32b[i] = (vs1_i.i32b[i] > vs2_i.i32b[i]) ? vs1_i.i32b[i] : vs2_i.i32b[i];
                    OPI_VMAX:  result_o.i32b[i] = ($signed(vs1_i.i32b[i]) > $signed(vs2_i.i32b[i])) ? vs1_i.i32b[i] : vs2_i.i32b[i];
                    default:   result_o.i32b[i] = '0;
                endcase
            end
        end

        SEW64: begin
            for (int i = 0; i < 2; i++) begin
                case (op_i)
                    OPI_VADD:  result_o.i64b[i] = vs1_i.i64b[i] + vs2_i.i64b[i];
                    OPI_VSUB:  result_o.i64b[i] = vs2_i.i64b[i] - vs1_i.i64b[i];
                    OPI_VRSUB: result_o.i64b[i] = vs1_i.i64b[i] - vs2_i.i64b[i];
                    OPI_VMINU: result_o.i64b[i] = (vs1_i.i64b[i] < vs2_i.i64b[i]) ? vs1_i.i64b[i] : vs2_i.i64b[i];
                    OPI_VMIN:  result_o.i64b[i] = ($signed(vs1_i.i64b[i]) < $signed(vs2_i.i64b[i])) ? vs1_i.i64b[i] : vs2_i.i64b[i];
                    OPI_VMAXU: result_o.i64b[i] = (vs1_i.i64b[i] > vs2_i.i64b[i]) ? vs1_i.i64b[i] : vs2_i.i64b[i];
                    OPI_VMAX:  result_o.i64b[i] = ($signed(vs1_i.i64b[i]) > $signed(vs2_i.i64b[i])) ? vs1_i.i64b[i] : vs2_i.i64b[i];
                    default:   result_o.i64b[i] = '0;
                endcase
            end
        end

    endcase
end

endmodule