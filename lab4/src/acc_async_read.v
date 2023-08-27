`timescale 1ns/1ns

module acc_async_read #(
  parameter AWIDTH = 10,
  parameter DWIDTH = 32
) (
  input  clk,
  input  rst,
  input  [31:0] len,
  output [AWIDTH-1:0] read_addr,
  input  [DWIDTH-1:0] read_data,
  output [DWIDTH-1:0] acc_result,
  output done
);

  // TODO: implement an accumulator that reads data from (external)
  // memory block asynchronously
  // Some initial code is provided to you, but feel free to change it

  // indexing value to memory
  wire [31:0] index_reg_value, index_reg_next;
  wire index_reg_rst, index_reg_ce;
  REGISTER_R_CE #(.N(32), .INIT(0)) index_reg (
    .q(index_reg_value),
    .d(index_reg_next),
    .ce(index_reg_ce),
    .rst(index_reg_rst),
    .clk(clk)
  );

  // accumulation result
  wire [31:0] sum_reg_value, sum_reg_next;
  wire sum_reg_rst, sum_reg_ce;
  REGISTER_R_CE #(.N(DWIDTH), .INIT(0)) sum_reg (
    .q(sum_reg_value),
    .d(sum_reg_next),
    .ce(sum_reg_ce),
    .rst(sum_reg_rst),
    .clk(clk)
  );

  // TODO: Update these lines
  assign read_addr = index_reg_value;

  assign index_reg_next = index_reg_value == len ? index_reg_value : index_reg_value + 1;
  assign index_reg_ce   = 1;
  assign index_reg_rst  = rst;

  assign sum_reg_next = done ? sum_reg_value : sum_reg_value + read_data;
  assign sum_reg_ce   = 1;
  assign sum_reg_rst  = rst;

  assign acc_result = sum_reg_value;

  // Note that you must hold 'done' HIGH after the computation finishes
  assign done = index_reg_value >= len;

endmodule
