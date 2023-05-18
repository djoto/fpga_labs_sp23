module structural_adder (
    input [13:0] a,
    input [13:0] b,
    output [14:0] sum
);

    wire [14:0] carry;
    genvar i;
    
    assign carry[0] = 1'b0;

    generate
	for (i = 0; i < 14; i = i + 1)
	    begin
	         full_adder f_add(a[i],b[i],carry[i],sum[i],carry[i+1]);
	    end
    endgenerate

    assign sum[14] = carry[14];

endmodule
