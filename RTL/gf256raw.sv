    module gfraw #(parameter WIDTH = 256) (
        input  logic [WIDTH-1:0]   a, b,
        output logic [2*WIDTH-2:0] y
    );

        generate
            if (WIDTH == 2) begin : base
                gf2raw base_mult (.a(a), .b(b), .y(y));
            end else begin : rec
                localparam H = WIDTH/2;
                logic [H-1:0] a_h, a_l, b_h, b_l;
                assign a_h = a[WIDTH-1:H];
                assign a_l = a[H-1:0];
                assign b_h = b[WIDTH-1:H];
                assign b_l = b[H-1:0];
                logic [WIDTH-2:0] P0, P1, P2;

                gfraw #(H) p0(.a(a_h),       .b(b_h),       .y(P0));
                gfraw #(H) p1(.a(a_l),       .b(b_l),       .y(P1));
                gfraw #(H) p2(.a(a_h^a_l),   .b(b_h^b_l),   .y(P2));

                assign y = (P0 << WIDTH) ^ ((P0^P1^P2) << H) ^ P1;
            end
        endgenerate

    endmodule