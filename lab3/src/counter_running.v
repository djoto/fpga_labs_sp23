module counter_running #(parameter MAX_CYCLES = 125_000_000)(
  input clk,
  output [3:0] out
  //output [16:0] cycle_countt
);
    // TODO: delete this assignment once you write your own logic.
    //assign out = 4'd0;


    // TODO: Instantiate a register (from the 151 library) to count the number of cycles
    // required to reach one second. Note that our clock period is 8ns.
    // Think about how many bits are needed for your register.

    //Parameters for increment every 1s: 
    parameter MAX_CYCLES_WIDTH = $clog2(MAX_CYCLES);
    //parameter MAX_CYCLES = 27'd12500000;
    //parameter CYCLES_INCREMENT_VAL = 27'd1;

    //Parameters for increment every 1ms (added in order to speed up simulation) 
    //parameter MAX_CYCLES_WIDTH = 17;
   //parameter MAX_CYCLES = 17'd125000;
    //parameter CYCLES_INCREMENT_VAL = 17'd1;

    wire [MAX_CYCLES_WIDTH-1:0] cycle_count;
    wire [MAX_CYCLES_WIDTH-1:0] cycles_temp;
    assign cycles_temp = cycle_count == MAX_CYCLES 
		? {MAX_CYCLES_WIDTH{1'b0}} 
		: cycle_count + 1;

    REGISTER #(.N(MAX_CYCLES_WIDTH)) cycle_counter(cycle_count, cycles_temp, clk);


    // TODO: Instantiate a register to hold the current count,
    // and assign this value to the out.
    // TODO: update the register if clock is enabled (ce is 1).
    // Once the requisite number of cycles is reached, increment the count.

    wire [3:0] count;
    assign count = cycle_count == MAX_CYCLES
		? out == 4'b1111
			? 4'b0
			: out + 4'b1
		: out;

    REGISTER #(.N(4)) current_count(out, count, clk);


/*
    reg [N-1:0] cycle_count;
    initial cycle_count = {N{1'b0}};
    always @(posedge clk)
        if (cycle_count == MAX_CYCLES)
            cycle_count <= {N{1'b0}};
        else
            cycle_count <= cycle_count + INCREMENT_VAL;

    //REGISTER #(.N(N)) counter_reg(cycle_countt, cycle_count, clk);

    wire ce1;
    assign ce1 = cycle_count == MAX_CYCLES;

    reg [3:0] q;
    initial q = 4'b0;
    always @(posedge clk)
        if (ce1)
            q <= q + 4'b1;
        //q <= cycle_count == MAX_CYCLES ? q + 4'b1 : q;

    REGISTER_CE #(.N(4)) counter_ce_reg(out, q, ce, clk);
*/


endmodule

