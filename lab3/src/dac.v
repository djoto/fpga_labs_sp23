module dac #(
    parameter CYCLES_PER_WINDOW = 1024,
    parameter CODE_WIDTH = $clog2(CYCLES_PER_WINDOW)
)(
    input clk,
    input [CODE_WIDTH-1:0] code,
    output next_sample,
    output pwm
);

    wire [CODE_WIDTH-1:0] cycle_count;
    wire [CODE_WIDTH-1:0] cycles_temp;
    assign cycles_temp = cycle_count == CYCLES_PER_WINDOW - 1 
		                     ? {CODE_WIDTH{1'b0}}
		                     : cycle_count + 1;

    REGISTER #(.N(CODE_WIDTH)) cycle_counter(cycle_count, cycles_temp, clk);

    wire [CODE_WIDTH-1:0] code_delayed;
    wire [CODE_WIDTH-1:0] code_delayed_two;
    REGISTER #(.N(CODE_WIDTH)) code_delay(code_delayed, code, clk);
    REGISTER #(.N(CODE_WIDTH)) code_delay_for_two(code_delayed_two, code_delayed, clk);

    assign pwm = cycle_count < code
		             ? 1
			     : 0;


    //assign pwm = 0;
    //assign next_sample = 0;

    assign next_sample = cycle_count == CYCLES_PER_WINDOW - 1
                                         ? 1
        				 : 0;

endmodule