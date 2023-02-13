`timescale 1ns/1ns

`define CLOCK_PERIOD 8

module control_unit_tb();
  localparam WIDTH = 4;

  reg [3:0] buttons_pressed;
  reg [1:0] SWITCHES;

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

  reg [WIDTH-1:0] tmp_addr, tmp_data;

  reg clk = 0;
  always #(`CLOCK_PERIOD/2) clk = ~clk;

  datapath #(
    .WIDTH(WIDTH)
  ) DATAPATH (
    .clk(clk),

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
    .clk(clk),

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

  // Some basic tests are done for you. Feel free to add your own tests
  initial begin
`ifdef IVERILOG
     $dumpfile("control_unit_tb.fst");
     $dumpvars;
`endif
`ifndef IVERILOG
     $vcdpluson;
     $vcdplusmemon;
`endif     
     buttons_pressed = 0;
     SWITCHES = 0;
     repeat (10) @(negedge clk);
     // reset
     SWITCHES = 2'b11;
     buttons_pressed[3] = 1;
     @(negedge clk);
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(~idle) $display("test 0 failed");
     // set address w
     SWITCHES = 2'b00;
     buttons_pressed[3] = 1;
     @(negedge clk);
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 1 failed");
     // increment keypad
     tmp_addr = disp_output;
     buttons_pressed[0] = 1;
     @(negedge clk);
     buttons_pressed[0] = 0;
     tmp_addr = tmp_addr + 1;
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_addr)) $display("test 2 failed, got %b, expected %b", disp_output, tmp_addr);
     // set data
     buttons_pressed[2] = 1;
     @(negedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 3 failed");
     // decrement keypad
     tmp_data = disp_output;
     buttons_pressed[1] = 1;
     @(negedge clk);
     buttons_pressed[1] = 0;
     tmp_data = tmp_data - 1;
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_data)) $display("test 4 failed, got %b, expected %b", disp_output, tmp_data);
     // write
     buttons_pressed[2] = 1;
     @(negedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(~idle) $display("test 5 failed");
     // set address r
     SWITCHES = 2'b01;
     buttons_pressed[3] = 1;
     @(negedge clk);
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 6 failed");
     // increment keypad
     while(tmp_addr != keypad_value) begin
        buttons_pressed[0] = 1;
        @(negedge clk);
        buttons_pressed[0] = 0;
        repeat (10) @(negedge clk);
     end
     // read
     buttons_pressed[2] = 1;
     @(negedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(~idle || (disp_output != tmp_data)) $display("test 7 failed, got %b, expected %b", disp_output, tmp_data);

     // TODO: implement test for Compute state



`ifndef IVERILOG
     $vcdplusoff;
`endif
     $display("Done!");
     $finish();
  end

  initial begin
    repeat (10000) @(posedge clk);
`ifndef IVERILOG
     $vcdplusoff;
`endif
    $display("Timeout!");
    $finish();
  end

endmodule
