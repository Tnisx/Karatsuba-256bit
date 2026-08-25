module top (
    input logic[255:0] ina,
    input logic[255:0] inb,
   output logic[255:0] out
);
//Logics
logic [510:0] raw;
logic [255:0] x;//output
//Module Assignment
gfraw topraw(
    .a(ina),
    .b(inb),
    .y(raw)
);
gf256red topred(
    .raw(raw),
    .x(x)
);

assign out = x;
endmodule

