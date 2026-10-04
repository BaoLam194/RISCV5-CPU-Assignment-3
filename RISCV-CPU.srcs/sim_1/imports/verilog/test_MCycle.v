`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NUS
// Engineer: Shahzor Ahmad, Rajesh C Panicker
// 
// Create Date: 27.09.2016 16:55:23
// Design Name: 
// Module Name: test_MCycle
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
/* 
----------------------------------------------------------------------------------
--	(c) Shahzor Ahmad, Rajesh C Panicker
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(iv) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(v) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

//module test_MCycle(

//    );
    
//    // DECLARE INPUT SIGNALs
//    reg CLK = 0 ;
//    reg RESET = 0 ;
//    reg Start = 0 ;
//    reg [1:0] MCycleOp = 0 ;
//    reg [3:0] Operand1 = 0 ;
//    reg [3:0] Operand2 = 0 ;

//    // DECLARE OUTPUT SIGNALs
//    wire [3:0] Result1 ;
//    wire [3:0] Result2 ;
//    wire Busy ;
    
//    // INSTANTIATE DEVICE/UNIT UNDER TEST (DUT/UUT)
//    MCycle dut( 
//        CLK, 
//        RESET, 
//        Start, 
//        MCycleOp, 
//        Operand1, 
//        Operand2, 
//        Result1, 
//        Result2, 
//        Busy
//        ) ;
    
//    // STIMULI
//    initial begin
//        // hold reset state for 100 ns.
//        #10 ;    
//        MCycleOp = 2'b00 ;
//        Operand1 = 4'b1111 ;
//        Operand2 = 4'b1111 ;
//        Start = 1'b1 ; // Start is asserted continously(Operations are performed back to back). To try a non-continous Start, you can uncomment the commented lines.    

//        wait(Busy) ; // suspend initial block till condition becomes true  ;
//        wait(~Busy) ;
////        #10 ;
////        Start = 1'b0 ;
////        #10 ;
//        Operand1 = 4'b1110 ;
//        Operand2 = 4'b1111 ;
////        Start = 1'b1 ;
        
//        wait(Busy) ; 
//        wait(~Busy) ;
////        #10 ;
////        Start = 1'b0 ;
////        #10 ;
//        MCycleOp = 2'b01 ;
//        Operand1 = 4'b1111 ;
//        Operand2 = 4'b1111 ;
////        Start = 1'b1 ;

//        wait(Busy) ; 
//        wait(~Busy) ; 
////        #10 ;
////        Start = 1'b0 ;
////        #10 ;
//        Operand1 = 4'b1110 ;
//        Operand2 = 4'b1111 ;
////        Start = 1'b1 ;

//        wait(Busy) ; 
//        wait(~Busy) ; 
//        Start = 1'b0 ;
//    end
     
//    // GENERATE CLOCK       
//    always begin 
//        #5 CLK = ~CLK ; 
//        // invert CLK every 5 time units 
//    end
    
//endmodule

module test_MCycle(

    );

    // DECLARE INPUT SIGNALs
    reg CLK = 0 ;
    reg RESET = 0 ;
    reg Start = 0 ;
    reg [1:0] MCycleOp = 0 ;
    reg [3:0] Operand1 = 0 ;
    reg [3:0] Operand2 = 0 ;

    // DECLARE OUTPUT SIGNALs
    wire [3:0] Result1 ;
    wire [3:0] Result2 ;
    wire Busy ;

    // INSTANTIATE DEVICE/UNIT UNDER TEST (DUT/UUT)
    MCycle #(.width(4)) dut(
        .CLK(CLK),
        .RESET(RESET),
        .Start(Start),
        .MCycleOp(MCycleOp),
        .Operand1(Operand1),
        .Operand2(Operand2),
        .Result1(Result1),
        .Result2(Result2),
        .Busy(Busy)
        ) ;

    // GENERATE CLOCK
    always begin
        #5 CLK = ~CLK ;
        // invert CLK every 5 time units
    end

    // WATCHDOG: abort if the DUT ever hangs (Busy stuck high)
    initial begin
        #20_000_000 ;
        $display("TIMEOUT: simulation hung, Busy probably never fell") ;
        $finish ;
    end

    // ------------------------------------------------------------------
    // Bookkeeping
    // ------------------------------------------------------------------
    integer errors = 0 ;
    integer checks = 0 ;
    integer busy_cycles = 0 ;   // number of clock edges at which Busy was high
    reg     verbose = 1'b1 ;    // print a line for every check (turned off for the big sweeps)

    // Count how many cycles Busy stays high. Sampled at the clock edge, i.e. before
    // the DUT's non-blocking updates take effect.
    always @(posedge CLK)
        if (Busy) busy_cycles = busy_cycles + 1 ;

    // Reference model scratch variables
    integer sa, sb, pq, pr, exp_cycles ;
    reg [7:0] exp_prod ;
    reg [3:0] exp_q, exp_r ;      // expected Result1 / Result2

    // ------------------------------------------------------------------
    // run_op: apply one operation and check everything about it.
    //   hold = 0 : Start is dropped after the operation, one idle cycle follows
    //              (non-continuous Start)
    //   hold = 1 : Start is left high, so the next call runs back to back
    // Checks: Result1, Result2, number of busy cycles, Busy rising with Start (when
    // starting from idle), Busy low and results held in the idle cycle afterwards.
    // ------------------------------------------------------------------
    task run_op(input [1:0] op, input [3:0] a, input [3:0] b, input hold);
        begin
            // ---- reference model ----
            sa = a[3] ? a - 16 : a ;     // signed value of a
            sb = b[3] ? b - 16 : b ;
            case (op)
                2'b00: begin // signed multiply, 2*width cycles
                    pq = sa * sb ;
                    exp_prod = pq[7:0] ;
                    exp_q = exp_prod[3:0] ;
                    exp_r = exp_prod[7:4] ;
                    exp_cycles = 8 ;
                end
                2'b01: begin // unsigned multiply, width cycles
                    pq = a * b ;
                    exp_prod = pq[7:0] ;
                    exp_q = exp_prod[3:0] ;
                    exp_r = exp_prod[7:4] ;
                    exp_cycles = 4 ;
                end
                2'b10: begin // signed divide (truncates toward zero, remainder takes sign of dividend)
                    pq = sa / sb ;       // -8 / -1 = 8 -> truncates to 4'b1000 = -8, as RISC-V specifies
                    pr = sa % sb ;
                    exp_q = pq[3:0] ;
                    exp_r = pr[3:0] ;
                    exp_cycles = 4 ;
                end
                2'b11: begin // unsigned divide
                    pq = a / b ;
                    pr = a % b ;
                    exp_q = pq[3:0] ;
                    exp_r = pr[3:0] ;
                    exp_cycles = 4 ;
                end
            endcase

            // ---- apply stimulus ----
            MCycleOp = op ;
            Operand1 = a ;
            Operand2 = b ;
            busy_cycles = 0 ;
            Start = 1'b1 ;

            if (!hold) begin
                #1 ;
                if (Busy !== 1'b1) begin   // Mealy output: Busy must rise as soon as Start does
                    errors = errors + 1 ;
                    $display("FAIL: Busy did not rise immediately with Start (op=%b a=%0d b=%0d)", op, a, b) ;
                end
            end

            wait(Busy) ;
            wait(~Busy) ;
            #1 ;                           // let the registered results settle

            // ---- check results ----
            checks = checks + 1 ;
            if (Result1 !== exp_q || Result2 !== exp_r || busy_cycles !== exp_cycles) begin
                errors = errors + 1 ;
                $display("FAIL: op=%b a=%0d(%0d) b=%0d(%0d) | R1=%0d R2=%0d (expected %0d %0d) | cycles=%0d (expected %0d)",
                         op, a, sa, b, sb, $signed(Result1), $signed(Result2),
                         $signed(exp_q), $signed(exp_r), busy_cycles, exp_cycles) ;
            end
            else if (verbose)
                // $display("PASS: op=%b a=%0d b=%0d | R1=%0d R2=%0d | cycles=%0d", op, a, sa == sa ? b : b, $signed(Result1), $signed(Result2), busy_cycles) ;
                $display("PASS: op=%b a=%0d b=%0d | R1=%0d R2=%0d | cycles=%0d", op, a, b, $signed(Result1), $signed(Result2), busy_cycles) ;

            // ---- idle cycle after the operation ----
            if (!hold) begin
                Start = 1'b0 ;
                @(posedge CLK) ;
                #1 ;
                if (Busy !== 1'b0) begin
                    errors = errors + 1 ;
                    $display("FAIL: Busy still high in the idle cycle after the operation") ;
                end
                if (Result1 !== exp_q || Result2 !== exp_r) begin
                    errors = errors + 1 ;
                    $display("FAIL: results changed in the idle cycle (op=%b a=%0d b=%0d)", op, a, b) ;
                end
            end
        end
    endtask

    // ------------------------------------------------------------------
    // STIMULI
    // ------------------------------------------------------------------
    reg [1:0] op_r ;
    reg [3:0] a_r, b_r ;
    reg [3:0] hold_r1, hold_r2 ;
    reg [31:0] rnd1, rnd2, rnd3 ;
    integer i, j, k ;

    initial begin
        #10 ;

        // ==============================================================
        // 1. Your original stimuli (multiply). Expected:
        //    signed   -1 * -1 =   1  -> R2:R1 = 0000_0001
        //    signed   -2 * -1 =   2  -> R2:R1 = 0000_0010
        //    unsigned 15 * 15 = 225  -> R2:R1 = 1110_0001
        //    unsigned 14 * 15 = 210  -> R2:R1 = 1101_0010
        // ==============================================================
        $display("--- 1. original multiply stimuli ---") ;
        run_op(2'b00, 4'b1111, 4'b1111, 1'b0) ;
        run_op(2'b00, 4'b1110, 4'b1111, 1'b0) ;
        run_op(2'b01, 4'b1111, 4'b1111, 1'b0) ;
        run_op(2'b01, 4'b1110, 4'b1111, 1'b0) ;

        // ==============================================================
        // 2. More multiply corner cases
        // ==============================================================
        $display("--- 2. multiply corner cases ---") ;
        run_op(2'b00, 4'd7,  4'd7,  1'b0) ;   // 49
        run_op(2'b00, 4'd8,  4'd8,  1'b0) ;   // -8 * -8 = 64
        run_op(2'b00, 4'd8,  4'd7,  1'b0) ;   // -8 * 7 = -56
        run_op(2'b00, 4'd7,  4'd8,  1'b0) ;   // 7 * -8
        run_op(2'b00, 4'd0,  4'd13, 1'b0) ;   // 0 * x
        run_op(2'b01, 4'd15, 4'd1,  1'b0) ;   // 15
        run_op(2'b01, 4'd0,  4'd15, 1'b0) ;   // 0

        // ==============================================================
        // 3. Unsigned divide (divisor never 0)
        //    quotient in Result1, remainder in Result2
        // ==============================================================
        $display("--- 3. unsigned divide ---") ;
        run_op(2'b11, 4'd7,  4'd2,  1'b0) ;   // 3 r1
        run_op(2'b11, 4'd15, 4'd1,  1'b0) ;   // 15 r0
        run_op(2'b11, 4'd15, 4'd15, 1'b0) ;   // 1 r0
        run_op(2'b11, 4'd3,  4'd7,  1'b0) ;   // 0 r3  (dividend < divisor)
        run_op(2'b11, 4'd0,  4'd5,  1'b0) ;   // 0 r0
        run_op(2'b11, 4'd15, 4'd2,  1'b0) ;   // 7 r1  (MSB of dividend set)
        run_op(2'b11, 4'd14, 4'd15, 1'b0) ;   // 0 r14 (divisor MSB set)
        run_op(2'b11, 4'd9,  4'd9,  1'b0) ;   // 1 r0

        // ==============================================================
        // 4. Signed divide (divisor never 0)
        // ==============================================================
        $display("--- 4. signed divide ---") ;
        run_op(2'b10, 4'd7,  4'd2,  1'b0) ;   //  7 /  2 =  3 r  1
        run_op(2'b10, -4'sd7, 4'd2, 1'b0) ;   // -7 /  2 = -3 r -1
        run_op(2'b10, 4'd7, -4'sd2, 1'b0) ;   //  7 / -2 = -3 r  1
        run_op(2'b10, -4'sd7, -4'sd2, 1'b0) ; // -7 / -2 =  3 r -1
        run_op(2'b10, 4'b1000, 4'b1111, 1'b0) ; // -8 / -1 = -8 r 0 (overflow case)
        run_op(2'b10, 4'b1000, 4'd1, 1'b0) ;  // -8 /  1 = -8 r 0
        run_op(2'b10, 4'b1000, 4'd3, 1'b0) ;  // -8 /  3 = -2 r -2
        run_op(2'b10, 4'd0, -4'sd3, 1'b0) ;   //  0 / -3 =  0 r  0
        run_op(2'b10, 4'd3, 4'd7, 1'b0) ;     //  3 /  7 =  0 r  3
        run_op(2'b10, -4'sd3, 4'd7, 1'b0) ;   // -3 /  7 =  0 r -3

        // ==============================================================
        // 5. Results must be held while idle, whatever the operands do
        // ==============================================================
        $display("--- 5. results held while idle ---") ;
        run_op(2'b10, -4'sd7, 4'd2, 1'b0) ;
        hold_r1 = Result1 ;
        hold_r2 = Result2 ;
        Operand1 = 4'hA ;
        Operand2 = 4'h5 ;
        MCycleOp = 2'b01 ;
        repeat (5) @(posedge CLK) ;
        #1 ;
        checks = checks + 1 ;
        if (Result1 !== hold_r1 || Result2 !== hold_r2 || Busy !== 1'b0) begin
            errors = errors + 1 ;
            $display("FAIL: results or Busy changed while idle") ;
        end
        else
            $display("PASS: results and Busy stable for 5 idle cycles") ;

        // ==============================================================
        // 6. Back to back operations (Start held high), switching between
        //    multiply and divide, signed and unsigned
        // ==============================================================
        $display("--- 6. back-to-back, Start held high ---") ;
        run_op(2'b00, 4'b1111, 4'b1111, 1'b1) ;  // signed mult
        run_op(2'b11, 4'd15,   4'd2,    1'b1) ;  // unsigned div
        run_op(2'b01, 4'd15,   4'd15,   1'b1) ;  // unsigned mult
        run_op(2'b10, -4'sd7,  4'd2,    1'b1) ;  // signed div
        run_op(2'b10, 4'b1000, 4'b1111, 1'b1) ;  // signed div overflow
        run_op(2'b00, 4'd7,    4'd7,    1'b1) ;  // signed mult
        run_op(2'b11, 4'd7,    4'd2,    1'b0) ;  // unsigned div, last one drops Start

        // ==============================================================
        // 7. RESET in the middle of a division
        // ==============================================================
        $display("--- 7. reset during an operation ---") ;
        MCycleOp = 2'b11 ;
        Operand1 = 4'd13 ;
        Operand2 = 4'd3 ;
        Start = 1'b1 ;
        repeat (2) @(posedge CLK) ;
        #1 ;
        RESET = 1'b1 ;
        #1 ;
        checks = checks + 1 ;
        if (Busy !== 1'b0) begin
            errors = errors + 1 ;
            $display("FAIL: Busy should be low while RESET is high") ;
        end
        else
            $display("PASS: Busy low during RESET") ;
        @(posedge CLK) ;
        #1 ;
        Start = 1'b0 ;
        RESET = 1'b0 ;
        @(posedge CLK) ;
        #1 ;
        if (Busy !== 1'b0) begin
            errors = errors + 1 ;
            $display("FAIL: Busy not low after RESET released") ;
        end
        run_op(2'b11, 4'd13, 4'd3, 1'b0) ;      // 4 r1, unit must work normally after reset
        run_op(2'b00, 4'd5,  4'd3, 1'b0) ;      // and multiply too

        // ==============================================================
        // 8. Random back-to-back mix (Start held high), 500 operations
        // ==============================================================
        $display("--- 8. random back-to-back mix ---") ;
        verbose = 1'b0 ;
        for (i = 0; i < 500; i = i + 1) begin
            rnd1 = $urandom ;
            rnd2 = $urandom ;
            rnd3 = $urandom ;
            op_r = rnd1[1:0] ;
            a_r  = rnd2[3:0] ;
            b_r  = rnd3[3:0] ;
            if (op_r[1] && b_r == 4'd0) b_r = 4'd1 ;   // divisor is never zero
            run_op(op_r, a_r, b_r, 1'b1) ;
        end
        run_op(2'b00, 4'd1, 4'd1, 1'b0) ;               // drop Start
        verbose = 1'b1 ;

        // ==============================================================
        // 9. Exhaustive sweep: all 4 operations x 16 x 16 operand pairs
        //    (divisor 0 skipped for divides)
        // ==============================================================
        $display("--- 9. exhaustive sweep ---") ;
        verbose = 1'b0 ;
        for (k = 0; k < 4; k = k + 1)
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1)
                    if (!(k >= 2 && j == 0)) begin
                        op_r = k ;
                        a_r  = i ;
                        b_r  = j ;
                        run_op(op_r, a_r, b_r, 1'b0) ;
                    end
        verbose = 1'b1 ;

        // ==============================================================
        // Summary
        // ==============================================================
        #20 ;
        $display("==================================================") ;
        if (errors == 0)
            $display("ALL TESTS PASSED (%0d result checks)", checks) ;
        else
            $display("%0d ERROR(S) in %0d result checks", errors, checks) ;
        $display("==================================================") ;
        $finish ;
    end

endmodule