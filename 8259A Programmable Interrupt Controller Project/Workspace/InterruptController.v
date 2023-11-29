module InterruptController (
  input clk,           // Clock input
  input enable_gie,    // Enable signal for General Interrupt Enable
  input [n-1:0] pie,   // Peripheral Interrupt Enable for n peripherals
  output reg gie       // General Interrupt Enable
);

always @(posedge clk) begin
  if (enable_gie) begin
    // Enable GIE only if at least one PIE is enabled
    if (|pie) begin
      gie <= 1;
    end
  else begin
    // Disable GIE
    gie <= 0;
  end
end
end
endmodule