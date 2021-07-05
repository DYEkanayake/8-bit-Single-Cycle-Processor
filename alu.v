//E16096
//Lab6_alu_modified

`timescale 1ns/100ps

module alu(DATA1, DATA2, RESULT,ZERO,SELECT); 

	input [7:0] DATA1,DATA2;
	input [2:0] SELECT;
	output [7:0] RESULT;
	output wire ZERO;
	
	reg [7:0] RESULT;
	
	reg [7:0] res_forward,res_add,res_and,res_or; //intermediates for each alu operation
	
	
	//FORWARD function(forward DATA2 into RESULT) (with delay #1)	
	always @(DATA1,DATA2,SELECT)
	begin
		#1 res_forward=DATA2;
	end
	
	//ADD function(add DATA1 and DATA2) (with delay #2)
	always @(DATA1,DATA2,SELECT)
	begin
		#2 res_add=DATA1+DATA2;
	end
	
	//AND function(bitwise AND on DATA1 with DATA2) (with delay #1)
	always @(DATA1,DATA2,SELECT)
	begin
		#1 res_and=DATA1&DATA2;
	end
	
	//OR function(bitwise OR on DATA1 with DATA2) (with delay #1)
	always @(DATA1,DATA2,SELECT)
	begin
		#1 res_or=DATA1|DATA2;
	end
	
	
	always @ (*) 
	begin
		case (SELECT)  //defining the function for the result based on SELECT input
			
			3'b000 : RESULT=res_forward; //SELECT=000 corresponds to FORWARD function(forward DATA2 into RESULT) (with delay #1)
					
			3'b001 : RESULT=res_add; //SELECT=001 corresponds to ADD function(add DATA1 and DATA2) (with delay #2)
					
			3'b010 : RESULT=res_and; //SELECT=010 corresponds to AND function(bitwise AND on DATA1 with DATA2) (with delay #1)
					
			3'b011 : RESULT=res_or; //SELECT=011 corresponds to OR function(bitwise OR on DATA1 with DATA2) (with delay #1)	
							
			default: RESULT=8'bx; //Reserved inputs for SELECT(for other bit combinations concerning the 1st bit) is considered a don't-care(x) condition at this stage                                                               			
					
		endcase

	end
	
	nor n1(ZERO,RESULT[0],RESULT[1],RESULT[2],RESULT[3],RESULT[4],RESULT[5],RESULT[6],RESULT[7]);
		
						
	
endmodule

