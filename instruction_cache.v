/*
E/16/096
Lab 06-part3(instruction cache module)
*/

`timescale 1ns/100ps

module instr_cache(clock,reset,PC,instr_read,readdata,mem_address,mem_read,mem_readdata,busywait,mem_busywait);

	//to and from cpu 
	input clock,reset;
	input [31:0] PC;
	input instr_read;

	output [31:0] readdata; //the instruction word
	output busywait;
	
	reg [31:0] readdata;
	reg busywait;
	
	//to and from instruction memory
	input mem_busywait;
	input [127:0] mem_readdata;  //the block that's being fetched from the instruction memory

	output [5:0] mem_address; //the address of the block to be fetched from the instruction memory
	output mem_read;

	reg [5:0] mem_address;
	reg mem_read;
	
	//instr_cache storage
	reg [127:0] cache_block [7:0];  // instr_cache memory array(16 byte per block)
	reg [2:0] tag_block [7:0];   //this reg array keeps the tag per block of data in instr_cache
	reg valid [7:0];   //this reg array keeps the valid bit per block


//Combinational part for indexing, tag comparison for hit deciding, etc.
  
/*
address corresponds to least significant 10 bits of PC(i.e. adress is PC[9:0])
Least significant 2 bits(i.e. address[1:0]) are 0 always.
For address,
tag is PC[9:7], 
index is PC[6:4],
word offset is PC[3:2].

*/  
	reg [9:0] address;
	
	always @ (PC) begin
		if(instr_read)
			address=PC[9:0];
	end
	
    wire [2:0] index; 
	wire [1:0] offset;
   
    wire [2:0] tag;
	wire [127:0] block;
	wire valid_bit;
	
	
	
	//INDEXING
	
	assign index=address[6:4]; 
	assign offset=address[3:2];
	
	//extracting stored data(indexing latency of #1 time unit when extracting the stored values)
	
	assign 	#1 block=cache_block[index];
	assign  #1 tag=tag_block[index];  
	assign  #1 valid_bit=valid[index];
		
	
	//TAG COMPARISON 
	
	//(tag at tag_block[index] should match with PC[9:7])
	wire tag_match;  //is 1 when a tag matches
	wire a,b,c,out;
	
	xnor xnor1(a,tag[0],address[7]); 
	xnor xnor2(b,tag[1],address[8]);
	xnor xnor3(c,tag[2],address[9]);
	and and1(out,a,b,c);
	
	assign #1 tag_match=out; // latency of #1 time units for the tag comparison
	
	
	//HIT DECIDING
	wire hit;
	and and2(hit,tag_match,valid_bit); //it's a hit iff the tag matches and the block is valid

	//INSTRUCTION WORD SELECTION + SENDING TO CPU
	reg [31:0] instruction; 
	always @ (*)
	
	begin 
		case(offset)
				2'd0: #1 instruction=block[31:0];
				2'd1: #1 instruction=block[63:32];
				2'd2: #1 instruction=block[95:64];
				2'd3: #1 instruction=block[127:96];
		endcase
		
		//Selecting the instruction word from the block is done parallel to hit deciding
		if(hit && instr_read) 
			readdata=instruction;

	end
	

	//busywait ASSERTION & DE-ASSERTION 
	always @(*) begin
		if(instr_read)
			busywait=1;
		else
			busywait=0;
	end
	
	
	always @ (posedge clock)
	begin
		if(hit)
			busywait=0;
			
	end
	
	
	
	
    /* Instruction Cache Controller FSM Start */

    parameter IDLE = 3'b00, MEM_READ = 3'b01 ,CACHE_UPDATE=3'b10;
    reg [2:0] state, next_state;

    // combinational next state logic
		
    always @(*)
    begin
        case (state)
            IDLE:
                if ((instr_read) && !hit)  
                    next_state = MEM_READ;
                else
                    next_state = IDLE;
			
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = CACHE_UPDATE;
                else    
                    next_state = MEM_READ;
									
			
			CACHE_UPDATE:
                next_state = IDLE;  
            
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
				mem_read = 0;
                mem_address = 6'dx;
				busywait=0;
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_address = address[9:4];
				busywait=1;
            end
			
						
			CACHE_UPDATE:
			begin 
                mem_read = 0;
                mem_address = 6'dx;
				busywait=1;
				
				#1 // latency of #1 time unit for writing operation(writing the fetched values to the cache memory)
				tag_block[index][2:0]=address[9:7];
				
				cache_block[index]=mem_readdata;
				/*
				
				cache_block[index][31:0]=mem_readdata[31:0];
				cache_block[index][63:32]=mem_readdata[63:32];
				cache_block[index][95:64]=mem_readdata[95:64];
				cache_block[index][127:96]=mem_readdata[127:96];
				
				*/
				valid[index]=1'b1;
                
            end
			
			
            
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge clock, reset)
    begin
        if(reset)
            state = IDLE;
		else
            state = next_state;
	
    end

    /* Cache Controller FSM End */
	
	integer i;
	always @(reset)begin				//Cache Reset
		if(reset)begin
			
			for (i=0; i<8; i=i+1)begin
				valid[i] <= 0;
				//tag_block[i] <= 0; //NOT NECESSARY
				cache_block[i] <= 128'd0; 
			end	
			busywait=0;
		end
	end
	
endmodule















