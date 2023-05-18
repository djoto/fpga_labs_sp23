module counter (
  input clk,
  input ce,
  output [3:0] LEDS
);
    // TODO: delete this assignment once you write your own logic.
    //assign LEDS = 4'd0;


    // TODO: Instantiate a register (from the 151 library) to count the number of cycles
    // required to reach one second. Note that our clock period is 8ns.
    // Think about how many bits are needed for your register.

    //Parameters for increment every 1s: 
    parameter MAX_CYCLES_WIDTH = 27;
    parameter MAX_CYCLES = 27'd125000000;
    parameter CYCLES_INCREMENT_VAL = 27'd1;

    //Parameters for increment every 1ms (added in order to speed up simulation) 
    //parameter MAX_CYCLES_WIDTH = 17;
    //parameter MAX_CYCLES = 17'd125000;
    //parameter CYCLES_INCREMENT_VAL = 17'd1;

    wire [MAX_CYCLES_WIDTH-1:0] cycle_count;
    wire [MAX_CYCLES_WIDTH-1:0] cycles_temp;
    assign cycles_temp = cycle_count == MAX_CYCLES 
		? {MAX_CYCLES_WIDTH{1'b0}} 
		: cycle_count + CYCLES_INCREMENT_VAL;

    REGISTER #(.N(MAX_CYCLES_WIDTH)) cycle_counter(cycle_count, cycles_temp, clk);


    // TODO: Instantiate a register to hold the current count,
    // and assign this value to the LEDS.
    // TODO: update the register if clock is enabled (ce is 1).
    // Once the requisite number of cycles is reached, increment the count.

    wire [3:0] count;
    assign count = cycle_count == MAX_CYCLES
		? LEDS == 4'b1111
			? 4'b0
			: LEDS + 4'b1
		: LEDS;

    REGISTER_CE #(.N(4)) current_count(LEDS, count, ce, clk);

endmodule

