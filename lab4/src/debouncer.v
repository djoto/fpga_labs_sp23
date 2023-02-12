module debouncer #(
                   parameter WIDTH              = 1,
                   parameter SAMPLE_CNT_MAX     = 62500,
                   parameter PULSE_CNT_MAX      = 200,
                   parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
                   parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
                   ) (
                      input              clk,
                      input [WIDTH-1:0]  glitchy_signal,
                      output [WIDTH-1:0] debounced_signal
                      );
endmodule
