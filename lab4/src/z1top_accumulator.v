module z1top_accumulator (
  input CLK_125MHZ_FPGA,
  input [3:0] buttons_pressed,
  input [1:0] SWITCHES,
  output [5:0] LEDS
);

  localparam AWIDTH = 10;
  localparam DWIDTH = 32;

  wire s_rst, s_done, a_rst, a_done;
  wire [DWIDTH-1:0] s_acc_result, a_acc_result;

  wire [31:0] len = 32'd1024;

  // Toggle the accumulation circuits
  wire s_rst_reg_value, s_rst_reg_next, s_rst_reg_ce;
  wire a_rst_reg_value, a_rst_reg_next, a_rst_reg_ce;
  REGISTER_CE #(.N(1)) s_rst_reg(
    .q(s_rst_reg_value),
    .d(s_rst_reg_next),
    .ce(s_rst_reg_ce),
    .clk(CLK_125MHZ_FPGA)
  );

  REGISTER_CE #(.N(1)) a_rst_reg(
    .q(a_rst_reg_value),
    .d(a_rst_reg_next),
    .ce(a_rst_reg_ce),
    .clk(CLK_125MHZ_FPGA)
  );

  assign s_rst_reg_next = ~s_rst_reg_value;
  assign s_rst_reg_ce   = buttons_pressed[0];

  assign a_rst_reg_next = ~a_rst_reg_value;
  assign a_rst_reg_ce   = buttons_pressed[1];

  assign s_rst = s_rst_reg_value;
  assign a_rst = a_rst_reg_value;

  wire [AWIDTH-1:0] s_read_addr, a_read_addr;
  wire [DWIDTH-1:0] s_read_data, a_read_data;

  SYNC_ROM #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH),
    .MIF_HEX("test_data_sync.mif")
  ) srom (
    .clk(CLK_125MHZ_FPGA),
    .en(1'b1),
    .addr(s_read_addr), // input
    .q(s_read_data)     // output
  );

  acc_sync_read #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH)
  ) ACC_SYNC_R (
    .clk(CLK_125MHZ_FPGA),
    .rst(s_rst),
    .done(s_done),            // output
    .read_addr(s_read_addr),  // output
    .read_data(s_read_data),  // input
    .len(len),                // input
    .acc_result(s_acc_result) // output
  );

  ASYNC_ROM #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH),
    .MIF_HEX("test_data_async.mif")
  ) arom (
    .addr(a_read_addr), // input
    .q(a_read_data)     // output
  );

  acc_async_read #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH)
  ) ACC_ASYNC_R (
    .clk(CLK_125MHZ_FPGA),
    .rst(a_rst),
    .done(a_done),            // output
    .read_addr(a_read_addr),  // output
    .read_data(a_read_data),  // input
    .len(len),                // input
    .acc_result(a_acc_result) // output
  );

  // Checksums
  assign LEDS[5] = (s_acc_result == 32'd541587138) && (s_done == 1);
  assign LEDS[4] = (a_acc_result == 32'd514007903) && (a_done == 1);
  assign LEDS[3:0] = 4'h0;

endmodule
