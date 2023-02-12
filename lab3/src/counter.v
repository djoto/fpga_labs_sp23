module counter #(
    parameter CYCLES_PER_SECOND = 125_000_000
)(
    input clk,
    input [3:0] buttons,
    output [3:0] leds
);
    wire [3:0] count;
    wire [3:0] d;
    assign leds = counter;

    always @(*) begin
        if (buttons[0])
            data = counter + 4'd1;
        else if (buttons[1])
            data = counter - 4'd1;
        else if (buttons[3])
            data = 4'd0;
        else
            data = count;
            
    end

    REGISTER #(4) counter (.q(count), .d(data), .clk(clk))
endmodule

