import vpu_pkg::*;

module vpu_compare (
    input  vector_t      vs1_i,
    input  vector_t      vs2_i,
    input  sew_t         sew_i,
    input  funct6_opi_t  op_i,
    output logic [15:0]  result_o  // 1 bit por elemento
);

always_comb begin
    result_o = '0;
    case (sew_i)

        SEW8: begin
            for (int i = 0; i < 16; i++) begin
                case (op_i)
                    OPI_VMSEQ:  result_o[i] = (vs2_i.i8b[i] == vs1_i.i8b[i]);
                    OPI_VMSNE:  result_o[i] = (vs2_i.i8b[i] != vs1_i.i8b[i]);
                    OPI_VMSLTU: result_o[i] = (vs2_i.i8b[i] <  vs1_i.i8b[i]);
                    OPI_VMSLT:  result_o[i] = signed'(vs2_i.i8b[i]) <  signed'(vs1_i.i8b[i]);
                    OPI_VMSLEU: result_o[i] = (vs2_i.i8b[i] <= vs1_i.i8b[i]);
                    OPI_VMSLE:  result_o[i] = signed'(vs2_i.i8b[i]) <= signed'(vs1_i.i8b[i]);
                    OPI_VMSGTU: result_o[i] = (vs2_i.i8b[i] >  vs1_i.i8b[i]);
                    OPI_VMSGT:  result_o[i] = signed'(vs2_i.i8b[i]) >  signed'(vs1_i.i8b[i]);
                    default:    result_o[i] = '0;
                endcase
            end
        end

        SEW16: begin
            for (int i = 0; i < 8; i++) begin
                case (op_i)
                    OPI_VMSEQ:  result_o[i] = (vs2_i.i16b[i] == vs1_i.i16b[i]);
                    OPI_VMSNE:  result_o[i] = (vs2_i.i16b[i] != vs1_i.i16b[i]);
                    OPI_VMSLTU: result_o[i] = (vs2_i.i16b[i] <  vs1_i.i16b[i]);
                    OPI_VMSLT:  result_o[i] = signed'(vs2_i.i16b[i]) <  signed'(vs1_i.i16b[i]);
                    OPI_VMSLEU: result_o[i] = (vs2_i.i16b[i] <= vs1_i.i16b[i]);
                    OPI_VMSLE:  result_o[i] = signed'(vs2_i.i16b[i]) <= signed'(vs1_i.i16b[i]);
                    OPI_VMSGTU: result_o[i] = (vs2_i.i16b[i] >  vs1_i.i16b[i]);
                    OPI_VMSGT:  result_o[i] = signed'(vs2_i.i16b[i]) >  signed'(vs1_i.i16b[i]);
                    default:    result_o[i] = '0;
                endcase
            end
        end

        SEW32: begin
            for (int i = 0; i < 4; i++) begin
                case (op_i)
                    OPI_VMSEQ:  result_o[i] = (vs2_i.i32b[i] == vs1_i.i32b[i]);
                    OPI_VMSNE:  result_o[i] = (vs2_i.i32b[i] != vs1_i.i32b[i]);
                    OPI_VMSLTU: result_o[i] = (vs2_i.i32b[i] <  vs1_i.i32b[i]);
                    OPI_VMSLT:  result_o[i] = signed'(vs2_i.i32b[i]) <  signed'(vs1_i.i32b[i]);
                    OPI_VMSLEU: result_o[i] = (vs2_i.i32b[i] <= vs1_i.i32b[i]);
                    OPI_VMSLE:  result_o[i] = signed'(vs2_i.i32b[i]) <= signed'(vs1_i.i32b[i]);
                    OPI_VMSGTU: result_o[i] = (vs2_i.i32b[i] >  vs1_i.i32b[i]);
                    OPI_VMSGT:  result_o[i] = signed'(vs2_i.i32b[i]) >  signed'(vs1_i.i32b[i]);
                    default:    result_o[i] = '0;
                endcase
            end
        end

        SEW64: begin
            for (int i = 0; i < 2; i++) begin
                case (op_i)
                    OPI_VMSEQ:  result_o[i] = (vs2_i.i64b[i] == vs1_i.i64b[i]);
                    OPI_VMSNE:  result_o[i] = (vs2_i.i64b[i] != vs1_i.i64b[i]);
                    OPI_VMSLTU: result_o[i] = (vs2_i.i64b[i] <  vs1_i.i64b[i]);
                    OPI_VMSLT:  result_o[i] = signed'(vs2_i.i64b[i]) <  signed'(vs1_i.i64b[i]);
                    OPI_VMSLEU: result_o[i] = (vs2_i.i64b[i] <= vs1_i.i64b[i]);
                    OPI_VMSLE:  result_o[i] = signed'(vs2_i.i64b[i]) <= signed'(vs1_i.i64b[i]);
                    OPI_VMSGTU: result_o[i] = (vs2_i.i64b[i] >  vs1_i.i64b[i]);
                    OPI_VMSGT:  result_o[i] = signed'(vs2_i.i64b[i]) >  signed'(vs1_i.i64b[i]);
                    default:    result_o[i] = '0;
                endcase
            end
        end

        default: result_o = '0;

    endcase
end

endmodule