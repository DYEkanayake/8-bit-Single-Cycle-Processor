//E/16/096

`timescale 1ns/100ps

module dcache(clock,reset,address,busywait,read,write,writedata,readdata,mem_busywait,mem_address,mem_read,mem_write,mem_writedata,mem_readdata);
    
	
	input clock;
	input reset;
	
	//to and from cpu
	input [7:0] address;
	input read;
	input write;
	input [7:0] writedata;
	
	output busywait;
	output [7:0] readdata;
	
	reg busywait;
	reg [7:0] readdata;
	
	//to and from data memory
	input mem_busywait;
	input [31:0] mem_readdata;
	
	output [5:0] mem_address;
	output mem_read;
	output mem_write;
	output [31:0] mem_writedata;
	
	reg [5:0] mem_address;
	reg mem_read;
	reg mem_write;
	reg [31:0] mem_writedata;
	
		
	//cache storage
	reg [31:0] cachedata [7:0];  // cache memory array(4 byte per block)
	reg [2:0] tag_block [7:0];   //this reg array keeps the tag per block of data in cache
	reg valid [7:0];   //this reg array keeps the valid bit per block
	reg dirty [7:0];   //this reg array keeps the dirty bit per block
	
	
	//cache_controller-BUSYWAIT ASSERTION
	
	always @ (address,read,write) 
	begin
		if(read || write)
			busywait=1;
		else
			busywait=0;
	end
	
	//cache_controller-BUSYWAIT DE-ASSERTION(in case of a hit)
	
	always @ (posedge clock)
	begin
		if(hit && (read || write))
		begin
			busywait=0;
		end
	end
	
	
	//Combinational part for indexing, tag comparison for hit deciding, etc.
   
    wire [2:0] index;
	wire [1:0] offset;
   
    wire [2:0] tag;
	reg [31:0] datablock;
	wire valid_bit;
	wire dirty_bit;
	
	
	//INDEXING
	
	assign index=address[4:2]; 
	assign offset=address[1:0];
	
	//extracting stored data(indexing latency of #1 time unit when extracting the stored values)
	always @ (*) begin
		#1 datablock=cachedata[index];
	end
	assign  #1 tag=tag_block[index];  
	assign  #1 valid_bit=valid[index];
	assign  #1 dirty_bit=dirty[index];
	
	
	
	//TAG COMPARISON 
	
	//(tag at tag_block[index] should match with address[7:5])
	wire tag_match;  //is 1 when a tag matches
	wire a,b,c,out;
	
	xnor xnor1(a,tag[0],address[5]); 
	xnor xnor2(b,tag[1],address[6]);
	xnor xnor3(c,tag[2],address[7]);
	and and1(out,a,b,c);
	
	//assign #1 tag_match=out;  
	assign #0.9 tag_match=out; // latency of #0.9 time units for the tag comparison
	
	
	//HIT DECIDING
	wire hit;
	and and2(hit,tag_match,valid_bit); //it's a hit iff the tag matches and the block is valid
	
	
	
    //*/
	//DATA WORD SELECTION + SENDING TO CPU
	reg [7:0] dataword; 
	always @ (*)
	begin 
			
		case(offset)
			2'd0: #1 dataword=datablock[7:0];
			2'd1: #1 dataword=datablock[15:8];
			2'd2: #1 dataword=datablock[23:16];
			2'd3: #1 dataword=datablock[31:24];
			
			
			
		endcase
		
		//Selecting the word from the block is done parallel to hit deciding but sent to cpu only if its a hit
		if(hit&& read) begin //Should this be (read && hit)
			readdata=dataword;
		end
	end
	
    //DATA WORD WRITING
	always @ (posedge clock)
	//always @ (hit)?????????
	begin 
		if (hit && write) begin
			#1
			dirty[index]=1'd1;
			case(offset)
				2'd0:  cachedata[index][7:0]=writedata;
				2'd1:  cachedata[index][15:8]=writedata;
				2'd2:  cachedata[index][23:16]=writedata;
				2'd3:  cachedata[index][31:24]=writedata;
				
				
			endcase
		end
	end
	
    /* Cache Controller FSM Start */

    parameter IDLE = 3'b00, MEM_READ = 3'b01 ,WRITE_BACK=3'b10, CACHE_UPDATE=3'b11;
    reg [2:0] state, next_state;

    // combinational next state logic
		
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read || write) && !dirty_bit && !hit)  
                    next_state = MEM_READ;
                else if ((read || write) && dirty_bit && !hit)
                    next_state = WRITE_BACK;
                else
                    next_state = IDLE;
			
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = CACHE_UPDATE;
                else    
                    next_state = MEM_READ;
					
			WRITE_BACK:
                if (!mem_busywait)
                    next_state = MEM_READ;
                else    
                    next_state = WRITE_BACK;
					
			CACHE_UPDATE:
                next_state = IDLE;  //at next posedge clock the busywait is deasserted
            
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 6'dx;
                mem_writedata = 6'dx;
               
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_write = 0;
                mem_address = address[7:2];
                mem_writedata = 32'dx;
               
            end
			
			WRITE_BACK:
			begin
                mem_read = 0;
                mem_write = 1;
                mem_address = {tag, index};
			    mem_writedata = datablock;
               
            end
			
			CACHE_UPDATE:
			begin 
                mem_read = 0;
                mem_write = 0;
                mem_address = 6'dx;
                mem_writedata =32'dx;
				
				#1 // latency of #1 time unit for writing operation(writing the fetched values to the cache memory)
				tag_block[index][2:0]=address[7:5];
				//cachedata[index]=mem_readdata;
				cachedata[index][7:0]=mem_readdata[7:0];
				cachedata[index][15:8]=mem_readdata[15:8];
				cachedata[index][23:16]=mem_readdata[23:16];
				cachedata[index][31:24]=mem_readdata[31:24];
				dirty[index]=1'b0;
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
				dirty[i] <= 0;
				//tag_block[i] <= 0; //NOT NECESSARY
				cachedata[i] <= 32'd0;
			end	
			busywait=0;
		end
	end
	
endmodule

