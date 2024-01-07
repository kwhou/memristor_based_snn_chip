
module ICG (
    CP,
    E,
    Q 
);

/* This is only a model for integrated clock gating (ICG) cell.
   Please replace this with the ICG cell provided by the
   standard cell library that you use. */

input CP; // clock
input E;  // enable
output Q; // gated clock

reg E_latch;

always @(CP or E)
    if (~CP)
        E_latch <= E;

assign Q = CP & E_latch;

endmodule

