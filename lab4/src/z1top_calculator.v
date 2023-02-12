module z1top_calculator (
  input CLK_125MHZ_FPGA,
  input [3:0] buttons_pressed,
  input [1:0] SWITCHES,
  output [5:0] LEDS
);

  localparam WIDTH  = 5;

  wire [WIDTH-1:0] keypad_value;
  wire [WIDTH-1:0] displ_output;

  wire mem_addr_cen;
  wire op_a_cen;
  wire op_b_cen;
  wire result_cen;

  wire mem_read;
  wire mem_write;
  wire write_sel;
  wire displ_sel;

  wire idle;
  wire rst;

  datapath #(
    .WIDTH(WIDTH)
  ) DATAPATH (
    .clk(CLK_125MHZ_FPGA),

    .keypad_value(keypad_value), // input

    .mem_addr_cen(mem_addr_cen),  // input
    .op_a_cen(op_a_cen),          // input
    .op_b_cen(op_b_cen),          // input
    .result_cen(result_cen),      // input

    .mem_read(mem_read),         // input
    .mem_write(mem_write),       // input
    .write_sel(write_sel),       // input
    .displ_sel(displ_sel),       // input

    .displ_output(displ_output)  // output
  );

  control_unit #(
    .WIDTH(WIDTH)
  ) CONTROL_UNIT (
    .clk(CLK_125MHZ_FPGA),
    .rst(rst),

    .buttons_pressed(buttons_pressed), // input
    .SWITCHES(SWITCHES),               // input

    .keypad_value(keypad_value), // output

    .mem_addr_cen(mem_addr_cen), // output
    .op_a_cen(op_a_cen),         // output
    .op_b_cen(op_b_cen),         // output
    .result_cen(result_cen),     // output

    .mem_read(mem_read),         // output
    .mem_write(mem_write),       // output
    .write_sel(write_sel),       // output
    .displ_sel(displ_sel),       // output

    .idle(idle)                  // output
  );

  // We use LEDS[5] as indicator if the calculator is in idle state
  assign LEDS[5]   = idle;
  assign LEDS[4:0] = displ_output;

  assign rst = (SWITCHES[1:0] == 2'b11) & buttons_pressed[3];

endmodule
