`timescale 1ns/1ns

module control_unit # (
  parameter WIDTH = 5
) (
  input clk,
  input [3:0] buttons_pressed,
  input [1:0] SWITCHES,

  output [WIDTH-1:0] keypad_value,

  output addr_cen,
  output op_a_cen,
  output op_b_cen,
  output result_cen,

  output read,
  output write,
  output write_sel,
  output disp_sel,
  output idle
);

  // buttons_pressed[0] -- increment
  // buttons_pressed[1] -- decrement
  // buttons_pressed[2] -- set
  // SWITCHES[1:0] = 2'b00 -- buttons_pressed[3] -> addr -> buttons_pressed[2] -> data -> buttons_pressed[2]
  // SWITCHES[1:0] = 2'b01 -- buttons_pressed[3] -> addr -> buttons_pressed[2] -> display read result
  // SWITCHES[1:0] = 2'b10 -- buttons_pressed[3] -> addr_op_a -> buttons_pressed[2] -> addr_op_b -> button_pressed[2] -> addr_result -> buttons_pressed[2] -> display add result
  // SWITCHES[1:0] = 2'b11 -- buttons_pressed[3] -> reset

  // disp_sel: 0 -- keypad_value, 1 -- result_value
  // write_sel: 0 -- keypad_value, 1 -- result_value

  // TODO: implement the control logic for your calculator
  // Some code is provided, but feel free to modify it

  // What states do we need?
  localparam STATE_IDLE = 3'd0;

  reg  [2:0] state_next;
  wire [2:0] state_value;
  wire       rst;

  REGISTER_R #(.N(3), .INIT(STATE_IDLE)) state_reg (
    .clk(clk),
    .rst(rst),
    .d(state_next),
    .q(state_value)
  );

  // The keypad register holds the value when we press BUTTONS[0] or BUTTONS[1]
  wire [WIDTH-1:0] keypad_reg_value, keypad_reg_next;
  wire keypad_reg_cen, keypad_reg_rst;

  REGISTER_R_CE #(.N(WIDTH), .INIT(0)) keypad_reg (
    .clk(clk),
    .d(keypad_reg_next),
    .q(keypad_reg_value),
    .ce(keypad_reg_cen),
    .rst(keypad_reg_rst)
  );

  always @(*) begin
    state_next = state_value;

    case (state_value)
      STATE_IDLE: begin
        // FIXME
        state_next = STATE_IDLE;
      end

      // TODO

    endcase
  end

  assign keypad_reg_next = (buttons_pressed[0] == 1'b1) ? keypad_reg_value + 1 :
                           (buttons_pressed[1] == 1'b1) ? keypad_reg_value - 1 : keypad_reg_value;
  assign keypad_reg_rst  = 0; // FIXME
  assign keypad_reg_cen   = 0; // FIXME

  assign op_a_cen     = 0; // FIXME
  assign op_b_cen     = 0; // FIXME
  assign result_cen   = 0; // FIXME
  assign addr_cen = 0; // FIXME

  assign read  = 0; // FIXME
  assign write = 0; // FIXME

  assign write_sel = 0; // FIXME
  assign disp_sel = 0; // FIXME

  assign keypad_value = keypad_reg_value;
  assign idle = (state_value == STATE_IDLE);

  assign rst = (SWITCHES[1:0] == 2'b11) & buttons_pressed[3];

endmodule
