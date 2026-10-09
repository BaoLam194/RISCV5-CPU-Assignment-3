#----------------------------------------------------------------------------------
#-- (c) Rajesh Panicker
#--	License terms :
#--	You are free to use this code as long as you
#--		(i) DO NOT post it on any public repository;
#--		(ii) use it only for educational purposes;
#--		(iii) accept the responsibility to ensure that your implementation does not violate anyone's intellectual property.
#--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
#--		(v) send an email to rajesh<dot>panicker<at>ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
#--		(vi) retain this notice in this file and any files derived from this.
#----------------------------------------------------------------------------------


#/////////////////////////////////////////////////////////////////////////////////
# Testing for RV32I Instructions
# lui, addi,
# and(i), or(i), slt(i), sltu(i)
# auipc, lw
# sub
# auipc, sw
# The assert is delayed 1 cycle because writing only happens at next cycle
#/////////////////////////////////////////////////////////////////////////////////

# This sample program for RISC-V simulation using RARS

# Memory this program needs: IROM_DEPTH_BITS 9, DMEM_DEPTH_BITS 9
# (2**9 = 512 bytes of code, 2**9 = 512 bytes of data). The simulator sets its
# Linker segments from these when you pick the example; set the same two
# localparams in Wrapper.v. Change both if you change the program.

.eqv MMIO_BASE 0xFFFF0000
# Memory-mapped peripheral register offsets
.eqv UART_RX_VALID_OFF 			0x00 #RO, status bit
.eqv UART_RX_OFF			0x04 #RO
.eqv UART_TX_READY_OFF			0x08 #RO, status bit
.eqv UART_TX_OFF			0x0C #WO
.eqv OLED_COL_OFF			0x20 #WO
.eqv OLED_ROW_OFF			0x24 #WO
.eqv OLED_DATA_OFF			0x28 #WO
.eqv OLED_CTRL_OFF			0x2C #WO
.eqv OLED_STATUS_OFF		0x30 #RO, status bit
.eqv ACCEL_DATA_OFF			0x40 #RO
.eqv ACCEL_DREADY_OFF			0x44 #RO, status bit
.eqv DIP_OFF				0x64 #RO
.eqv PB_OFF				0x68 #RO
.eqv LED_OFF				0x60 #WO
.eqv SEVENSEG_OFF			0x80 #WO
.eqv CYCLECOUNT_OFF			0xA0 #RO

# ------- <code memory (Instruction Memory ROM) begins>
.text	## IROM segment: IROM_BASE to IROM_BASE+2^IROM_DEPTH_BITS-1
# Total number of real instructions should not exceed 2^IROM_DEPTH_BITS/4 (127 excluding the last line 'halt B halt' if IROM_DEPTH_BITS=9).
# Pseudoinstructions (e.g., li, la) may be implemented using more than one actual instruction. See the assembled code in the Execute tab of RARS.

# You can also use the actual register numbers directly. For example, instead of s1, you can write x9

main:
	li s0, MMIO_BASE		# MMIO_BASE. Implemented as lui+addi
	# Could have done lw s0,MMIO_BASE (ARM style) instead of the li above, provided MMIO_BASE: .word 0xFFFF0000 was declared in the .data (DMEM) section instead of .eqv
	li a0, 100
    li a1, 67
    li a2, -8
    li a3, 1024
    and a4, a0, a1          #64
    andi a5, a2, 89			#88
    or a6, a2, a3 			#-8
    ori a7, a3, 4			#1028
    slt s8, a2, a3 			# 1
    slt s9, a3, a0 			# 0
    sltu s10, a3, a2		# 1
    sltu s11, a0, a1 		# 0
    la s1, delay_val        # 0x10010000
    lw s2, 0(s1)            # 3
    sub s2, s2, s8			# 2
    sw s2, 0(s1)			# 2
    slti s3, s2, 1 			# 0
    sltiu s4, s2, -8 		# 1
    xor s5, s2, s4			# 3
    xori s6, s2, 7  		# 5
	beq s3, s4, finish 		# 0 == 1 ?
	beq s2, s2, beq_skip
  	addi s0, s0, 1
beq_skip:
	bne s2, s2, finish		# 2 != 2 ?
	bne s3, s4, bne_skip
  	addi s0, s0, 1
bne_skip:
	blt s3, a2, finish		# 0 < -8 ?
	blt a2, s3, blt_skip
  	addi s0, s0, 1
blt_skip:
	bge a2, s3, finish 		# -8 > 0?
	bge s4, s3, bge_skip
    addi s0, s0, 1
bge_skip:
	bltu a2, s3, finish 		# unsigned(-8) < 0 ?
    bltu s3, a2, bltu_skip
  	addi s0, s0, 1
bltu_skip:
	bgeu s3, a2, finish 		# 0 > unsigned(-8) ?
    bgeu a2, s3, bgeu_skip
	addi s0, s0, 1
bgeu_skip:
	# Register shifts
	li t0, 1
	li t1, 4
	sll t2, t0, t1			# 1 << 4 = 16
	li t3, 16
	bne t2, t3, finish
	srl t2, t2, t1			# 16 >> 4 = 1
	bne t2, t0, finish
	li t2, -8
	sra t2, t2, t1			# -8 >>> 4 = -1
	li t3, -1
	bne t2, t3, finish

	# Immediate shifts
	slli t2, t0, 3			# 1 << 3 = 8
	li t3, 8
	bne t2, t3, finish
	srli t2, t2, 2			# 8 >> 2 = 2
	li t3, 2
	bne t2, t3, finish
	li t2, -8
	srai t2, t2, 2			# -8 >>> 2 = -2
	li t3, -2
	bne t2, t3, finish

	# AUIPC must use the PC of its own instruction
	auipc t4, 0
	auipc t5, 0
	sub t6, t5, t4
	li t3, 4
	bne t6, t3, finish

	# JAL without linking: the instruction after the jump must be skipped
	li t4, 85
	jal x0, jal_call_start
	addi t4, zero, 0		# corrupts the sentinel if the jump fails

jal_link_target:
	auipc t3, 0				# address used to verify the JALR link
	jalr t2, 0(t1)			# return through the JAL link

jal_call_start:
	li t5, 85
	bne t4, t5, finish
	auipc t0, 0
	jal t1, jal_link_target
jal_return:
	addi t0, t0, 8			# expected JAL link: address after jal
	bne t1, t0, finish
	addi t3, t3, 8			# expected JALR link: address after jalr
	bne t2, t3, finish

    addi s1, s0, LED_OFF		# LED address
	addi s2, s0, DIP_OFF		# DIP address
    lw s4, (s2)                 # Reading DIPS
    sw s4, (s1)                 # writing DIPS
    mul a0, t1, s1			# 0x0x16d07200
    mulh t0, t1, s1			# -64
    mulhu t2, t1, s1		# 0x4000f0
finish:
	nop

# ------- <code memory (Instruction Memory ROM) ends>			
				
								
#------- <Data Memory begins>									
.data  ## DMEM segment: DMEM_BASE to DMEM_BASE+2^DMEM_DEPTH_BITS-1
# Total number of constants+variables should not exceed 2^DMEM_DEPTH_BITS/4 (128 if DMEM_DEPTH_BITS=9).

DMEM:

delay_val: .word 3	# a constant, at location DMEM+0x00
string1:
.asciz "\r\nWelcome to CG3207..\r\n"	# string, from DMEM+0x4 to DMEM+0x18 (word address, including null character. The last character is at a byte address 0x1B).
var1: .word	1 		# a statically allocated variable (which can have an initial value, say 1), at location DMEM+0x1C
# Food for thought: What will be the address of var1 if string1 had one extra character, say  "..." instead of ".."? Hint: words are word-aligned.

.align 9	# To set the address at this point to be 512-byte aligned, i.e., DMEM+0x200
STACK_INIT:	# Stack pointer can be initialised to this location - DMEM+0x200 (i.e., the address of stack_top)
			# stack grows downwards, so stack pointer should be decremented when pushing and incremented when popping (if the stack is full-descending). Stack can be used for function calls and local variables.
		# Not allocating any heap, as it is unlikely to be used in this simple program. If we need dynamic memory allocation,we need to allocate memory and imeplement a heap manager.
#------- <Data Memory ends>													
