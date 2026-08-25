module gf2raw(
    input [1:0] a,b,
    output [3:0] y
);
logic [2:0] yout;

always_comb begin
    yout=0;
    if(b[0])yout=yout^(a<<0);
    if(b[1])yout=yout^(a<<1);
end
assign y = yout;
endmodule
