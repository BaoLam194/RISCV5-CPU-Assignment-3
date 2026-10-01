`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Tesing for RV32I Instructions
// lui, addi
// and(i), or(i), slt(i), sltu(i)
// lw, sw
// The assert is delayed 1 cycle because writing only happens at next cycle
//////////////////////////////////////////////////////////////////////////////////

// Mimicthe test_Wrapper_DIP_to_LED file
// File usage Basic_Functionality.asm

integer error_count = 0;


`define ERROR(msg, expected, result) \
    begin \
        error_count = error_count + 1; \
        $display(""); \
        $display("============================================================"); \
        $display("                    SOME TEST FAILED"); \
        $display("============================================================"); \
        $error("        Instruction check failed: %s",msg); \
        $display("        Expected: %h, got %h.", expected, result); \
        $display("============================================================"); \
    end

module test_Wrapper_BF #(
	   parameter N_LEDs_OUT	= 8,					
	   parameter N_DIPs		= 16,
	   parameter N_PBs		= 3,
       parameter init_DIPs  = 16'ha80f
	)
	(
	);
	
	// Signals for the Unit Under Test (UUT)
	reg  [N_DIPs-1:0] DIP = init_DIPs;		
	reg  [N_PBs-1:0] PB = 0;			
	wire [N_LEDs_OUT-1:0] LED_OUT;
	wire [6:0] LED_PC;			
	wire [31:0] SEVENSEGHEX;	
	wire [7:0] UART_TX;
	reg  UART_TX_ready = 0;
	wire UART_TX_valid;
	reg  [7:0] UART_RX = 0;
	reg  UART_RX_valid = 0;
	wire UART_RX_ack;
	wire OLED_Write;
	wire [6:0] OLED_Col;
	wire [5:0] OLED_Row;
	wire [23:0] OLED_Data;
	reg [31:0] ACCEL_Data;
	wire ACCEL_DReady;			
	reg  RESET = 0;	
	reg  CLK = 0;				
	
	// Instantiate UUT
    Wrapper dut(DIP, PB, LED_OUT, LED_PC, SEVENSEGHEX, UART_TX, UART_TX_ready, UART_TX_valid, UART_RX, UART_RX_valid, UART_RX_ack, OLED_Write, OLED_Col, OLED_Row, OLED_Data, ACCEL_Data, ACCEL_DReady, RESET, CLK) ;

	
	// Note: This testbench is for DIP_to_LED program. Other assembly programs require appropriate modifications.
	// STIMULI
    initial
    begin
        RESET = 1; #10; RESET = 0; //hold reset state for 10 ns.
        #30
        assert(dut.RV1.RegFile1.RegBank[8] === 32'hffff0000) else `ERROR("li s0, MMIO_BASE instrution is failed", 32'hffff0000, dut.RV1.RegFile1.RegBank[8]);
        #30; // the "and" instruction is executed,
        
        #10; // the "andi" instruction is executed,
        assert(dut.RV1.RegFile1.RegBank[14] === 32'h40) else `ERROR("and instrution is failed", 32'h40, dut.RV1.RegFile1.RegBank[14]);
        
        #10; // the "or" instruction is executed,
        assert(dut.RV1.RegFile1.RegBank[15] === 32'h58) else `ERROR("andi instrution is failed", 32'h58, dut.RV1.RegFile1.RegBank[15]);
        
        #10; // the "ori" instruction is executed,
        assert(dut.RV1.RegFile1.RegBank[16] === 32'hfffffff8) else `ERROR("or instrution is failed", 32'hfffffff8, dut.RV1.RegFile1.RegBank[16]);
        
        #10; // the "slt" instruction is executed,
        assert(dut.RV1.RegFile1.RegBank[17] === 32'h404) else `ERROR("ori instrution is failed", 32'h404, dut.RV1.RegFile1.RegBank[17]);
        
        #10; // the "slt" instruction is executed,
        assert(dut.RV1.RegFile1.RegBank[24] === 32'h1) else `ERROR("slt instrution is failed", 32'h1, dut.RV1.RegFile1.RegBank[24]);
       
        #10; // the "sltu" instruction is executed,
        assert(dut.RV1.RegFile1.RegBank[25] === 32'h0) else `ERROR("slt instrution is failed", 32'h0, dut.RV1.RegFile1.RegBank[25]);
        
        #10; // the "sltu" instruction is executed,
        assert(dut.RV1.RegFile1.RegBank[26] === 32'h1) else `ERROR("sltu instrution is failed", 32'h1, dut.RV1.RegFile1.RegBank[26]);
        
        #10; // la instruction line 72
        assert(dut.RV1.RegFile1.RegBank[27] === 32'h0) else `ERROR("sltu instrution is failed", 32'h0, dut.RV1.RegFile1.RegBank[27]);
        
        #20; // lw instruction is executed
        assert(dut.RV1.RegFile1.RegBank[9] === 32'h10010000) else `ERROR("la instrution is failed", 32'h10010000, dut.RV1.RegFile1.RegBank[9]);

        #10; // sub instruction line 74 is executed        
        #10; // sw instruction line 75 is executed
        assert(dut.RV1.RegFile1.RegBank[18] === 32'h2) else `ERROR("lw instrution is failed", 32'h2, dut.RV1.RegFile1.RegBank[18]);

        #10; // slti instruction line 76 is executed
        assert(dut.RV1.RegFile1.RegBank[18] === 32'h2) else `ERROR("sw instrution is failed", 32'h2, dut.RV1.RegFile1.RegBank[18]);
        assert(dut.DMEM[0] === 32'h2) else `ERROR("sw instrution is failed", 32'h2, dut.DMEM[0]);

        #10; // sltiu instruction line 77 is executed
        assert(dut.RV1.RegFile1.RegBank[19] === 32'h0) else `ERROR("slti instrution is failed", 32'h0, dut.RV1.RegFile1.RegBank[19]);

        #10; // xor instruction line 78 is executed
        assert(dut.RV1.RegFile1.RegBank[20] === 32'h1) else `ERROR("sltiu instrution is failed", 32'h1, dut.RV1.RegFile1.RegBank[20]);
        
        #10; // xori instruction line 79 is executed
        assert(dut.RV1.RegFile1.RegBank[21] === 32'h3) else `ERROR("xor instrution is failed", 32'h3, dut.RV1.RegFile1.RegBank[21]);

        #10; // beq instruction line 80 is executed
        assert(dut.RV1.RegFile1.RegBank[22] === 32'h5) else `ERROR("xori instrution is failed", 32'h5, dut.RV1.RegFile1.RegBank[22]);

        #10; // beq instruction line 81 is executed
        assert(dut.RV1.PC === 32'h00400060) else `ERROR("beq instrution is failed", 32'h00400060, dut.RV1.PC);
       
        #10; // bne instruction line 84 is executed
        assert(dut.RV1.PC === 32'h00400068) else `ERROR("beq instrution is failed", 32'h00400068, dut.RV1.PC);

        #10; // bne instruction line 85 is executed
        assert(dut.RV1.PC === 32'h0040006c) else `ERROR("bne instrution is failed", 32'h0040006c, dut.RV1.PC);

        #10; // blt instruction line 88 is executed
        assert(dut.RV1.PC === 32'h00400074) else `ERROR("bne instrution is failed", 32'h00400074, dut.RV1.PC);

        #10; // blt instruction line 89 is executed
        assert(dut.RV1.PC === 32'h00400078) else `ERROR("blt instrution is failed", 32'h00400078, dut.RV1.PC);

        #10; // bge instruction line 92 is executed
        assert(dut.RV1.PC === 32'h00400080) else `ERROR("blt instrution is failed", 32'h00400080, dut.RV1.PC);

        #10; // bge instruction line 93 is executed
        assert(dut.RV1.PC === 32'h00400084) else `ERROR("bge instrution is failed", 32'h00400084, dut.RV1.PC);

        #10; // bltu instruction line 96 is executed
        assert(dut.RV1.PC === 32'h0040008c) else `ERROR("bge instrution is failed", 32'h0040008c, dut.RV1.PC);

        #10; // bltu instruction line 97 is executed
        assert(dut.RV1.PC === 32'h00400090) else `ERROR("bltu instrution is failed", 32'h00400090, dut.RV1.PC);        

        #10; // bgeu instruction line 100 is executed
        assert(dut.RV1.PC === 32'h00400098) else `ERROR("bltu instrution is failed", 32'h00400098, dut.RV1.PC);

        #10; // bgeu instruction line 101 is executed
        assert(dut.RV1.PC === 32'h0040009c) else `ERROR("bgeu instrution is failed", 32'h0040009c, dut.RV1.PC);   

        #10; // successful bgeu has reached bgeu_skip
        assert(dut.RV1.RegFile1.RegBank[8] === 32'hffff0000) else `ERROR("probably some branching fails", 32'hffff0000, dut.RV1.RegFile1.RegBank[8]);
        assert(dut.RV1.PC === 32'h004000a4) else `ERROR("bgeu instrution is failed", 32'h004000a4, dut.RV1.PC);   

        #430; // extended instruction checks, DIP -> LED write, and final nop are executed
        assert(dut.RV1.RegFile1.RegBank[31] === 32'h4) else `ERROR("auipc PC difference check is failed", 32'h4, dut.RV1.RegFile1.RegBank[31]);
        assert(dut.RV1.RegFile1.RegBank[29] === 32'h55) else `ERROR("jal x0 skip check is failed", 32'h55, dut.RV1.RegFile1.RegBank[29]);
        assert(dut.RV1.RegFile1.RegBank[6] === dut.RV1.RegFile1.RegBank[5]) else `ERROR("jal link check is failed", dut.RV1.RegFile1.RegBank[5], dut.RV1.RegFile1.RegBank[6]);
        assert(dut.RV1.RegFile1.RegBank[7] === dut.RV1.RegFile1.RegBank[28]) else `ERROR("jalr link check is failed", dut.RV1.RegFile1.RegBank[28], dut.RV1.RegFile1.RegBank[7]);
        assert(dut.LED_OUT === 8'h0f) else `ERROR("Reading and writing DIPS fails", 8'h0f, dut.LED_OUT);

        // ---------------------------------------------------------
        // TEST SUMMARY
        // ---------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("                       TEST SUMMARY");
        $display("============================================================");
        $display("Total errors: %0d", error_count);

        if (error_count == 0) begin
            $display("                    ALL TESTS PASSED");
        end
        else begin
            $display("                    TESTS FAILED");
        end

        $display("============================================================");

        $finish;
	end
	// GENERATE CLOCK       
    always          
    begin
       #5 CLK = ~CLK ; // invert clk every 5 time units 
    end
    
endmodule
