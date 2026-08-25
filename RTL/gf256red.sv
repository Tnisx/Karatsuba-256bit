module gf256red(
    input  logic [510:0] raw,
    output logic [255:0] x
);
localparam logic [510:0] POLY = 11'b10000100101;
integer i;
logic [510:0] acc;

always_comb begin
    acc = raw;
    for(i=510;i>=256;i=i-1)begin
        if(acc[i])begin
            acc[i]=1'b0;
            acc=acc^(POLY<<(i-256));
        end
    end
end

assign x = acc[255:0];
endmodule