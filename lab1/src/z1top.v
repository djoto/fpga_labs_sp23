module z1top(
  input CLK_125MHZ_FPGA,
  input [3:0] BUTTONS,
  input [1:0] SWITCHES,
  output [5:0] LEDS
);

  and(LEDS[0], BUTTONS[0], SWITCHES[0]);
  assign LEDS[5:1] = 0;

//  wire a, b;
//  and(a, BUTTONS[0], BUTTONS[1]);
//  and(b, BUTTONS[2], BUTTONS[3]); 
//  and(LEDS[1], a, b); 

//  and(LEDS[1], BUTTONS[0], BUTTONS[1], BUTTONS[2], BUTTONS[3]);

endmodule
