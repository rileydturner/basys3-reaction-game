`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/29/2021 08:41:35 PM
// Design Name: 
// Module Name: game_reflex
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


module game_reflex(
  input clk, btnL, btnC, btnR, //reset is btnL, start is btnC, stop is btnR
  output [3:3]led,
  output [3:0] an,
  output [6:0] seg //use all 7 bits of seven segment display
  );
reg [3:0] out0, out1, out2, out3; //the main output registers

wire game_start, game_stop;
reg single_button_start1, single_button_start2, single_button_stop1, single_button_stop2;
 
always @ (posedge clk) single_button_start1 <= btnC;
always @ (posedge clk) single_button_start2 <= single_button_start1;
 
assign game_start = ~(single_button_start1) & single_button_start2; //there are two posedge of clocks per button press to not have button sticking and read twice
 
always @ (posedge clk) single_button_stop1 <= btnR;
always @ (posedge clk) single_button_stop2 <= single_button_stop1;
 
assign game_stop = ~(single_button_stop1) & single_button_stop2; //there are two posedge of clocks per button press to not have button double read stop input


// connect wires for seven segemtn display .v file
sseg display (
    .clock(clk), 
    .reset(btnL), 
    .fourth_state(out3), 
    .third_state(out2), 
    .second_state(out1), 
    .first_state(out0), 
    .sseg_temp(seg),
    .anode(an)
    );

//lfsr pseudorandom number generator 

reg [28:0] rand, rand_n, rand_d; //29 bits for each random bit 
reg [4:0] lfsrcount, lfsrcount_n; //save the shifts, 5 bit since need up to 30 shifts
wire feedback = rand[28] ^ rand[16]; //random seed

always @ (posedge clk or posedge btnL)
begin
 if (btnL)
 begin
  rand <= 29'hF; //lfsf should never be zero, so in reset then set all to high
  lfsrcount <= 0; //count is zero
 end
 else
 begin
  rand <= rand_n; //get next random
  lfsrcount <= lfsrcount_n; //get next count
 end
end

always @ (*)
begin
 rand_n = rand; //default state stays the same
 lfsrcount_n = lfsrcount;
  
  rand_n = {rand[27:0], feedback}; //shift left with xor seed from feedback and continue until count is 29
 if (lfsrcount == 29) 
 begin
  lfsrcount_n = 0;
  rand_d = rand; //assign random value now
 end
 else
 begin
  lfsrcount_n = lfsrcount + 1;// increase count
  rand_d = rand; //retain previous random vlaue
 end
end


reg [3:0] out0_d, out1_d, out2_d, out3_d; //registers that will hold the individual counts
reg [1:0] sel, sel_next; //for KEEP attribute see note below
localparam [1:0]
      IDLE = 2'b00,
      START = 2'b01,
      TIME = 2'b10,
      DONE = 2'b11;
      
reg [1:0] state_reg, state_next;
reg [28:0] count_reg, count_next; 

always @ (posedge clk or posedge btnL)
begin
 if(btnL)
  begin 
   state_reg <= IDLE;
   count_reg <= 0;
   sel <=0;
  end
 else
  begin
   state_reg <= state_next;
   count_reg <= count_next;
   sel <= sel_next;
  end
end

reg go_start;
always @ (*)
begin
 state_next = state_reg; //default state stays the same
 count_next = count_reg;
 sel_next = sel;
 case(state_reg)
  IDLE:
   begin
    //display ON
    sel_next = 2'b00;
    if(game_start)
    begin
     count_next = rand_d; //get the random number from LFSR module
     state_next = START; //go to next state
    end
   end
  START:
   begin
    if(count_next == 500000000) // **500M equals a delay of 10 seconds. and starting from 'rand' ensures a random delay
    begin  
     state_next = TIME; //go to next state
    end
    
    else
    begin
     count_next = count_reg + 1; 
    end
   end  
  TIME:
   begin
     sel_next = 2'b01; //start the timer
     state_next = DONE;     
   end
    
  DONE:
   begin
    if(game_stop)
     begin
      sel_next = 2'b10; //stop the timer
     end
    
   end
   
  endcase
  
 case(sel_next) //what is sent so seven seg can display
  2'b00: //-on- statement
  begin
   go_start = 0; //timer is OFF
   out0 = 4'd12; //-
   out1 = 4'd11;//o
   out2 = 4'd10;//n
   out3 = 4'd12;//-
  end
  
  2'b01: //timer
  begin
   
   go_start = 1'b1; //start timer
   out0 = out0_d;
   out1 = out1_d;
   out2 = out2_d;
   out3 = out3_d;
  end
  
  2'b10: //stop timer
  begin
   go_start = 1'b0;
   out0 = out0_d;
   out1 = out1_d;
   out2 = out2_d;
   out3 = out3_d;
  end
  
  2'b11: //must complete case statment, this is dashed and will never appear if working properly
  begin
   out0 = 4'd12; 
   out1 = 4'd12;
   out2 = 4'd12;
   out3 = 4'd12;
   go_start = 1'b0;
  end
  
  default:
  begin
   out0 = 4'd12;
   out1 = 4'd12;
   out2 = 4'd12;
   out3 = 4'd12;
   go_start = 1'b0;
  end
 endcase   
end


//stopwatch
reg [19:0] ticker; //19 bits needed to count up to 500K bits
wire click;

//the mod 500K clock to generate a tick ever 0.01 second

always @ (posedge clk or posedge btnL)
begin
 if(btnL)

  ticker <= 0;

 else if(ticker == 100000) //at 500K reset it
  ticker <= 0;
 else if(go_start) //only start if the input is set high
  ticker <= ticker + 1;
end

assign click = ((ticker == 100000)?1'b1:1'b0); //click to be assigned high every 0.01 second
//if ticker 100000 then click is 1 else 0

always @ (posedge clk or posedge btnL)
begin
 if (btnL)
  begin
   out0_d <= 0;
   out1_d <= 0;
   out2_d <= 0;
   out3_d <= 0;
  end
  
 else if (click) //increment at every click
  begin
   if(out0_d == 9) //xxx9 - the 0.001 second digit
   begin  //if_1
    out0_d <= 0;
    
    if (out1_d == 9) //xx99 
    begin  // if_2
     out1_d <= 0;
     if (out2_d == 5) //x599 - the two digit seconds digits
     begin //if_3
      out2_d <= 0;
      if(out3_d == 9) //9599 - The minute digit
       out3_d <= 0;
      else
       out3_d <= out3_d + 1;
     end
     else //else_3
      out2_d <= out2_d + 1;
    end
    
    else //else_2
     out1_d <= out1_d + 1;
   end 
   
   else //else_1
    out0_d <= out0_d + 1;
  end
end

//If count_reg == 500M - check if 'stop' key is pressed, if yes disable led, otherwise enable it. If count_reg ~= 500M keep led off.
assign led = ((count_reg == 500000000)?((game_stop == 1)?1'b0:1'b1):1'b0);
//if count_reg is 500M then check if the game has stopped. 
            //if true then disable led else ensble
//when count_reg is 500M then led must be off

endmodule
