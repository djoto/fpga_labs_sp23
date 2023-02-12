pp`timescale 1ns/1ns

module datapath #(
  parameter WIDTH = 5
) (
  input clk,

  input [WIDTH-1:0] keypad_value,

  input addr_cen,
  input op_a_cen,
  input op_b_cen,
  input result_cen,

  input read,
  input write,
  input write_sel,
  input disp_sel,

  output [WIDTH-1:0] disp_output
);

  wire [WIDTH-1:0] addr_reg_value, addr_reg_next;
  wire addr_reg_ce;

  REGISTER_CE #(.N(WIDTH)) addr_reg (
    .clk(clk),
    .ce(addr_reg_ce),
    .d(addr_reg_next),
    .q(addr_reg_value)
  );

  wire [WIDTH-1:0] op_a_reg_value, op_a_reg_next;
  wire op_a_reg_ce;

  REGISTER_CE #(.N(WIDTH)) op_a_reg (
    .clk(clk),
    .ce(op_a_reg_ce),
    .d(op_a_reg_next),
    .q(op_a_reg_value)
  );

  wire [WIDTH-1:0] op_b_reg_value, op_b_reg_next;
  wire op_b_reg_ce;

  REGISTER_CE #(.N(WIDTH)) op_b_reg (
    .clk(clk),
    .ce(op_b_reg_ce),
    .d(op_b_reg_next),
    .q(op_b_reg_value)
  );

  wire [WIDTH-1:0] result_reg_value, result_reg_next;
  wire result_reg_ce;

  REGISTER_CE #(.N(WIDTH)) result_reg (
    .clk(clk),
    .ce(result_reg_ce),
    .d(result_reg_next),
    .q(result_reg_value)
  );

  wire [WIDTH-1:0] addr;
  wire [WIDTH-1:0] din, dout;
  wire wen;
  ASYNC_RAM #(
    .AWIDTH(WIDTH),
    .DWIDTH(WIDTH)
  ) RF (
    .clk(clk),
    .addr(addr),
    .d(din),
    .q(dout),
    .we(wen)
  );

  assign op_a_reg_next = dout;
  assign op_a_reg_ce   = op_a_cen;

  assign op_b_reg_next = dout;
  assign op_b_reg_ce   = op_b_cen;

  assign result_reg_next = (read) ? dout : (op_a_reg_value + op_b_reg_value);
  assign result_reg_ce   = result_cen;

  assign addr_reg_next = keypad_value;
  assign addr_reg_ce   = addr_cen;

  assign addr = addr_reg_value;
  assign din  = write_sel ? result_reg_value : keypad_value;
  assign wen  = write;

  assign disp_output = disp_sel ? result_reg_value : keypad_value;

endmodule
