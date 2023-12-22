/**
 * @file PriorityResolver_tb.v .
 * @brief Testbench for the Priority Resolver module.
 */

 /**
 * @brief Testbench for the Priority Resolver module.
 * @details Simulates various scenarios to verify the functionality of the Priority Resolver module.
 */
module PriorityResolver_tb();
    // Inputs
    reg freezing;
    reg [7:0] IRR_reg;
    reg [7:0] ISR_reg;
    reg [2:0] resetedISR_index;
    reg [7:0] OCW2;
    reg INT_requestAck = 0;


    // Outputs
    wire [2:0] serviced_interrupt_index;
    wire [2:0] zeroLevelPriorityBit;
    wire INT_request;


    // Instantiate the InterruptRequestRegister module
    PriorityResolver pr_inst(
        .freezing(freezing),
        .IRR_reg(IRR_reg),
        .ISR_reg(ISR_reg),
        .resetedISR_index(resetedISR_index),
        .OCW2(OCW2),
        .INT_requestAck,
        .serviced_interrupt_index(serviced_interrupt_index),
        .zeroLevelPriorityBit(zeroLevelPriorityBit),
        .INT_request(INT_request)
    );
    
    integer testCaseNo;
    integer i;
    // Stimulus
    initial begin
        #10 testCaseNo = 0;
      /*
       * Fixed priorities tests.
       * OCW2 will have the value of 001xxxxx or 011xxxxx.
       * Zero priority level index must be 0 all the time.
       * Check All the expected outputs to be as expected.
       */
        //->Test case 1: 
        // -Inputs: ISR empty, IRR empty, resetedISR is x, 
        // OCW2 indicates for FULLY_NESTED_MODE, INT_requestAck is zero.
        // -Expected Outputs: serviced_interrupt_index is x,
        // zeroLevelPriorityBit is zero, INT_request is zero.
        // -The test flow: check all the values of OCW2 to give all the expected outputs.
        ISR_reg = 8'b0;
        IRR_reg = 8'b0;
        resetedISR_index = 1'bx;
        INT_requestAck = 0;
        //OCW2 is 001xxxxx
        for(i = 0; i < 32; i = i + 1) begin
           OCW2 = {3'b001, i[4:0]};
           #10;
        end
        //OCW2 is 011xxxxx
        for(i = 0; i < 32; i = i + 1) begin
           OCW2 = {3'b011, i[4:0]};
           #10;
        end

    end

    /*
    * When an INT_request arrived, INT_requestAck must be inverted.
    */
    always @(posedge INT_request) begin
        INT_requestAck <= ~INT_requestAck;
    end

endmodule