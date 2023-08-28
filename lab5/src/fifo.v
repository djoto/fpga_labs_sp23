module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);

    wire [POINTER_WIDTH-1:0] ptr;
    wire [POINTER_WIDTH-1:0] ptr_next;

    wire can_write;
    wire can_read;

    wire [POINTER_WIDTH-1:0] wr_ptr;
    wire [POINTER_WIDTH-1:0] rd_ptr;
    wire [POINTER_WIDTH:0] count;
    wire [POINTER_WIDTH-1:0] wr_ptr_next;
    wire [POINTER_WIDTH-1:0] rd_ptr_next;
    wire [POINTER_WIDTH:0] count_next;

    // If reading is priority during simultaneous read/write
    //assign ptr_next = can_read ? rd_ptr_next : can_write ? wr_ptr_next : ptr;
    assign ptr_next = can_write ? wr_ptr_next : can_read ? rd_ptr_next : ptr;

    assign can_write = wr_en & ~full;
    assign can_read = rd_en & ~empty;

    assign wr_ptr_next = can_write ? wr_ptr + 1 : wr_ptr;
    assign rd_ptr_next = can_read ? rd_ptr + 1 : rd_ptr;

    /*
    // If reading is priority during simultaneous read/write
    assign count_next  = (can_read & (count > 0))
                         ? count - 1
			 : (can_write & (count < DEPTH))
			 	? count + 1
				: count;
    */

    assign count_next  = (can_write & (count < DEPTH))
                         ? count + 1
			 : (can_read & (count > 0))
			 	? count - 1
				: count;

    REGISTER_R #(.N(POINTER_WIDTH)) ptr_reg    (ptr, ptr_next, rst, clk);
    REGISTER_R #(.N(POINTER_WIDTH)) wr_ptr_reg (wr_ptr, wr_ptr_next, rst, clk);
    REGISTER_R #(.N(POINTER_WIDTH)) rd_ptr_reg (rd_ptr, rd_ptr_next, rst, clk);
    REGISTER_R #(.N(POINTER_WIDTH+1)) count_reg  (count, count_next, rst, clk);

    SYNC_RAM #(.DWIDTH(WIDTH), .AWIDTH(POINTER_WIDTH)) fifo_sync_ram(.q(dout), .d(din), .en(can_read | can_write), .we(can_write), .addr(ptr), .clk(clk));
    // ASYNC_RAM #(.DWIDTH(WIDTH), .AWIDTH(POINTER_WIDTH)) fifo_async_ram(.q(dout), .d(din), .we(can_write), .addr(ptr), .clk(clk));

    assign full = count == DEPTH;
    assign empty = count == 0;

endmodule
