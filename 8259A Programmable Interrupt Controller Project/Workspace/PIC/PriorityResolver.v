module PriorityResolver(
  input wire freezing,
  input wire [7:0] IRR_reg, //connected to ISR to get its reg values.
  input wire [7:0] ISR_reg, //connected to ISR to get its reg values.
  input wire [2:0] resetedISR_index, //the number of ISR that've been reset.
  input wire [7:0] OCW2, //connected to the OCW2 reg to know the mode.
  output reg [2:0] serviced_interrupt_index, //connected to ISR (index to set) or to IRR (index to reset) the corresponding bit.
  output reg [2:0] zeroLevelPriorityBit, //Which bit have the highest bit priority, changes in rotaion modes.
  output reg INT_request //connected to the control logic to fire a new interrupt
);
  
  reg [7:0] interrupt_indexes; //Register to store valid interrupt indexes.
  reg [1:0] currentMode; //Register to store the current mode active according to OCW2.
  wire [2:0] modesFromOCW2; //wire that holds the values of (D7,D6,D5) of OCW2. 
  reg resolveFlag; //Flag to start resolving the current priority.
  integer i; //counter for loops
  /*
   * Assign wires
   */
   assign modesFromOCW2 = OCW2[7:5];
   
  /*
   * localparam for the OCW2 modes (in this order: D7,D6,D5)
   */
  //For Fully Nested mode
  localparam NON_SPECIFIC_EOI                 = 3'b001;
  localparam SPECIFIC_EOI                     = 3'b011;
  //For Automatic Rotation mode
  localparam ROTATE_ON_NON_SPECIFIC_EOI       = 3'b101;
  localparam ROTATE_ON_AUTO_EOI_set           = 3'b100; //TODO??
  localparam ROTATE_ON_AUTO_EOI_clear         = 3'b000; //TODO??
  //For Specific rotation (out of scope)
  localparam ROTATE_ON_SPECIFIC_EOI           = 3'b111; 
  localparam SET_PRIORITY                     = 3'b110;
  //No operation ??
  localparam NO_OPERATION                     = 3'b010; //TODO??
  
  /*
   * Values of each mode
   */
   localparam FULLY_NESTED_MODE  = 2'b00;
   localparam AUTO_ROTATION_MODE = 2'b01;
   
  /*
   * Set the mode according to the value of OCW2.
   */
   always @(modesFromOCW2) begin
     case (modesFromOCW2)
      //Fully nested mode
      NON_SPECIFIC_EOI: currentMode <= FULLY_NESTED_MODE;
      SPECIFIC_EOI:     currentMode <= FULLY_NESTED_MODE;
      //Automatic Rotation mode
      ROTATE_ON_NON_SPECIFIC_EOI: currentMode <= AUTO_ROTATION_MODE;
      ROTATE_ON_AUTO_EOI_set:     currentMode <= AUTO_ROTATION_MODE;
      ROTATE_ON_AUTO_EOI_clear:   currentMode <= AUTO_ROTATION_MODE;
    endcase
   end
   
  
  /*
   * If any changes happeend in the IRR reg, if the priority was in freezing,
   * then ignore the changes in IRR and use the prev value of interrupt_indexes
   * Otherwise save the new IRR in the interrupt_indexes and start resolving.
   */
  always @(IRR_reg) begin
    //save the values of IRR or not according to freezing flag.
    if(freezing) begin
      interrupt_indexes = interrupt_indexes; //Store valid interrupts and freeze it.
    end else begin
      interrupt_indexes = IRR_reg; //Get the new values from the IRR.
      //Start resolviong priority.
      resolveFlag = 1;
      #5 resolveFlag = 0;
    end 
  end
  
  /*
   * Resolving block according to the mode.
   */
   always @(posedge resolveFlag) begin
     //Do the resolving according to the mode.
     case (currentMode)
       FULLY_NESTED_MODE: begin
         zeroLevelPriorityBit <= 3'b0; //Bit zero have the level zero
     end  
       
       AUTO_ROTATION_MODE: begin
         zeroLevelPriorityBit <= zeroLevelPriorityBit; //Priority is same as before, until EOI occured
         //change will happen at: always @(ISR_reg) part.
       end
    endcase
    /*
     * Loop starting from the IRR_reg bit with highest priority to the bit
     * with the lowest priority, get the highest priority bit.
     * assign the value to serviced_interrupt_index.
     * 
     * when the serviced_interrupt_index is changed, it must be compared with 
     * ISR_reg bits to determine whether to fire a flag or not. 
     * this part is found at: always @(serviced_interrupt_index) part.
     */
    for(i = 0; i < 8; i = i + 1) begin
      if(IRR_reg[zeroLevelPriorityBit + i]) begin
        // Assign the active numbered IRR bit with highest priority.
        serviced_interrupt_index <= resetedISR_index + i;
        i = 8; // Exit the loop once the interrupt is found.
      end
    end
   end
  
  /*
   * In any change in ISR_reg, we need to change zeroLevelPriorityBit to the new value
   * for the automatic rotation mode.
   */
   always @(ISR_reg) begin
     if(currentMode == AUTO_ROTATION_MODE) begin
       zeroLevelPriorityBit <= resetedISR_index + 1;
     end
   end
  
  /*
   * When serviced_interrupt_index changes, we need to check whether it
   * has a higher priority than the currenct bits in ISR_regor not.
   * 
   * If true then we will fire an INT flag to the control logic,
   * Else do nothing.
   */
   always @(serviced_interrupt_index) begin
     // loop for ISR bits starting from the highest priority.
     // compare the highest with the serviced_interrupt_index value
     for(i = 0; i < 8; i = i + 1) begin
       if(ISR_reg[zeroLevelPriorityBit + i]) begin
         //If the new INt is higher in priority, fire a new INt flag.
         if((zeroLevelPriorityBit + i) < serviced_interrupt_index) begin
           INT_request = 1;
           #5 INT_request = 0;
         end
       end
       i = 8; // Exit the loop once the interrupt is found.
     end
   end
  
endmodule