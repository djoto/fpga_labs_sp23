`timescale 1ns/1ns

`define CLK_PERIOD 8
`define CYCLES_PER_SECOND 125_000

module counter_tb();
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    reg [3:0] buttons;
    wire [3:0] leds;

    counter #(.CYCLES_PER_SECOND(`CYCLES_PER_SECOND)) ctr (
        .clk(clk),
        .buttons(buttons),
        .leds(leds)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("counter_tb.fst");
            $dumpvars(0, counter_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // TODO: Change input values and step forward in time to test
        // your counter and its clock enable/disable functionality.
        buttons = 0;
        repeat (5) @(posedge clk);
        #1;

        buttons[0] = 1;
        @(posedge clk);
        #1;

        buttons[0] = 0;
        repeat (5) @(posedge clk);
        #1;
        assert(leds[0] == 1) else $display("led[0] should be 1 after button[0] pressed first time");

        repeat (10) begin
            buttons[0] = ~buttons[0];
            @(posedge clk); #1;
        end
        assert(leds == 4'b0110) else $display("leds should be 6 (0110) after button[0] pressed six times");

        repeat (5) @(posedge clk);
        repeat (20) begin
            buttons[0] = ~buttons[0];
            @(posedge clk); #1;
        end

        buttons[0] = 1;
        @(posedge clk);
        buttons[0] = 0;

        repeat (5) @(posedge clk);

        buttons[3] = 1;
        @(posedge clk);
        #1;

        buttons[3] = 0;
        assert(leds == 0) else $display("leds should be 0 after button[3] (reset) pressed");

        repeat (10) @(posedge clk);



        buttons[2] = 1;
        @(posedge clk);
        buttons[2] = 0;
        repeat (500000) @(posedge clk);
        
        repeat (100) @(posedge clk);
        buttons[2] = 1;
        @(posedge clk);
        buttons[2] = 0;

        repeat (5) @(posedge clk);
        buttons[0] = 1;
        @(posedge clk);
        buttons[0] = 0;

        repeat (10) @(posedge clk);

        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule

