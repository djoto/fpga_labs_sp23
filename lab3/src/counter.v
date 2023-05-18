module counter #(
    parameter CYCLES_PER_SECOND = 125_000_000
)(
    input clk,
    input [3:0] buttons,
    output [3:0] leds
);
    wire [3:0] count;
    reg [3:0] d;
    assign leds = count;

    parameter MAX_CYCLES_WIDTH = $clog2(CYCLES_PER_SECOND);

    localparam RUNNING = 2'b01;
    localparam STATIC = 2'b10;
    reg [1:0] state;
    reg [1:0] next_state;
    initial state = STATIC;
    always @(posedge clk)
        state <= next_state;




    always @(*) begin
        if (buttons[2] && state==STATIC)
            next_state = RUNNING;
        else if (~buttons[2] && state==RUNNING)
            next_state = RUNNING;
        else
            next_state = STATIC;
    end




    wire [MAX_CYCLES_WIDTH-1:0] cycle_count;
    wire [MAX_CYCLES_WIDTH-1:0] cycles_temp;
    assign cycles_temp = cycle_count == CYCLES_PER_SECOND 
		? {MAX_CYCLES_WIDTH{1'b0}} 
		: cycle_count + 1;

    REGISTER #(.N(MAX_CYCLES_WIDTH)) cycle_counter(cycle_count, cycles_temp, clk);

    wire [3:0] cnt;
    //wire [3:0] count1;
    assign cnt = cycle_count == CYCLES_PER_SECOND
		? count == 4'b1111
			? 4'b0
			: count + 4'b1
		: count;

    //REGISTER #(.N(4)) current_count(count1, cnt, clk);


    always @(*) begin
        if (state==STATIC)
            begin
		if (buttons[0])
		    d = count + 4'd1;
		else if (buttons[1])
		    d = count - 4'd1;
		else if (buttons[3])
		    d = 4'd0;
		else
		    d = count;
            end 
        else
            d = cnt;
    end




    REGISTER #(4) counter (.q(count), .d(d), .clk(clk));
endmodule

