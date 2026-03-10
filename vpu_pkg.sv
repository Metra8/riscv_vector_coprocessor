package vpu_pkg;

parameter VLEN = 128;   //registro vectorial 128 bits
parameter XLEN = 32;    //32 registros x31-x0

//tamaños SEW
typedef union packed {
    logic [127:0]       i128b;
    logic [1:0][63:0]   i64b;
    logic [3:0][31:0]   i32b;
    logic [7:0][15:0]   i16b;
    logic [15:0][7:0]   i8b;
} vector_t;

//tipos de SEW
typedef enum logic [1:0] {
    SEW8  = 2'b00,
    SEW16 = 2'b01,
    SEW32 = 2'b10,
    SEW64 = 2'b11
} sew_t;

//operaciones ALU vectorial
//vector-vector         vector-scalar           vector-inmediate
//suma de vectores      sumar un único número   como vx pero solo puede
//                      a los elementos         usar números entre
//                      de un vector            -16 y +15
//
//viene de un registro  viene de un registro    indicado en la instrucción

//OPI = Opcode Integer Inmediate    OPM = Opcode Integer Multi-vector/Misc
//OPI se suele reservar para sumas/restas/lógica y OPM para multiplicaciones/reducciones/máscaras

//Grupo OPI — usado con funct3 = OPIVV, OPIVX, OPIVI
typedef enum logic [5:0] {
    // Aritmética
    OPI_VADD   = 6'b000000,  // vadd.vv  / vadd.vx  / vadd.vi
    OPI_VSUB   = 6'b000010,  // vsub.vv  / vsub.vx
    OPI_VRSUB  = 6'b000011,  // vrsub.vx / vrsub.vi
    OPI_VMINU  = 6'b000100,  // vminu.vv / vminu.vx
    OPI_VMIN   = 6'b000101,  // vmin.vv  / vmin.vx
    OPI_VMAXU  = 6'b000110,  // vmaxu.vv / vmaxu.vx
    OPI_VMAX   = 6'b000111,  // vmax.vv  / vmax.vx
    // Lógica
    OPI_VAND   = 6'b001001,  // vand.vv  / vand.vx  / vand.vi
    OPI_VOR    = 6'b001010,  // vor.vv   / vor.vx   / vor.vi
    OPI_VXOR   = 6'b001011,  // vxor.vv  / vxor.vx  / vxor.vi
    // Shifts
    OPI_VSLL   = 6'b100101,  // vsll.vv  / vsll.vx  / vsll.vi
    OPI_VSRL   = 6'b101000,  // vsrl.vv  / vsrl.vx  / vsrl.vi
    OPI_VSRA   = 6'b101001,  // vsra.vv  / vsra.vx  / vsra.vi
    // Comparaciones
    OPI_VMSEQ  = 6'b011000,  // vmseq.vv / vmseq.vx / vmseq.vi
    OPI_VMSNE  = 6'b011001,  // vmsne.vv / vmsne.vx / vmsne.vi
    OPI_VMSLTU = 6'b011010,  // vmsltu.vv / vmsltu.vx
    OPI_VMSLT  = 6'b011011,  // vmslt.vv  / vmslt.vx
    OPI_VMSLEU = 6'b011100,  // vmsleu.vv / vmsleu.vx / vmsleu.vi
    OPI_VMSLE  = 6'b011101,  // vmsle.vv  / vmsle.vx  / vmsle.vi
    OPI_VMSGTU = 6'b011110,  // vmsgtu.vx / vmsgtu.vi
    OPI_VMSGT  = 6'b011111   // vmsgt.vx  / vmsgt.vi
} funct6_opi_t;

// Grupo OPM — usado con funct3 = OPMVV, OPMVX
typedef enum logic [5:0] {
    // Multiplicación
    OPM_VMULHU = 6'b100100,  // vmulhu.vv / vmulhu.vx
    OPM_VMUL   = 6'b100101,  // vmul.vv   / vmul.vx
    OPM_VMULHSU= 6'b100110,  // vmulhsu.vv / vmulhsu.vx
    OPM_VMULH  = 6'b100111,  // vmulh.vv  / vmulh.vx
    OPM_VDIVU  = 6'b100000,  // vdivu.vv  / vdivu.vx
    OPM_VDIV   = 6'b100001,  // vdiv.vv   / vdiv.vx
    OPM_VREMU  = 6'b100010,  // vremu.vv  / vremu.vx
    OPM_VREM   = 6'b100011   // vrem.vv   / vrem.vx
} funct6_opm_t;


typedef enum logic [2:0] {
    OPIVV = 3'b000,   // vv entero
    OPIVX = 3'b100,   // vx entero
    OPIVI = 3'b011,   // vi entero
    OPMVV = 3'b010,   // vv (mul/div)
    OPMVX = 3'b110    // vx (mul/div)
} funct3_t;

endpackage