`timescale 1ns/1ns
`define CLOCK_FREQ 125_000_000

`define REGISTER_FILE
//`define ACCUMULATOR
//`define CALCULATOR

module z1top (
    input CLK_125MHZ_FPGA,
    input [3:0] BUTTONS,
    input [1:0] SWITCHES,
    output [5:0] LEDS
);

  // Button parser
  // Sample the button signal every 500us
  localparam integer B_SAMPLE_CNT_MAX = 0.0005 * `CLOCK_FREQ;
  // The button is considered 'pressed' after 100ms of continuous pressing
  localparam integer B_PULSE_CNT_MAX = 0.100 / 0.0005;

  wire [3:0] buttons_pressed;
  button_parser #(
    .WIDTH(4),
    .SAMPLE_CNT_MAX(B_SAMPLE_CNT_MAX),
    .PULSE_CNT_MAX(B_PULSE_CNT_MAX)
  ) bp (
    .clk(CLK_125MHZ_FPGA),
    .in(BUTTONS),
    .out(buttons_pressed));

`ifdef REGISTER_FILE
   z1top_register_file z1top_rf(.CLK_125MHZ_FPGA(CLK_125MHZ_FPGA), .buttons_pressed(buttons_pressed), .SWITCHES(SWITCHES), .LEDS(LEDS));
`elsif ACCUMULATOR
   z1top_accumulator z1top_acc(.CLK_125MHZ_FPGA(CLK_125MHZ_FPGA), .buttons_pressed(buttons_pressed), .SWITCHES(SWITCHES), .LEDS(LEDS));
`elsif CALCULATOR
   z1top_calculator z1top_calc(.CLK_125MHZ_FPGA(CLK_125MHZ_FPGA), .buttons_pressed(buttons_pressed), .SWITCHES(SWITCHES), .LEDS(LEDS[4:0]));
   wire      rst;
   wire [5:0] tmp;
   z1top_accumulator z1top_acc(.CLK_125MHZ_FPGA(CLK_125MHZ_FPGA), .buttons_pressed({2'b00, rst, rst}), .SWITCHES(2'b00), .LEDS(tmp));
   assign rst = (SWITCHES[1:0] == 2'b11) & buttons_pressed[3];
   assign LEDS[5] = tmp[5] & tmp[4];
`endif
endmodule
