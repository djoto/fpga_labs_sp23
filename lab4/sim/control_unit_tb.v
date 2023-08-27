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

  reg [WIDTH-1:0] tmp_addr, tmp_data, tmp_addr_2, tmp_data_2;

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
     @(posedge clk);  // added
     buttons_pressed[3] = 1;
     @(posedge clk);  // changed
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(~idle) $display("test 0 failed");
     // set address w
     SWITCHES = 2'b00;
     @(posedge clk);  // added
     buttons_pressed[3] = 1;
     @(posedge clk);  // changed
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 1 failed");
     // increment keypad
     tmp_addr = disp_output;  // 0
     @(posedge clk);  // added
     buttons_pressed[0] = 1;
     @(posedge clk);  // changed
     buttons_pressed[0] = 0;
     tmp_addr = tmp_addr + 1;  // 1
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_addr)) $display("test 2 failed, got %b, expected %b", disp_output, tmp_addr);
     // set data
     @(posedge clk);  // added
     buttons_pressed[2] = 1;
     @(posedge clk);  // changed
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 3 failed");
     // increment keypad
     tmp_data = disp_output;  // 1
     @(posedge clk);  // added
     buttons_pressed[0] = 1;
     @(posedge clk);  // changed
     buttons_pressed[0] = 0;
     tmp_data = tmp_data + 1; // 2
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_data)) $display("test 4 failed, got %b, expected %b", disp_output, tmp_data);
     // write
     @(posedge clk);  // added
     buttons_pressed[2] = 1;
     @(posedge clk);  // changed
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(~idle) $display("test 5 failed");
     // set address r
     SWITCHES = 2'b01;
     @(posedge clk);  // added
     buttons_pressed[3] = 1;
     @(posedge clk);  // changed
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 6 failed");
     // increment keypad
     while(tmp_addr != keypad_value) begin
     	@(posedge clk);  // added
        buttons_pressed[0] = 1;
     	@(posedge clk);  // changed
        buttons_pressed[0] = 0;
        repeat (10) @(negedge clk);
     end
     // read
     @(posedge clk);  // added
     buttons_pressed[2] = 1;
     @(posedge clk);  // changed
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(~idle || (disp_output != tmp_data)) $display("test 7 failed, got %b, expected %b", disp_output, tmp_data);

     // TODO: implement test for Compute state
     //
     // SET VALUE 3 AT ADDRESS 4
     SWITCHES = 2'b00;
     @(posedge clk);
     buttons_pressed[3] = 1;
     @(posedge clk);
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 8 failed");
     // increment keypad
     tmp_addr = disp_output;  // 1
     @(posedge clk);
     buttons_pressed[0] = 1;
     @(posedge clk);
     buttons_pressed[0] = 0;
     repeat (10) @(negedge clk);
     @(posedge clk);
     buttons_pressed[0] = 1;
     @(posedge clk);
     buttons_pressed[0] = 0;
     repeat (10) @(negedge clk);
     @(posedge clk);
     buttons_pressed[0] = 1;
     @(posedge clk);
     buttons_pressed[0] = 0;
     tmp_addr = tmp_addr + 3; // 4
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_addr)) $display("test 9 failed, got %b, expected %b", disp_output, tmp_addr);
     // set data
     @(posedge clk);
     buttons_pressed[2] = 1;
     @(posedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 10 failed");
     // increment keypad
     tmp_data = disp_output; // 4
     @(posedge clk);
     buttons_pressed[1] = 1;
     @(posedge clk);
     buttons_pressed[1] = 0;
     tmp_data = tmp_data - 1; // 3
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_data)) $display("test 11 failed, got %b, expected %b", disp_output, tmp_data);
     // write
     @(posedge clk);
     buttons_pressed[2] = 1;
     @(posedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(~idle) $display("test 12 failed");
     repeat (10) @(negedge clk);
     repeat (10) @(negedge clk);
     if(~idle) $display("test 13 failed");
     // read value from address 4 to check if writing correctly done
     SWITCHES = 2'b01;
     @(posedge clk);
     buttons_pressed[3] = 1;
     @(posedge clk);
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 14 failed");
     // increment keypad
     // while(tmp_addr_2 != keypad_value) begin
     @(posedge clk);
     buttons_pressed[0] = 1;
     @(posedge clk);
     buttons_pressed[0] = 0;
     repeat (10) @(negedge clk);
     // end
     // read
     @(posedge clk);
     buttons_pressed[2] = 1;
     @(posedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     if(~idle || (disp_output != tmp_data)) $display("test 15 failed, got %b, expected %b", disp_output, tmp_data);
     repeat (10) @(negedge clk);
     repeat (10) @(negedge clk);
     if(~idle) $display("test 16 failed");
     //
     //
     // TEST FOR COMPUTE STATE (sum of values 2 and 3 from addresses 1 and 4, respectively)
     SWITCHES = 2'b10;
     @(posedge clk);
     buttons_pressed[3] = 1;
     @(posedge clk);
     buttons_pressed[3] = 0;
     repeat (10) @(negedge clk);
     if(idle) $display("test 17 failed");
     repeat (10) @(negedge clk);
     tmp_data = tmp_data + 1; // 4
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_data)) $display("test 18 failed, got %b, expected %b", disp_output, tmp_data);
     // read from address 4 (keypad is 4 at this point)
     @(posedge clk);
     buttons_pressed[2] = 1;
     @(posedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     repeat (10) @(negedge clk);
     // decrement kaypad value to be 1
     @(posedge clk);
     buttons_pressed[1] = 1;
     @(posedge clk);
     buttons_pressed[1] = 0;
     repeat (10) @(negedge clk);
     @(posedge clk);
     buttons_pressed[1] = 1;
     @(posedge clk);
     buttons_pressed[1] = 0;
     repeat (10) @(negedge clk);
     @(posedge clk);
     buttons_pressed[1] = 1;
     @(posedge clk);
     buttons_pressed[1] = 0;
     repeat (10) @(negedge clk);
     tmp_data = tmp_data - 3; // 1
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_data)) $display("test 19 failed, got %b, expected %b", disp_output, tmp_data);
     // read from address 1
     @(posedge clk);
     buttons_pressed[2] = 1;
     @(posedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     repeat (10) @(negedge clk);
     // increment kaypad to value 2 (sum result will be at address 2)
     @(posedge clk);
     buttons_pressed[0] = 1;
     @(posedge clk);
     buttons_pressed[0] = 0;
     repeat (10) @(negedge clk);
     tmp_data = tmp_data + 1; // 2
     repeat (10) @(negedge clk);
     if(idle || (disp_output != tmp_data)) $display("test 20 failed, got %b, expected %b", disp_output, tmp_data);
     // write sum result to address 2
     @(posedge clk);
     buttons_pressed[2] = 1;
     @(posedge clk);
     buttons_pressed[2] = 0;
     repeat (10) @(negedge clk);
     repeat (10) @(negedge clk);
     tmp_data = 2 + 3; // 5
     repeat (10) @(negedge clk);
     if(~idle || (disp_output != tmp_data)) $display("test 21 failed, got %b, expected %b", disp_output, tmp_data);



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
