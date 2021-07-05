//E16096
//Lab5_part2

`timescale 1ns/100ps

module cpu_testbench;

	wire [31:0] PC;
	wire [31:0] INSTRUCTION;
	reg CLK,RESET;

	//reg [7:0] instr_mem[1023:0]; //instruction memory of 1024 bytes represented in the testbench by 256 8 bit registers(4 registers storing 1 instruction of 32 bits)

/////////////////////////////////
	wire READ;
	wire WRITE_DATAMEM;
	wire [7:0] ALURESULT;
	wire [7:0] OUT1;
	
	wire [7:0] readdata;
	wire busywait;
	
	wire  mem_read ;
    wire mem_write ;
    wire [5:0] mem_address ;
    wire [31:0] mem_writedata ;
	wire [31:0] mem_readdata ;
    wire mem_busywait;
////////////////////////////////

	
	wire instrmem_read;
	wire [5:0] instrmem_address;
	wire [127:0] instrmem_readdata;
	wire instrmem_busywait;
	wire instr_busywait;
	wire instr_read;
	
////////////////////////////////



	
	//pc is updated only at the clock edge(delay #1) hence the INSTRUCTION(delay #2 after pc update)
	//assign	#2 INSTRUCTION={instr_mem[PC+3],instr_mem[PC+2], instr_mem[PC+1], instr_mem[PC+0]}; 
																					

	
	//cpu mycpu(PC,INSTRUCTION,CLK,RESET);
	
	/*
	cpu mycpu(PC,INSTRUCTION,CLK,RESET,READ,WRITE_DATAMEM,ALURESULT,OUT1,readdata,busywait);
	data_memory datamemory(CLK,RESET,READ,WRITE_DATAMEM,ALURESULT,OUT1,readdata,busywait);
	
	*/
	
	cpu mycpu(PC,INSTRUCTION,CLK,RESET,READ,WRITE_DATAMEM,ALURESULT,OUT1,readdata,busywait,instr_busywait,instr_read);
	dcache mydcache(CLK,RESET,ALURESULT,busywait,READ,WRITE_DATAMEM,OUT1,readdata,mem_busywait,mem_address,mem_read,mem_write,mem_writedata,mem_readdata);
	data_memory datamemory(CLK,RESET,mem_read,mem_write,mem_address,mem_writedata,mem_readdata,mem_busywait);

	instr_memory myinstr_memory(CLK,instrmem_read,instrmem_address,instrmem_readdata,instrmem_busywait);
	instr_cache myinstr_cache(CLK,RESET,PC,instr_read,INSTRUCTION,instrmem_address,instrmem_read,instrmem_readdata,instr_busywait,instrmem_busywait);
	
	
	
	initial
	begin

        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_testbench);
		
        CLK=1'b0;
		RESET=1'b0;
		
		 // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
		#1
		RESET=1'b1;
		
		#2
		RESET=1'b0;
		
		#15000
		$finish;
	end
	
	 always
        //#5 CLK = ~CLK;
		#4 CLK = ~CLK;
	
endmodule