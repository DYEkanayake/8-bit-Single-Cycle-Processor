/*
Program	: 256x8-bit data memory (16-Byte blocks)
Author	: Isuru Nawinne
Date	: 10/06/2020

Description	:

This program presents a primitive instruction memory module for CO224 Lab 6 - Part 3
This memory allows instructions to be read as 16-Byte blocks
*/

module instr_memory(
//module data_memory(
    clock,
    read,
    address,
    readdata,
    busywait
);
input               clock;
input               read;
input[5:0]          address;
output reg [127:0]  readdata;
output reg          busywait;

reg readaccess;

//Declare memory array 1024x8-bits 
reg [7:0] memory_array [1023:0];


//Initialize instruction memory
initial
begin
    busywait = 0;
    readaccess = 0;

    // Sample program given below. You may hardcode your software program here, or load it from a file:
  /*
	{memory_array[10'd3],  memory_array[10'd2],  memory_array[10'd1],  memory_array[10'd0]}  = 32'b00000000000001000000000000011001; // loadi 4 #25
    {memory_array[10'd7],  memory_array[10'd6],  memory_array[10'd5],  memory_array[10'd4]}  = 32'b00000000000001010000000000100011; // loadi 5 #35
    {memory_array[10'd11], memory_array[10'd10], memory_array[10'd9],  memory_array[10'd8]}  = 32'b00000010000001100000010000000101; // add 6 4 5
    {memory_array[10'd15], memory_array[10'd14], memory_array[10'd13], memory_array[10'd12]} = 32'b00000000000000010000000001011010; // loadi 1 90
    {memory_array[10'd19], memory_array[10'd18], memory_array[10'd17], memory_array[10'd16]} = 32'b00000011000000010000000100000100; // sub 1 1 4
	
	*/
			
			{memory_array[10'd3], memory_array[10'd2], memory_array[10'd1], memory_array[10'd0]}=32'b00000000000000010000000000000110;   //loadi 1 0x06
			{memory_array[10'd7], memory_array[10'd6], memory_array[10'd5], memory_array[10'd4]}=32'b00000000000000100000000000000100;   //loadi 2 0x04
			{memory_array[10'd11], memory_array[10'd10], memory_array[10'd9], memory_array[10'd8]}=32'b00001010000000000000000100000010;   //swd 1 2
			{memory_array[10'd15], memory_array[10'd14], memory_array[10'd13], memory_array[10'd12]}=32'b00000010000000110000000100000010;  //add 3 1 2
			{memory_array[10'd19], memory_array[10'd18], memory_array[10'd17], memory_array[10'd16]}=32'b00001000000001000000000000000010;  //lwd 4 2
			{memory_array[10'd23], memory_array[10'd22], memory_array[10'd21], memory_array[10'd20]}=32'b00000011000001100000001100000100;  //sub 6 3 4
			{memory_array[10'd27], memory_array[10'd26], memory_array[10'd25], memory_array[10'd24]}=32'b00000100000001010000000100000010;  //and 5 1 2
			{memory_array[10'd31], memory_array[10'd30], memory_array[10'd29], memory_array[10'd28]}=32'b00000101000001110000000100000010;  //or 7 1 2
			{memory_array[10'd35], memory_array[10'd34], memory_array[10'd33], memory_array[10'd32]}=32'b00001011000000000000001000001000;  //swi 2 0x08
			{memory_array[10'd39], memory_array[10'd38], memory_array[10'd37], memory_array[10'd36]}=32'b00001001000001010000000000001000;  //lwi 5 0x08
			{memory_array[10'd43], memory_array[10'd42], memory_array[10'd41], memory_array[10'd40]}=32'b00000111000000010000000100000010;  //beq 0x01 1 2
			{memory_array[10'd47], memory_array[10'd46], memory_array[10'd45], memory_array[10'd44]}=32'b00000111000000100000001000000101;  //beq 0x02 2 5
			{memory_array[10'd51], memory_array[10'd50], memory_array[10'd49], memory_array[10'd48]}=32'b00000010000001110000000100000011;  //add 7 1 3
			{memory_array[10'd55], memory_array[10'd54], memory_array[10'd53], memory_array[10'd52]}=32'b00000001000001010000000000000111;  //mov 5 7
			{memory_array[10'd59], memory_array[10'd58], memory_array[10'd57], memory_array[10'd56]}=32'b00000110000000010000000000000000;  //j 0x01
			{memory_array[10'd63], memory_array[10'd62], memory_array[10'd61], memory_array[10'd60]}=32'b00000000000000010000000000000101;  //loadi 1 0x05
			
			{memory_array[10'd67], memory_array[10'd66], memory_array[10'd65], memory_array[10'd64]}=32'b00000010000001010000000100000010;  //add 5 1 2
			{memory_array[10'd71], memory_array[10'd70], memory_array[10'd69], memory_array[10'd68]}=32'b00001000000001110000000000000010;  //lwd 7 2
			{memory_array[10'd75], memory_array[10'd74], memory_array[10'd73], memory_array[10'd72]}=32'b00001001000001010000000000001000;  //lwi 5 0x08
			{memory_array[10'd79], memory_array[10'd78], memory_array[10'd77], memory_array[10'd76]}=32'b00000010000001100000010100000111;  //add 6 5 7
			{memory_array[10'd83], memory_array[10'd82], memory_array[10'd81], memory_array[10'd80]}=32'b00001011000000000000001100000101;  //swi 3 0x05 
			{memory_array[10'd87], memory_array[10'd86], memory_array[10'd85], memory_array[10'd84]}=32'b00001010000000000000001000000001;  //swd 2 1
			{memory_array[10'd91], memory_array[10'd90], memory_array[10'd89], memory_array[10'd88]}=32'b00001001000001010000000000000101;  //lwi 5 0x05
			{memory_array[10'd95], memory_array[10'd94], memory_array[10'd93], memory_array[10'd92]}=32'b00001000000001110000000000000001;  //lwd 7 1
			{memory_array[10'd99], memory_array[10'd98], memory_array[10'd97], memory_array[10'd96]}=32'b00000010000001100000010100000111;  //add 6 5 7
		
	
	
end

//Detecting an incoming memory access
always @(read)
begin
    busywait = (read)? 1 : 0;
    readaccess = (read)? 1 : 0;
end

//Reading
always @(posedge clock)
begin
    if(readaccess)
    begin
        readdata[7:0]     = #40 memory_array[{address,4'b0000}];
        readdata[15:8]    = #40 memory_array[{address,4'b0001}];
        readdata[23:16]   = #40 memory_array[{address,4'b0010}];
        readdata[31:24]   = #40 memory_array[{address,4'b0011}];
        readdata[39:32]   = #40 memory_array[{address,4'b0100}];
        readdata[47:40]   = #40 memory_array[{address,4'b0101}];
        readdata[55:48]   = #40 memory_array[{address,4'b0110}];
        readdata[63:56]   = #40 memory_array[{address,4'b0111}];
        readdata[71:64]   = #40 memory_array[{address,4'b1000}];
        readdata[79:72]   = #40 memory_array[{address,4'b1001}];
        readdata[87:80]   = #40 memory_array[{address,4'b1010}];
        readdata[95:88]   = #40 memory_array[{address,4'b1011}];
        readdata[103:96]  = #40 memory_array[{address,4'b1100}];
        readdata[111:104] = #40 memory_array[{address,4'b1101}];
        readdata[119:112] = #40 memory_array[{address,4'b1110}];
        readdata[127:120] = #40 memory_array[{address,4'b1111}];
        busywait = 0;
        readaccess = 0;
    end
end
 
endmodule