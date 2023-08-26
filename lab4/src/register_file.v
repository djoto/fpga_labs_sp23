`timescale 1ns/1ns

module register_file # (
  parameter AWIDTH = 5,
  parameter DWIDTH = 32
) (
  input clk,
  input               we,
  input  [AWIDTH-1:0] addr,
  input  [DWIDTH-1:0] din,
  output [DWIDTH-1:0] dout
);

  // TODO: implement a register file
  // Some initial code is provided to you, feel free to change it

  // REGISTERs version
/*
  localparam NUM_REGS = (1 << AWIDTH);

  wire [DWIDTH-1:0] rf_entry_next  [NUM_REGS-1:0];
  wire [DWIDTH-1:0] rf_entry_value [NUM_REGS-1:0];
  wire              rf_entry_ce    [NUM_REGS-1:0];
  wire [NUM_REGS-1:0] decoder_out;

  // Decoder
  assign decoder_out = (1 << addr);

  // Multiplexer
  assign dout = rf_entry_value[addr];

  genvar i;
  generate for (i = 0; i < NUM_REGS; i = i + 1) begin
    REGISTER_CE #(.N(DWIDTH)) rf_entry (
      .clk(clk),
      .ce(rf_entry_ce[i]),
      .d(rf_entry_next[i]),
      .q(rf_entry_value[i])
    );

    assign rf_entry_ce[i]   = we & decoder_out[i];
    assign rf_entry_next[i] = din;
  end
  endgenerate
*/

  // ASYNC_RAM version
  ASYNC_RAM #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) async_ram(.q(dout), .d(din), .addr(addr), .we(we), .clk(clk));

endmodule
