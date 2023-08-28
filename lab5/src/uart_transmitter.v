module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);
    // See diagram in the lab guide
    // 125_000_000 / 115_200 = 1085
    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

    localparam DATA_WIDTH = 4'd8;

    localparam IDLE = 2'd0;
    localparam START = 2'd1;
    localparam DATA = 2'd2;
    localparam STOP = 2'd3;

    reg  [1:0] state_next;
    wire [1:0] state_value;
    reg serial_out_reg;
    reg data_in_ready_reg;
    reg [3:0] bit_count;  // couns up to 8 (DATA_WIDTH)
    reg [7:0] data_in_reg;
    wire [CLOCK_COUNTER_WIDTH-1:0] cycle_count_next;
    wire [CLOCK_COUNTER_WIDTH-1:0] cycle_count;

    REGISTER_R #(.N(2), .INIT(IDLE)) state_reg (
      .clk(clk),
      .rst(reset),
      .d(state_next),
      .q(state_value)
    );

    always @(posedge data_in_valid) begin
        data_in_reg <= data_in;
    end

    always @(*) begin
       state_next = state_value;

       case(state_value)
         IDLE: begin
	   data_in_ready_reg = 1;
	   serial_out_reg = 1;
	   bit_count = 0;
	   if (data_in_valid == 1'b1) begin
	     state_next = START;
	   end
	 end
         START: begin
	   serial_out_reg = 0;  // Start bit
	   data_in_ready_reg = 0;
	   if (cycle_count == SYMBOL_EDGE_TIME - 1) begin
	     state_next = DATA;
	   end
	 end
         DATA: begin
	   serial_out_reg = data_in_reg[bit_count];
	   if (cycle_count == SYMBOL_EDGE_TIME - 1) begin
	     bit_count = bit_count + 1;
	     if (bit_count == DATA_WIDTH) begin
	       bit_count = 0;
	       state_next = STOP;
             end
	   end
	 end
         STOP: begin
	   serial_out_reg = 1;  // Stop bit
	   if (cycle_count == SYMBOL_EDGE_TIME - 1) begin
	     state_next = IDLE;
	   end
	 end
         default: begin
           state_next = IDLE;
	   data_in_ready_reg = 0;
	   serial_out_reg = 1;
	   bit_count = 0;
	 end
       endcase
    end

    assign cycle_count_next = ((state_value == IDLE) | (cycle_count == SYMBOL_EDGE_TIME - 1))
     			    ? 0
    			    : cycle_count + 1;

    REGISTER_R #(.N(CLOCK_COUNTER_WIDTH)) clock_counter_reg(cycle_count, cycle_count_next, reset, clk);

    // TODO Remove these assignments when implementing this module
    assign serial_out = serial_out_reg;
    assign data_in_ready = data_in_ready_reg;
endmodule
