// vpu_addsub.sv
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
                    OPI_VADD:  result_o.i8[i] = vs1_i.i8[i] + vs2_i.i8[i];
                    OPI_VSUB:  result_o.i8[i] = vs2_i.i8[i] - vs1_i.i8[i];
                    OPI_VRSUB: result_o.i8[i] = vs1_i.i8[i] - vs2_i.i8[i];
                    OPI_VMINU: result_o.i8[i] = (vs1_i.i8[i] < vs2_i.i8[i]) ? vs1_i.i8[i] : vs2_i.i8[i];
                    OPI_VMIN:  result_o.i8[i] = ($signed(vs1_i.i8[i]) < $signed(vs2_i.i8[i])) ? vs1_i.i8[i] : vs2_i.i8[i];
                    OPI_VMAXU: result_o.i8[i] = (vs1_i.i8[i] > vs2_i.i8[i]) ? vs1_i.i8[i] : vs2_i.i8[i];
                    OPI_VMAX:  result_o.i8[i] = ($signed(vs1_i.i8[i]) > $signed(vs2_i.i8[i])) ? vs1_i.i8[i] : vs2_i.i8[i];
                    default:   result_o.i8[i] = '0;
                endcase
            end
        end

        SEW16: begin
            for (int i = 0; i < 8; i++) begin
                case (op_i)
                    OPI_VADD:  result_o.i16[i] = vs1_i.i16[i] + vs2_i.i16[i];
                    OPI_VSUB:  result_o.i16[i] = vs2_i.i16[i] - vs1_i.i16[i];
                    OPI_VRSUB: result_o.i16[i] = vs1_i.i16[i] - vs2_i.i16[i];
                    OPI_VMINU: result_o.i16[i] = (vs1_i.i16[i] < vs2_i.i16[i]) ? vs1_i.i16[i] : vs2_i.i16[i];
                    OPI_VMIN:  result_o.i16[i] = ($signed(vs1_i.i16[i]) < $signed(vs2_i.i16[i])) ? vs1_i.i16[i] : vs2_i.i16[i];
                    OPI_VMAXU: result_o.i16[i] = (vs1_i.i16[i] > vs2_i.i16[i]) ? vs1_i.i16[i] : vs2_i.i16[i];
                    OPI_VMAX:  result_o.i16[i] = ($signed(vs1_i.i16[i]) > $signed(vs2_i.i16[i])) ? vs1_i.i16[i] : vs2_i.i16[i];
                    default:   result_o.i16[i] = '0;
                endcase
            end
        end

        SEW32: begin
            for (int i = 0; i < 4; i++) begin
                case (op_i)
                    OPI_VADD:  result_o.i32[i] = vs1_i.i32[i] + vs2_i.i32[i];
                    OPI_VSUB:  result_o.i32[i] = vs2_i.i32[i] - vs1_i.i32[i];
                    OPI_VRSUB: result_o.i32[i] = vs1_i.i32[i] - vs2_i.i32[i];
                    OPI_VMINU: result_o.i32[i] = (vs1_i.i32[i] < vs2_i.i32[i]) ? vs1_i.i32[i] : vs2_i.i32[i];
                    OPI_VMIN:  result_o.i32[i] = ($signed(vs1_i.i32[i]) < $signed(vs2_i.i32[i])) ? vs1_i.i32[i] : vs2_i.i32[i];
                    OPI_VMAXU: result_o.i32[i] = (vs1_i.i32[i] > vs2_i.i32[i]) ? vs1_i.i32[i] : vs2_i.i32[i];
                    OPI_VMAX:  result_o.i32[i] = ($signed(vs1_i.i32[i]) > $signed(vs2_i.i32[i])) ? vs1_i.i32[i] : vs2_i.i32[i];
                    default:   result_o.i32[i] = '0;
                endcase
            end
        end

        SEW64: begin
            for (int i = 0; i < 2; i++) begin
                case (op_i)
                    OPI_VADD:  result_o.i64[i] = vs1_i.i64[i] + vs2_i.i64[i];
                    OPI_VSUB:  result_o.i64[i] = vs2_i.i64[i] - vs1_i.i64[i];
                    OPI_VRSUB: result_o.i64[i] = vs1_i.i64[i] - vs2_i.i64[i];
                    OPI_VMINU: result_o.i64[i] = (vs1_i.i64[i] < vs2_i.i64[i]) ? vs1_i.i64[i] : vs2_i.i64[i];
                    OPI_VMIN:  result_o.i64[i] = ($signed(vs1_i.i64[i]) < $signed(vs2_i.i64[i])) ? vs1_i.i64[i] : vs2_i.i64[i];
                    OPI_VMAXU: result_o.i64[i] = (vs1_i.i64[i] > vs2_i.i64[i]) ? vs1_i.i64[i] : vs2_i.i64[i];
                    OPI_VMAX:  result_o.i64[i] = ($signed(vs1_i.i64[i]) > $signed(vs2_i.i64[i])) ? vs1_i.i64[i] : vs2_i.i64[i];
                    default:   result_o.i64[i] = '0;
                endcase
            end
        end

    endcase
end

endmodule