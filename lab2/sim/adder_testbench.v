`timescale 1ns/1ns

`define SECOND 1000000000
`define MS 1000000

module adder_testbench();
    reg [13:0] a;
    reg [13:0] b;
    wire [14:0] sum;

    integer ai, bi;
    integer a_r, b_r;

    structural_adder sa (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("adder_testbench.fst");
            $dumpvars(0, adder_testbench);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        a = 14'd1;
        b = 14'd1;
        #(2);
        assert(sum == 15'd2);

        a = 14'd0;
        b = 14'd1;
        #(2);
        assert(sum == 15'd1) else $display("ERROR: Expected sum to be 1, actual value: %d", sum);

        a = 14'd10;
        b = 14'd10;
        #(2);
        if (sum != 15'd20) begin
            $error("Expected sum to be 20, a: %d, b: %d, actual value: %d", a, b, sum);
            $fatal(1);
        end

	// Exhaustive testing
	for (ai = 0; ai < 1024; ai = ai + 1) begin
	    for (bi = 0; bi < 1024; bi = bi + 1) begin
	        a = ai;
	        b = bi;
	        // delay + assert
	        #(2);
	        assert(sum == ai+bi) else $display("Error: Expected sum to be %d, actual value: %d", ai+bi, sum);
	    end
	end

	// Random testing
	for (ai = 0; ai < 1_000_000; ai = ai + 1) begin
	    a_r = $urandom() % (2 ** 14);
	    b_r = $urandom() % (2 ** 14);
	    a = a_r;
	    b = b_r;
	    // delay + assert
	    #(2);
	    assert(sum == a_r+b_r) else $display("Error: Expected sum to be %d, actual value: %d", a_r+b_r, sum);
	end

        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule
