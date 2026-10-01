`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
Self-checking testbench for the assigned RV32I instructions:
sll, srl, sra, slli, srli, srai, auipc, jal, and jalr.
----------------------------------------------------------------------------------
*/

module test_Wrapper_assigned;
	reg [15:0] DIP = 16'd0;
	reg [2:0] PB = 3'd0;
	wire [7:0] LED_OUT;
	wire [6:0] LED_PC;
	wire [31:0] SEVENSEGHEX;
	wire [7:0] UART_TX;
	reg UART_TX_ready = 1'b0;
	wire UART_TX_valid;
	reg [7:0] UART_RX = 8'd0;
	reg UART_RX_valid = 1'b0;
	wire UART_RX_ack;
	wire OLED_Write;
	wire [6:0] OLED_Col;
	wire [5:0] OLED_Row;
	wire [23:0] OLED_Data;
	reg [31:0] ACCEL_Data = 32'd0;
	reg ACCEL_DReady = 1'b0;
	reg RESET = 1'b1;
	reg CLK = 1'b0;
	integer errors = 0;

	Wrapper dut(
		.DIP(DIP),
		.PB(PB),
		.LED_OUT(LED_OUT),
		.LED_PC(LED_PC),
		.SEVENSEGHEX(SEVENSEGHEX),
		.UART_TX(UART_TX),
		.UART_TX_ready(UART_TX_ready),
		.UART_TX_valid(UART_TX_valid),
		.UART_RX(UART_RX),
		.UART_RX_valid(UART_RX_valid),
		.UART_RX_ack(UART_RX_ack),
		.OLED_Write(OLED_Write),
		.OLED_Col(OLED_Col),
		.OLED_Row(OLED_Row),
		.OLED_Data(OLED_Data),
		.ACCEL_Data(ACCEL_Data),
		.ACCEL_DReady(ACCEL_DReady),
		.RESET(RESET),
		.CLK(CLK)
	);

	function [31:0] encode_u;
		input [19:0] imm20;
		input [4:0] rd;
		input [6:0] opcode;
		begin
			encode_u = {imm20, rd, opcode};
		end
	endfunction

	function [31:0] encode_r;
		input [6:0] funct7;
		input [4:0] rs2;
		input [4:0] rs1;
		input [2:0] funct3;
		input [4:0] rd;
		input [6:0] opcode;
		begin
			encode_r = {funct7, rs2, rs1, funct3, rd, opcode};
		end
	endfunction

	function [31:0] encode_i;
		input [11:0] imm12;
		input [4:0] rs1;
		input [2:0] funct3;
		input [4:0] rd;
		input [6:0] opcode;
		begin
			encode_i = {imm12, rs1, funct3, rd, opcode};
		end
	endfunction

	function [31:0] encode_j;
		input [20:0] offset;
		input [4:0] rd;
		begin
			encode_j = {offset[20], offset[10:1], offset[11],
			            offset[19:12], rd, 7'b1101111};
		end
	endfunction

	task check32;
		input [383:0] label;
		input [31:0] actual;
		input [31:0] expected;
		begin
			if(actual !== expected) begin
				$display("FAIL: %0s expected %h, got %h", label, expected, actual);
				errors = errors + 1;
			end
			else
				$display("PASS: %0s = %h", label, actual);
		end
	endtask

	always #5 CLK = ~CLK;

	initial begin
		// Load after Wrapper's own time-zero memory initialisation has run.
		#1;
		dut.IROM[0]  = encode_u(20'h80000, 5'd1, 7'b0010111); // auipc x1, 0x80000
		dut.IROM[1]  = encode_u(20'h00000, 5'd2, 7'b0010111); // auipc x2, 0
		dut.IROM[2]  = encode_r(7'b0000000, 5'd2, 5'd1, 3'b001, 5'd3, 7'b0110011); // sll
		dut.IROM[3]  = encode_r(7'b0000000, 5'd2, 5'd1, 3'b101, 5'd4, 7'b0110011); // srl
		dut.IROM[4]  = encode_r(7'b0100000, 5'd2, 5'd1, 3'b101, 5'd5, 7'b0110011); // sra
		dut.IROM[5]  = encode_i(12'h004, 5'd1, 3'b001, 5'd6, 7'b0010011); // slli 4
		dut.IROM[6]  = encode_i(12'h004, 5'd1, 3'b101, 5'd7, 7'b0010011); // srli 4
		dut.IROM[7]  = encode_i(12'h404, 5'd1, 3'b101, 5'd8, 7'b0010011); // srai 4
		dut.IROM[8]  = encode_j(21'd8, 5'd0);  // jal x0, +8 (no link)
		dut.IROM[9]  = encode_u(20'h11111, 5'd20, 7'b0010111); // must be skipped
		dut.IROM[10] = encode_j(21'd8, 5'd9);  // jal x9, +8
		dut.IROM[11] = encode_u(20'h22222, 5'd20, 7'b0010111); // must be skipped
		dut.IROM[12] = encode_u(20'h00000, 5'd10, 7'b0010111); // auipc x10, 0
		dut.IROM[13] = encode_i(12'h00c, 5'd10, 3'b000, 5'd11, 7'b1100111); // jalr
		dut.IROM[14] = encode_u(20'h33333, 5'd20, 7'b0010111); // must be skipped
		dut.IROM[15] = encode_j(21'd0, 5'd0);  // stop in a self-loop

		// Sentinels make skipped instructions and writes to x0 observable.
		dut.RV1.RegFile1.RegBank[0] = 32'hDEAD_BEEF;
		dut.RV1.RegFile1.RegBank[20] = 32'hCAFE_BABE;

		#11 RESET = 1'b0;
		repeat(13) @(posedge CLK);
		#1;

		check32("auipc source value", dut.RV1.RegFile1.RegBank[1], 32'h8040_0000);
		check32("register shift amount", dut.RV1.RegFile1.RegBank[2], 32'h0040_0004);
		check32("sll result", dut.RV1.RegFile1.RegBank[3], 32'h0400_0000);
		check32("srl result", dut.RV1.RegFile1.RegBank[4], 32'h0804_0000);
		check32("sra result", dut.RV1.RegFile1.RegBank[5], 32'hF804_0000);
		check32("slli result", dut.RV1.RegFile1.RegBank[6], 32'h0400_0000);
		check32("srli result", dut.RV1.RegFile1.RegBank[7], 32'h0804_0000);
		check32("srai result", dut.RV1.RegFile1.RegBank[8], 32'hF804_0000);
		check32("jal link", dut.RV1.RegFile1.RegBank[9], 32'h0040_002C);
		check32("jalr base", dut.RV1.RegFile1.RegBank[10], 32'h0040_0030);
		check32("jalr link", dut.RV1.RegFile1.RegBank[11], 32'h0040_0038);
		check32("jalr target", dut.PC, 32'h0040_003C);
		check32("skipped fall-through instructions", dut.RV1.RegFile1.RegBank[20], 32'hCAFE_BABE);
		check32("x0 write suppression", dut.RV1.RegFile1.RegBank[0], 32'hDEAD_BEEF);

		if(errors == 0)
			$display("ALL ASSIGNED-INSTRUCTION TESTS PASSED");
		else
			$display("TEST FAILED WITH %0d ERROR(S)", errors);
		$finish;
	end

	initial begin
		#300;
		$display("FAIL: testbench timeout");
		$finish;
	end
endmodule
