module tb_top;

logic [255:0] ina, inb, out, exp;
localparam logic [255:0] POLY = 256'h425;
integer errors = 0;

top dut(.ina(ina), .inb(inb), .out(out));

function automatic logic [255:0] gfmul(input logic [255:0] a_in, b_in);
    logic [255:0] a, b, p;
    logic carry;
    integer i;
    a = a_in; b = b_in; p = 0;
    for (i = 0; i < 256; i = i + 1) begin
        if (b[0]) p = p ^ a;
        b = b >> 1;
        carry = a[255];
        a = a << 1;
        if (carry) a = a ^ POLY;
    end
    gfmul = p;
endfunction

task automatic check(input logic [255:0] a, b);
    ina = a; inb = b; #1;
    exp = gfmul(a, b);
    if (out !== exp) begin
        errors = errors + 1;
        $display("FAIL a=%h b=%h out=%h exp=%h", a, b, out, exp);
    end
endtask

function automatic logic [255:0] rnd256();
    rnd256 = {$urandom(), $urandom(), $urandom(), $urandom(),
              $urandom(), $urandom(), $urandom(), $urandom()};
endfunction

integer i;
initial begin
    check(256'h0, 256'h0);
    check(256'h1, 256'h1);
    check(256'h1, rnd256());
    check({256{1'b1}}, {256{1'b1}});
    check(256'h1 << 255, 256'h2);
    for (i = 0; i < 500; i = i + 1)
        check(rnd256(), rnd256());

    if (errors == 0) $display("ALL PASS");
    else $display("%0d FAILURES", errors);
    $finish;
end

endmodule