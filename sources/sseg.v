`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/29/2021 08:33:04 PM
// Design Name: 
// Module Name: sseg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sseg(
    input clock,
    input reset,
    input [3:0] fourth_state,
    input [3:0] third_state,
    input [3:0] second_state,
    input [3:0] first_state,
    output reg[3:0] anode, //which anode for sseg
    output reg [6:0] sseg_temp //temp sseg for case statement
    );

//Seven Segment Display with 18bit  multiplexer as a timer 

reg [18-1:0]count;

always @ (posedge clock or posedge reset)
 begin
  if (reset)
   count <= 0;
  else
   count <= count + 1;
 end

reg [3:0]sseg; //the 4 bit register to hold the data that is to be output
always @ (*)
 begin
  case(count[18-1:18-2]) //MSB and MSB-1 to determine the anode and state the main game logic is in
   
   2'b00 : 
    begin
     sseg = first_state; //regarding which state and which anodes to turn on
     anode = 4'b1110;
    end
   
   2'b01:
    begin
     sseg = second_state;
     anode = 4'b1101;
    end
   
   2'b10:
    begin
     sseg = third_state;
     anode = 4'b1011;
    end
    
   2'b11:
    begin
     sseg = fourth_state;
     anode = 4'b0111;    
    end
  endcase
 end

always @ (*) //simulanteous, change the seven segment display
 begin
  case(sseg)
   4'd0 : sseg_temp = 7'b1000000; //display 0 g f e d c b a
   4'd1 : sseg_temp = 7'b1111001; //display 1
   4'd2 : sseg_temp = 7'b0100100; //display 2
   4'd3 : sseg_temp = 7'b0110000; //display 3
   4'd4 : sseg_temp = 7'b0011001; //display 4
   4'd5 : sseg_temp = 7'b0010010; //display 5
   4'd6 : sseg_temp = 7'b0000010; //display 6
   4'd7 : sseg_temp = 7'b1111000; //display 7
   4'd8 : sseg_temp = 7'b0000000; //display 8
   4'd9 : sseg_temp = 7'b0010000; //display 9
   4'd10 : sseg_temp = 7'b0100011; //to display H
   4'd11 : sseg_temp = 7'b0101011; //to display I
   default : sseg_temp = 7'b0111111; //dash
  endcase
 end

endmodule
