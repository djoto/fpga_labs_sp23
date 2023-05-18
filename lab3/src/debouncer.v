module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);
    // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
    // Some initial code has been provided to you, but feel free to change it however you like
    // One wrapping counter is required
    // One saturating counter is needed for each bit of glitchy_signal
    // You need to think of the conditions for reseting, clock enable, etc. those registers
    // Refer to the block diagram in the spec

    //Synchronizer
    //wire [WIDTH-1:0] sync_signal;
    //synchronizer #(.WIDTH(WIDTH)) synch(glitchy_signal, clk, sync_signal);


    //Sample Pulse Generator:
    wire [WRAPPING_CNT_WIDTH-1:0] cycle_count;
    wire [WRAPPING_CNT_WIDTH-1:0] cycles_temp;
    assign cycles_temp = cycle_count == SAMPLE_CNT_MAX 
		? {WRAPPING_CNT_WIDTH{1'b0}} 
		: cycle_count + 1;

    REGISTER #(.N(WRAPPING_CNT_WIDTH)) reg_cycle_counter(cycle_count, cycles_temp, clk);    

    wire is_sample_max;
    assign is_sample_max = cycle_count == SAMPLE_CNT_MAX ? 1 : 0;

    //Debouncer:
    wire [WIDTH-1:0] en;
    wire [WIDTH-1:0] rst;
    wire [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];
    wire [SAT_CNT_WIDTH-1:0] saturating_counter_temp [WIDTH-1:0];
    genvar i;
    generate
	for (i = 0; i < WIDTH; i = i + 1)
	    begin
                 assign en[i] = is_sample_max & glitchy_signal[i];
                 assign rst[i] = ~glitchy_signal[i];
		// initial saturating_counter[i] = {SAT_CNT_WIDTH{1'b0}};
		// initial saturating_counter_temp[i] = {SAT_CNT_WIDTH{1'b0}};
                 assign debounced_signal[i] = saturating_counter[i] == PULSE_CNT_MAX;

	         assign saturating_counter_temp[i] = en[i]
			                 ? debounced_signal[i]
				             ? saturating_counter[i]
				             : saturating_counter[i] + 1
			                 : saturating_counter[i];

	         REGISTER_R #(.N(SAT_CNT_WIDTH)) reg_debouncer(saturating_counter[i], saturating_counter_temp[i], rst[i], clk);

	    end
    endgenerate

    // Remove this line once you have created your debouncer
    //assign debounced_signal = 0;

    //wire [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];
endmodule
