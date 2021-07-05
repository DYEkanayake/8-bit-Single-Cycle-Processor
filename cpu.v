//E16096
//Lab6

`timescale 1ns/100ps

//module cpu(PC,INSTRUCTION,CLK,RESET);
//module cpu(PC,INSTRUCTION,CLK,RESET,READ,WRITE_DATAMEM,ALURESULT,OUT1,readdata,busywait);
module cpu(PC,INSTRUCTION,CLK,RESET,READ,WRITE_DATAMEM,ALURESULT,OUT1,readdata,busywait,instr_busywait,instr_read);

//inputs and outputs***********

	input [31:0] INSTRUCTION;
	input CLK,RESET;
	output reg [31:0] PC;
	
	output READ;
	output WRITE_DATAMEM; 
	output [7:0] ALURESULT;
	output [7:0] OUT1;
	
	input [7:0] readdata;
	input busywait;	
	
	input instr_busywait;
	output instr_read;
	
//wires***********
	
	wire [31:0] PC_next; //to hold the value of PC+4  
	wire [31:0] PC_branch; //to hold the value of pc+4+offset
	wire [31:0] PC_updated; //updated value of pc(for the instruction at next positive clock edge)
	
	wire [31:0] unshifted_offset; //immediate value of INSTRUCTION[23:16] sign-extended 
	wire [31:0] shifted_offset; //offset at branch (sign-extended value left-shifted by 2 to get offset)
	
	wire [7:0] ALURESULT,OUT1,OUT2,OUT2_NEG,DATA2,OPERAND2,OPERAND_2; 
	
	wire [7:0] Temp_RESULT;
	
	
	
	wire [7:0] readdata;  //################
	wire busywait; 
	wire [7:0] IN;

	wire instr_busywait;
	
//Control signals***********
	
	reg WRITE;	//writing to registers in register file is enabled
	
	reg mux_immediate,mux_signed;   //control signal for taking 2's compliment of operand 2 in sub and immediate for alu
	
	reg [2:0] ALUOP;  //select value for relevant function of alu
	
	reg BRANCH;  //control signal to indicate a branch instruction
	reg JUMP;   //control signal to indicate a jump instruction
	reg BNE;
	
	wire ZERO; //zero flag to indicate whether the result of alu(ALURESULT) is zero.(ZERO is an output of alu)
	
	reg RIGHT;  //control signal to indicate whether shift instruction is right(if right,RIGHT=1)
	
	reg mux_shift;  //control signal for taking shifted values to be forwarded to ALURESULT
	
	 // #############
	reg mux_datamem;  //control signal for the mux which selects between the alu result and  readdata to be written to register file.
	reg READ;   //Control signal to control reading to data memory 
	reg WRITE_DATAMEM;  //Control signal to control writing to data memory
	
	reg instr_read;
//PC handling*******
	
	assign #1 PC_next=PC+4;  //#1 of adder delay when pc is updated by 4
	assign #2 PC_branch=PC_next+shifted_offset; //#2 of adder delay when pc is updated by offset
	
	/*PC_next(PC+4) and  PC_branch(PC_next+shifted_offset) is passed to muxbranch(a mux_32bit) where the select signal would be ((BRANCH&&ZERO)||JUMP) and mux output
	be PC_updated . 
	PC_updated=PC_branch in case of (BRANCH&&ZERO)=1 or JUMP=1 i.e. in case of beq when the condition is satisfied(ZERO=1) and in case of j)
	Else,PC_updated=PC_next i.e.BRANCH&&ZERO=0 and JUMP=0.
	*/
	wire b;  //output of (BRANCH&&ZERO)
	wire j; //output of ((BRANCH&&ZERO)||JUMP)
	
	wire ZERO_NEG; //output of ~ZERO
	wire bn; //output of (BNE&&~ZERO)
	
	sign_extend sign_extend1(unshifted_offset,INSTRUCTION[23:16]); //unshifted_offset is the sign-extended(to able to add to PC of 32 bit) value of INSTRUCTION[23:16]
	left_shift left_shift1(shifted_offset,unshifted_offset);  //left-shifted of sign-extended INSTRUCTION[23:16](4xNo.of instructions to skip,giving # bytes)
	and a1(b,BRANCH,ZERO);
	not n1(ZERO_NEG,ZERO);
	and a2(bn,BNE,ZERO_NEG);
	or o1(j,b,JUMP,bn);
	mux_32bit muxbranch(PC_updated,j,PC_next,PC_branch); 	//setting PC for next Instruction(slecting from mux_32bit)
	
	
				
	//decoding(delay of #1)
	always @ (INSTRUCTION) begin 
		
		READ=1'b0;     //###########################
		WRITE_DATAMEM=1'b0;
		
		case(INSTRUCTION[31:24])  //opcode
			
			8'd0 : #1 begin            //loadi
						WRITE=1'b1;
						ALUOP=3'b000;
						mux_immediate=1'b0;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end
			
			8'd1 : #1 begin            //mov
						WRITE=1'b1;
						ALUOP=3'b000;
						mux_immediate=1'b1;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end
					
			8'd2 : #1 begin            //add
						WRITE=1'b1;
						ALUOP=3'b001;
						mux_immediate=1'b1;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end
					
			8'd3 : #1 begin            //sub
						WRITE=1'b1;
						ALUOP=3'b001;
						mux_immediate=1'b1;
						mux_signed=1'b1;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end
					
			8'd4 : #1 begin            //and
						WRITE=1'b1;
						ALUOP=3'b010;
						mux_immediate=1'b1;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end
			
			8'd5 : #1 begin            //or
						WRITE=1'b1;
						ALUOP=3'b011;
						mux_immediate=1'b1;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end
					
			8'd6 : #1 begin            //j
						WRITE=1'b0;
						ALUOP=3'b111;  //undefined aluop (result would be don't care)
						mux_immediate=1'b1;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b1;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end  
		
			
			8'd7 : #1 begin            //beq
						WRITE=1'b0;
						ALUOP=3'b001;
						mux_immediate=1'b1;
						mux_signed=1'b1;
						mux_shift=1'b0;
						
						BRANCH=1'b1;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end		
					
					
			
			
			
			
			8'd8 : #1 begin            //lwd  ############################
						WRITE=1'b1;
						ALUOP=3'b000;
						mux_immediate=1'b1;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b1;   
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b1;
					end		
					
					
			8'd9 : #1 begin            //lwi  ############################
						WRITE=1'b1;
						ALUOP=3'b000;
						mux_immediate=1'b0;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b1;   
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b1;
					end		
			
			8'd10 : #1 begin            //swd  ############################
						WRITE=1'b0;
						ALUOP=3'b000;
						mux_immediate=1'b1;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;   
						WRITE_DATAMEM=1'b1;
						mux_datamem=1'b1;
					end		
			
			8'd11 : #1 begin            //swi  ############################
						WRITE=1'b0;
						ALUOP=3'b000;
						mux_immediate=1'b0;
						mux_signed=1'b0;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b0;
						
						READ=1'b0;   
						WRITE_DATAMEM=1'b1;
						mux_datamem=1'b1;
					end		
					
			
			
			//Some of the instructions added in lab5 part 5 has the same opcodes used for swi and lwi. The compiler I submitted for lab5 won't match this part1 of Lab 6. Therefore, 
			//the below instructions are not defined in this part of lab6.
			
			/*8'd10 : #1 begin            //sll
						WRITE=1'b1;
						ALUOP=3'b000;  //shifted value forwarded to ALURESULT
						mux_immediate=1'b1;
						mux_signed=1'b1;
						mux_shift=1'b1;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						RIGHT=1'b0;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end		
					
			8'd11 : #1 begin            //slr
						WRITE=1'b1;
						ALUOP=3'b000;  //shifted value forwarded to ALURESULT
						mux_immediate=1'b1;
						mux_signed=1'b1;
						mux_shift=1'b1;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						RIGHT=1'b1;
						BNE=1'b0;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end		
					
			8'd12 : #1 begin            //bne
						WRITE=1'b0;
						ALUOP=3'b001;
						mux_immediate=1'b1;
						mux_signed=1'b1;
						mux_shift=1'b0;
						
						BRANCH=1'b0;
						JUMP=1'b0;
						BNE=1'b1;
						
						READ=1'b0;     //###########################
						WRITE_DATAMEM=1'b0;
						mux_datamem=1'b0;
						
					end		
			
			*/
			//default: 
		endcase	
	end
	

	always @ (posedge CLK) begin
		if(!RESET) begin #1
			//#1 PC=PC_next; 
			//if(!busywait) begin //###################
			
			if((!busywait)&&(!instr_busywait)) begin
			
			//#1 PC=PC_updated;  //pc update delay of #1
			PC=PC_updated; 
				if(PC==-4) 
					instr_read=0;
				else
					instr_read=1;
			
			end  //###################
		end
	end
		
	always @ (RESET) begin
		#1 PC=-32'd4;  //pc update delay (at reset) of #1
		
		BRANCH=1'b0;   
		JUMP=1'b0;
		BNE=1'b0;
	
	end	

	/*UPto part5 lab5	
	reg_file reg_file_1(ALURESULT, OUT1, OUT2,INSTRUCTION[18:16],INSTRUCTION[10:8],INSTRUCTION[2:0],WRITE,CLK,RESET);
	barrel_shifter bs1(OUT1,INSTRUCTION[2:0],Temp_RESULT,RIGHT);
	compliment negated(OUT2_NEG,OUT2);
	mux muxsigned(DATA2,mux_signed,OUT2,OUT2_NEG);
	mux muximmediate(OPERAND2,mux_immediate,INSTRUCTION[7:0],DATA2);
	mux muxshift(OPERAND_2,mux_shift,OPERAND2,Temp_RESULT);
	alu alu_1(OUT1,OPERAND_2,ALURESULT,ZERO,ALUOP); */
	
	
	
	//##############################################
	reg_file reg_file_1(IN, OUT1, OUT2,INSTRUCTION[18:16],INSTRUCTION[10:8],INSTRUCTION[2:0],WRITE,CLK,RESET,busywait,instr_busywait);//May use gate level AND for (WRITE&&busywait)
	barrel_shifter bs1(OUT1,INSTRUCTION[2:0],Temp_RESULT,RIGHT);
	compliment negated(OUT2_NEG,OUT2);
	mux muxsigned(DATA2,mux_signed,OUT2,OUT2_NEG);
	mux muximmediate(OPERAND2,mux_immediate,INSTRUCTION[7:0],DATA2);
	mux muxshift(OPERAND_2,mux_shift,OPERAND2,Temp_RESULT);
	
	alu alu_1(OUT1,OPERAND_2,ALURESULT,ZERO,ALUOP);
	//alu_3 alu_13(OUT1,OPERAND_2,ALURESULT,ZERO,ALUOP);
	
	//data_memory datamemory(CLK,RESET,READ,WRITE_DATAMEM,ALURESULT,OUT1,readdata,busywait);
	mux muxdatamem(IN,mux_datamem,ALURESULT,readdata);


//MODULE INTERFACES:
//data_memory(clk,reset,read,write,address,writedata,readdata,busywait);			
//reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);
//alu(DATA1, DATA2, RESULT,ZERO,SELECT);  			
		

endmodule


module mux(OUPUT,SELECT,INPUT_1,INPUT_2);  //mux of 8 bit

	input [7:0] INPUT_1,INPUT_2;  
	input SELECT;
	output reg [7:0] OUPUT;
	
	always @ (*) begin
		if(SELECT==0) begin
			 OUPUT=INPUT_1;
		end
		else begin
			 OUPUT=INPUT_2; 
		end
	end
	
	
endmodule


		
module compliment(OUTPUT,INPUT); //module to take the 2's compliment to utilize add as sub
	input [7:0] INPUT;
	output signed [7:0] OUTPUT;

    //assign OUTPUT=-INPUT;
	assign #1 OUTPUT=-INPUT;
	
endmodule


module sign_extend(OUPUT,INPUT);  //sign-extending of 8 bit input into 32 bit
	input [7:0] INPUT;
	output reg [31:0] OUPUT;
		
	always @ (*) begin
		OUPUT[7:0]=INPUT[7:0];
	
		if(INPUT[7]==1'b0) begin
			OUPUT[31:8]=24'b000000000000000000000000;
		end 
		else begin
			OUPUT[31:8]=24'b111111111111111111111111;
		end
	end
endmodule

module left_shift(OUPUT,INPUT);  //left-shift by 2(multiplication by 4)
	input [31:0] INPUT;
	output reg [31:0] OUPUT;
	
	always @ (*) begin
		OUPUT[1:0]=2'b00;
		OUPUT[31:2]=INPUT[29:0];
	end

endmodule

module mux_32bit(OUPUT,SELECT,INPUT_1,INPUT_2); //mux of 32 bit

	input [31:0] INPUT_1,INPUT_2;  
	input SELECT;
	output reg [31:0] OUPUT;
	
	always @ (*) begin
		if(SELECT==0) begin
			 OUPUT=INPUT_1;
		end
		else begin
			 OUPUT=INPUT_2; 
		end
	end
	
	
endmodule

module barrel_shifter(DATA1,DATA2,RESULT,RIGHT);//for sll and srl(without delays) 
	input [7:0] DATA1;
	input [2:0] DATA2;
	input RIGHT;
	
	output wire [7:0] RESULT;
	
	wire [7:0] O1,O2,O3,l1,l2,l3;
	
	//right
	mux_1bit mr1_1(O1[0],DATA2[0],DATA1[7],1'b0);
	mux_1bit mr1_2(O1[1],DATA2[0],DATA1[6],DATA1[7]);
	mux_1bit mr1_3(O1[2],DATA2[0],DATA1[5],DATA1[6]);
	mux_1bit mr1_4(O1[3],DATA2[0],DATA1[4],DATA1[5]);
	mux_1bit mr1_5(O1[4],DATA2[0],DATA1[3],DATA1[4]);
	mux_1bit mr1_6(O1[5],DATA2[0],DATA1[2],DATA1[3]);
	mux_1bit mr1_7(O1[6],DATA2[0],DATA1[1],DATA1[2]);
	mux_1bit mr1_8(O1[7],DATA2[0],DATA1[0],DATA1[1]);
	
	mux_1bit mr2_1(O2[0],DATA2[1],O1[0],1'b0);
	mux_1bit mr2_2(O2[1],DATA2[1],O1[1],1'b0);
	mux_1bit mr2_3(O2[2],DATA2[1],O1[2],O1[0]);
	mux_1bit mr2_4(O2[3],DATA2[1],O1[3],O1[1]);
	mux_1bit mr2_5(O2[4],DATA2[1],O1[4],O1[2]);
	mux_1bit mr2_6(O2[5],DATA2[1],O1[5],O1[3]);
	mux_1bit mr2_7(O2[6],DATA2[1],O1[6],O1[4]);
	mux_1bit mr2_8(O2[7],DATA2[1],O1[7],O1[5]);
	
	mux_1bit mr3_1(O3[0],DATA2[2],O2[0],1'b0);
	mux_1bit mr3_2(O3[1],DATA2[2],O2[1],1'b0);
	mux_1bit mr3_3(O3[2],DATA2[2],O2[2],1'b0);
	mux_1bit mr3_4(O3[3],DATA2[2],O2[3],1'b0);
	mux_1bit mr3_5(O3[4],DATA2[2],O2[4],O2[0]);
	mux_1bit mr3_6(O3[5],DATA2[2],O2[5],O2[1]);
	mux_1bit mr3_7(O3[6],DATA2[2],O2[6],O2[2]);
	mux_1bit mr3_8(O3[7],DATA2[2],O2[7],O2[3]);
	
	
	//left
	mux_1bit ml1_1(l1[0],DATA2[0],DATA1[0],1'b0);
	mux_1bit ml1_2(l1[1],DATA2[0],DATA1[1],DATA1[0]);
	mux_1bit ml1_3(l1[2],DATA2[0],DATA1[2],DATA1[1]);
	mux_1bit ml1_4(l1[3],DATA2[0],DATA1[3],DATA1[2]);
	mux_1bit ml1_5(l1[4],DATA2[0],DATA1[4],DATA1[3]);
	mux_1bit ml1_6(l1[5],DATA2[0],DATA1[5],DATA1[4]);
	mux_1bit ml1_7(l1[6],DATA2[0],DATA1[6],DATA1[5]);
	mux_1bit ml1_8(l1[7],DATA2[0],DATA1[7],DATA1[6]);
	
	mux_1bit ml2_1(l2[0],DATA2[1],l1[0],1'b0);
	mux_1bit ml2_2(l2[1],DATA2[1],l1[1],1'b0);
	mux_1bit ml2_3(l2[2],DATA2[1],l1[2],l1[0]);
	mux_1bit ml2_4(l2[3],DATA2[1],l1[3],l1[1]);
	mux_1bit ml2_5(l2[4],DATA2[1],l1[4],l1[2]);
	mux_1bit ml2_6(l2[5],DATA2[1],l1[5],l1[3]);
	mux_1bit ml2_7(l2[6],DATA2[1],l1[6],l1[4]);
	mux_1bit ml2_8(l2[7],DATA2[1],l1[7],l1[5]);
	
	mux_1bit ml3_1(l3[0],DATA2[2],l2[0],1'b0);
	mux_1bit ml3_2(l3[1],DATA2[2],l2[1],1'b0);
	mux_1bit ml3_3(l3[2],DATA2[2],l2[2],1'b0);
	mux_1bit ml3_4(l3[3],DATA2[2],l2[3],1'b0);
	mux_1bit ml3_5(l3[4],DATA2[2],l2[4],l2[0]);
	mux_1bit ml3_6(l3[5],DATA2[2],l2[5],l2[1]);
	mux_1bit ml3_7(l3[6],DATA2[2],l2[6],l2[2]);
	mux_1bit ml3_8(l3[7],DATA2[2],l2[7],l2[3]);
	
	
	
	//final with right control signal
	mux_1bit ms1(RESULT[7],RIGHT,l3[7],O3[0]);
	mux_1bit ms2(RESULT[6],RIGHT,l3[6],O3[1]);
	mux_1bit ms3(RESULT[5],RIGHT,l3[5],O3[2]);
	mux_1bit ms4(RESULT[4],RIGHT,l3[4],O3[3]);
	mux_1bit ms5(RESULT[3],RIGHT,l3[3],O3[4]);
	mux_1bit ms6(RESULT[2],RIGHT,l3[2],O3[5]);
	mux_1bit ms7(RESULT[1],RIGHT,l3[1],O3[6]);
	mux_1bit ms8(RESULT[0],RIGHT,l3[0],O3[7]);
	
		
endmodule
	

module  mux_1bit(OUPUT,SELECT,INPUT_1,INPUT_2); //mux of 32 bit

	input  INPUT_1,INPUT_2;  
	input SELECT;
	output reg OUPUT;
	
	always @ (*) begin
		if(SELECT==0) begin
			 OUPUT=INPUT_1;
		end
		else begin
			 OUPUT=INPUT_2; 
		end
	end
	
	
endmodule

