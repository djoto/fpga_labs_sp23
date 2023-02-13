module z1top_calculator (
  input CLK_125MHZ_FPGA,
  input [3:0] buttons_pressed,
  input [1:0] SWITCHES,
  output [4:0] LEDS
);

  localparam WIDTH  = 4;

  wire [WIDTH-1:0] keypad_value;
  wire [WIDTH-1:0] disp_output;

  wire addr_cen;
  wire op_a_cen;
  wire op_b_cen;
  wire result_cen;

  wire read;
  wire write;
  wire write_sel;
  wire disp_sel;

  wire idle;

  datapath #(
    .WIDTH(WIDTH)
  ) DATAPATH (
    .clk(CLK_125MHZ_FPGA),

    .keypad_value(keypad_value), // input

    .addr_cen(addr_cen),  // input
    .op_a_cen(op_a_cen),          // input
    .op_b_cen(op_b_cen),          // input
    .result_cen(result_cen),      // input

    .read(read),         // input
    .write(write),       // input
    .write_sel(write_sel),       // input
    .disp_sel(disp_sel),       // input

    .disp_output(disp_output)  // output
  );

  control_unit #(
    .WIDTH(WIDTH)
  ) CONTROL_UNIT (
    .clk(CLK_125MHZ_FPGA),

    .buttons_pressed(buttons_pressed), // input
    .SWITCHES(SWITCHES),               // input

    .keypad_value(keypad_value), // output

    .addr_cen(addr_cen), // output
    .op_a_cen(op_a_cen),         // output
    .op_b_cen(op_b_cen),         // output
    .result_cen(result_cen),     // output

    .read(read),         // output
    .write(write),       // output
    .write_sel(write_sel),       // output
    .disp_sel(disp_sel),       // output

    .idle(idle)                  // output
  );

  // We use LEDS[4] as indicator if the calculator is in idle state
  assign LEDS[4]   = idle;
  assign LEDS[3:0] = disp_output;

endmodule
