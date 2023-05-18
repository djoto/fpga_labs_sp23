module full_adder (
    input a,
    input b,
    input carry_in,
    output sum,
    output carry_out
);

    assign sum = a ^ b ^ carry_in;
    assign carry_out = (a && b) || (carry_in && (a ^ b));

    //assign sum = a ^ b ^ carry_in; 
    //assign carry_out = (a && b) || (carry_in && (a || b));
       
    //wire p, q, r;
    //assign p = a ^ b;
    //assign q = a && b;
    //assign r = a || b;
    //assign sum = p ^ carry_in;
    //assign carry_out = q || (carry_in && r);

endmodule
