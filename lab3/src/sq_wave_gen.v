module sq_wave_gen (
    input clk,
    input next_sample,
    output [9:0] code
);

    localparam HALF_PERIOD_SQ_CYCLE = 139;
    localparam WIDTH_PERIOD = $clog2(HALF_PERIOD_SQ_CYCLE);

    wire [WIDTH_PERIOD-1:0] cycle_count;
    wire [WIDTH_PERIOD-1:0] cycles_temp;
    assign cycles_temp = cycle_count == HALF_PERIOD_SQ_CYCLE - 1 
		                     ? {WIDTH_PERIOD{1'b0}}
		                     : next_sample == 1 
					            ? cycle_count + 1
						    : cycle_count;
    REGISTER #(.N(WIDTH_PERIOD)) cycle_counter(cycle_count, cycles_temp, clk);

    wire [9:0] code_temp;
    assign code_temp = cycle_count == HALF_PERIOD_SQ_CYCLE - 1
			      ? code == 562
				      ? 462
				      : 562
			      : code;

    REGISTER #(.N(10)) code_reg(code, code_temp, clk);

    //assign code = 0;
endmodule
