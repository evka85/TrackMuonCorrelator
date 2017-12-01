////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 2.6
//  \   \         Application : 7 Series FPGAs Transceivers Wizard 
//  /   /         Filename : xilinx_gth_16b_5g_cpll_tx_startup_fsm.v
// /___/   /\     
// \   \  /  \ 
//  \___\/\___\ 
//
//
//  Description :     This module performs TX reset and initialization.
//                     
//
//
// Module xilinx_gth_16b_5g_cpll_tx_startup_fsm
// Generated by Xilinx 7 Series FPGAs Transceivers Wizard
// 
// 
// (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES. 


//*****************************************************************************

`timescale 1ns / 1ps
`define DLY #1


module xilinx_gth_16b_5g_cpll_TX_STARTUP_FSM  #
   (
      parameter     GT_TYPE                  = "GTX",
      parameter     STABLE_CLOCK_PERIOD      = 8,        // Period of the stable clock driving this state-machine, unit is [ns]
      parameter     RETRY_COUNTER_BITWIDTH   = 8, 
      parameter     TX_QPLL_USED             = "FALSE",  // the TX and RX Reset FSMs must
      parameter     RX_QPLL_USED             = "FALSE",  // share these two generic values
      parameter     PHASE_ALIGNMENT_MANUAL   = "TRUE"    // Decision if a manual phase-alignment is necessary or the automatic 
                                                         // is enough. For single-lane applications the automatic alignment is 
                                                         // sufficient              
   )
   (    
      input  wire      STABLE_CLOCK,             //Stable Clock, either a stable clock from the PCB
      input  wire      TXUSERCLK,                //TXUSERCLK as used in the design
      input  wire      SOFT_RESET,               //User Reset, can be pulled any time
      input  wire      QPLLREFCLKLOST,           //QPLL Reference-clock for the GT is lost
      input  wire      CPLLREFCLKLOST,           //CPLL Reference-clock for the GT is lost
      input  wire      QPLLLOCK,                 //Lock Detect from the QPLL of the GT
      input  wire      CPLLLOCK ,                //Lock Detect from the CPLL of the GT
      input  wire      TXRESETDONE,            
      input  wire      MMCM_LOCK,              
      output reg       GTTXRESET  = 1'b0,              
      output reg       MMCM_RESET = 1'b1,             
      output reg       QPLL_RESET = 1'b0,        //Reset QPLL
      output reg       CPLL_RESET = 1'b0,        //Reset CPLL
      output           TX_FSM_RESET_DONE,        //Reset-sequence has sucessfully been finished.
      output reg       TXUSERRDY  = 1'b0,        
      output           RUN_PHALIGNMENT,  
      output reg       RESET_PHALIGNMENT = 1'b0,
      input  wire      PHALIGNMENT_DONE, 
       
      output [RETRY_COUNTER_BITWIDTH-1:0] RETRY_COUNTER // Number of 
                                                        // Retries it took to get the transceiver up and running
   );


//Interdependencies:
// * Timing depends on the frequency of the stable clock. Hence counters-sizes
//   are calculated at design-time based on the Generics
//   
// * if either of the PLLs is reset during TX-startup, it does not need to be reset again by RX
//   => signal which PLL has been reset
// * 


   localparam [2:0] 
               INIT = 3'b000,
               ASSERT_ALL_RESETS = 3'b001,
               RELEASE_PLL_RESET = 3'b010,
               RELEASE_MMCM_RESET = 3'b011,
               WAIT_RESET_DONE = 3'b100,
               DO_PHASE_ALIGNMENT = 3'b101,
               RESET_FSM_DONE = 3'b110;
    
  reg [2:0] tx_state = INIT;


  parameter MMCM_LOCK_CNT_MAX = 1024;
  parameter STARTUP_DELAY    = 500;//AR43482: Transceiver needs to wait for 500 ns after configuration
  parameter WAIT_CYCLES      = STARTUP_DELAY / STABLE_CLOCK_PERIOD; // Number of Clock-Cycles to wait after configuration
  parameter WAIT_MAX         = WAIT_CYCLES + 10;                    // 500 ns plus some additional margin
    
  parameter WAIT_TIMEOUT_2ms   = 2000000 / STABLE_CLOCK_PERIOD;//  2 ms time-out
  parameter WAIT_TLOCK_MAX     =  100000 / STABLE_CLOCK_PERIOD;//100 us time-out
  parameter WAIT_TIMEOUT_500us =  500000 / STABLE_CLOCK_PERIOD;//100 us time-out
    
  reg [7:0] init_wait_count = 0;
  reg       init_wait_done = 1'b0;
  reg       pll_reset_asserted = 1'b0;

  reg       tx_fsm_reset_done_int    = 1'b0;
  wire      tx_fsm_reset_done_int_s2;
  reg       tx_fsm_reset_done_int_s3 = 1'b0;
    
  parameter MAX_RETRIES          = 2**RETRY_COUNTER_BITWIDTH-1; 
  reg [7:0] retry_counter_int = 0;
  reg [18:0] time_out_counter = 0;
    
  reg      reset_time_out = 1'b0;
  reg      time_out_2ms   = 1'b0;  //--\Flags that the various time-out points 
  reg      time_tlock_max = 1'b0;  //--|have been reached.
  reg      time_out_500us = 1'b0;  //--/
    
  reg [9:0] mmcm_lock_count = 0;
  reg       mmcm_lock_int = 1'b0;
  wire      mmcm_lock_reclocked;
    
  reg       run_phase_alignment_int = 1'b0;
  wire      run_phase_alignment_int_s2;
  reg       run_phase_alignment_int_s3 = 1'b0;

  parameter MAX_WAIT_BYPASS      = 110000; //110000 TXUSRCLK cycles is the max time needed for Multilane designs

  reg [16:0] wait_bypass_count = 0;
  reg       time_out_wait_bypass    = 1'b0;
  wire      time_out_wait_bypass_s2;
  reg       time_out_wait_bypass_s3 = 1'b0;

  wire      txresetdone_s2;
  reg       txresetdone_s3 = 1'b0;

  wire      refclk_lost;

  wire      cplllock_sync;
  wire      qplllock_sync;
  reg       cplllock_ris_edge = 1'b0;
  reg       qplllock_ris_edge = 1'b0;
  reg       cplllock_prev;
  reg       qplllock_prev;

  //Alias section, signals used within this module mapped to output ports:
 assign RETRY_COUNTER     = retry_counter_int;
 assign RUN_PHALIGNMENT   = run_phase_alignment_int;
 assign TX_FSM_RESET_DONE = tx_fsm_reset_done_int;


  always @(posedge STABLE_CLOCK)
  begin
      // The counter starts running when configuration has finished and 
      // the clock is stable. When its maximum count-value has been reached,
      // the 500 ns from Answer Record 43482 have been passed.
      if (init_wait_count == WAIT_MAX) 
          init_wait_done <= `DLY  1'b1;
      else
        init_wait_count <= `DLY  init_wait_count + 1;
  end 

 
  always @(posedge STABLE_CLOCK)
  begin
      // One common large counter for generating three time-out signals.
      // Intermediate time-outs are derived from calculated values, based
      // on the period of the provided clock.
      if (reset_time_out == 1'b1)
      begin
        time_out_counter  <= `DLY  0;
        time_out_2ms      <= `DLY  1'b0;
        time_tlock_max    <= `DLY  1'b0;
        time_out_500us    <= `DLY  1'b0;
      end
      else
      begin
        if (time_out_counter == WAIT_TIMEOUT_2ms) 
          time_out_2ms <= `DLY  1'b1;
        else
          time_out_counter <= `DLY  time_out_counter + 1;
        
        if (time_out_counter == WAIT_TLOCK_MAX)
          time_tlock_max <= `DLY  1'b1;
      
        if (time_out_counter == WAIT_TIMEOUT_500us)
          time_out_500us <= `DLY  1'b1;
      end
  end 

  always @(posedge TXUSERCLK)
  begin
      if (MMCM_LOCK == 1'b0)
      begin
        mmcm_lock_count <= `DLY  0;
        mmcm_lock_int   <= `DLY  1'b0;
      end
      else
      begin 
        if (mmcm_lock_count < MMCM_LOCK_CNT_MAX - 1)
          mmcm_lock_count <= `DLY  mmcm_lock_count + 1;
        else
          mmcm_lock_int <= `DLY  1'b1;
      end
  end
  

  //Clock Domain Crossing
 xilinx_gth_16b_5g_cpll_sync_block sync_run_phase_alignment_int 
        (
           .clk             (TXUSERCLK),
           .data_in         (run_phase_alignment_int),
           .data_out        (run_phase_alignment_int_s2)
        );

 xilinx_gth_16b_5g_cpll_sync_block sync_tx_fsm_reset_done_int 
        (
           .clk             (TXUSERCLK),
           .data_in         (tx_fsm_reset_done_int),
           .data_out        (tx_fsm_reset_done_int_s2)
        );

  always @(posedge TXUSERCLK)
  begin
     run_phase_alignment_int_s3 <= `DLY run_phase_alignment_int_s2;
     tx_fsm_reset_done_int_s3   <= `DLY tx_fsm_reset_done_int_s2;
  end

xilinx_gth_16b_5g_cpll_sync_block sync_time_out_wait_bypass 
        (
           .clk             (STABLE_CLOCK),
           .data_in         (time_out_wait_bypass),
           .data_out        (time_out_wait_bypass_s2)
        );

 xilinx_gth_16b_5g_cpll_sync_block sync_TXRESETDONE 
        (
           .clk             (STABLE_CLOCK),
           .data_in         (TXRESETDONE),
           .data_out        (txresetdone_s2)
        );

 xilinx_gth_16b_5g_cpll_sync_block sync_mmcm_lock_reclocked
        (
           .clk             (STABLE_CLOCK),
           .data_in         (mmcm_lock_int),
           .data_out        (mmcm_lock_reclocked)
        );

 xilinx_gth_16b_5g_cpll_sync_block sync_cplllock
        (
           .clk             (STABLE_CLOCK),
           .data_in         (CPLLLOCK),
           .data_out        (cplllock_sync)
        );

 xilinx_gth_16b_5g_cpll_sync_block sync_qplllock
        (
           .clk             (STABLE_CLOCK),
           .data_in         (QPLLLOCK),
           .data_out        (qplllock_sync)
        );


  always @(posedge STABLE_CLOCK)
  begin
     time_out_wait_bypass_s3   <= `DLY time_out_wait_bypass_s2;
     txresetdone_s3            <= `DLY txresetdone_s2;
     cplllock_prev             <= `DLY cplllock_sync;
     qplllock_prev             <= `DLY qplllock_sync;
  end

  always @(posedge STABLE_CLOCK)
  begin
     if(SOFT_RESET == 1'b1)
       cplllock_ris_edge <= 1'b0;
     else if((cplllock_prev == 1'b0) && (cplllock_sync == 1'b1))
       cplllock_ris_edge <= 1'b1;
     else if(tx_state == ASSERT_ALL_RESETS || tx_state == RELEASE_PLL_RESET)
       cplllock_ris_edge <= cplllock_ris_edge;
     else 
       cplllock_ris_edge <= 1'b0;
  end

  always @(posedge STABLE_CLOCK)
  begin
     if((qplllock_prev == 1'b0) && (qplllock_sync == 1'b1))
       qplllock_ris_edge <= 1'b1;
     else if(tx_state == ASSERT_ALL_RESETS || tx_state == RELEASE_PLL_RESET)
       qplllock_ris_edge <= qplllock_ris_edge;
     else 
       qplllock_ris_edge <= 1'b0;
  end


  always @(posedge TXUSERCLK)
  begin
      if (run_phase_alignment_int_s3 == 1'b0)
      begin
        wait_bypass_count     <= `DLY  0;
        time_out_wait_bypass  <= `DLY  1'b0;
      end
      else if (run_phase_alignment_int_s3 == 1'b1 && tx_fsm_reset_done_int_s3 == 1'b0)
      begin
        if (wait_bypass_count == MAX_WAIT_BYPASS - 1)
          time_out_wait_bypass <= `DLY  1'b1;
        else
          wait_bypass_count <= `DLY  wait_bypass_count + 1;
      end
  end

  assign refclk_lost = ( TX_QPLL_USED == "TRUE"  && QPLLREFCLKLOST == 1'b1) ? 1'b1 : 
                       ( TX_QPLL_USED == "FALSE" && CPLLREFCLKLOST == 1'b1) ? 1'b1 : 1'b0;



  //FSM for resetting the GTX/GTH/GTP in the 7-series. 
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  //
  // Following steps are performed:
  // 1) Only for GTX - After configuration wait for approximately 500 ns as specified in 
  //    answer-record 43482
  // 2) Assert all resets on the GT and on an MMCM potentially connected. 
  //    After that wait until a reference-clock has been detected.
  // 3) Release the reset to the GT and wait until the GT-PLL has locked.
  // 4) Release the MMCM-reset and wait until the MMCM has signalled lock.
  //    Also signal to the RX-side which PLL has been reset.
  // 5) Wait for the RESET_DONE-signal from the GTX.
  // 6) Signal to start the phase-alignment procedure and wait for it to 
  //    finish.
  // 7) Reset-sequence has successfully run through. Signal this to the 
  //    rest of the design by asserting TX_FSM_RESET_DONE.
  
  always @(posedge STABLE_CLOCK)
  begin
      if (SOFT_RESET == 1'b1 || (tx_state != INIT && tx_state != ASSERT_ALL_RESETS && refclk_lost == 1'b1))
      begin
        tx_state                <= `DLY  INIT;
        TXUSERRDY               <= `DLY  1'b0;
        GTTXRESET               <= `DLY  1'b0;
        MMCM_RESET              <= `DLY  1'b1;
        tx_fsm_reset_done_int   <= `DLY  1'b0;
        QPLL_RESET              <= `DLY  1'b0;
        CPLL_RESET              <= `DLY  1'b0;
        pll_reset_asserted      <= `DLY  1'b0;
        reset_time_out          <= `DLY  1'b0;
        retry_counter_int       <= `DLY   0;
        run_phase_alignment_int <= `DLY  1'b0;
        RESET_PHALIGNMENT       <= `DLY  1'b1;
      end
      else
      begin 
        case (tx_state)
           INIT :
           begin 
            //Initial state after configuration. This state will be left after
            //approx. 500 ns and not be re-entered. 
            if (init_wait_done == 1'b1)
              tx_state           <= `DLY  ASSERT_ALL_RESETS;
              reset_time_out     <= `DLY  1'b1;
           end 
            
           ASSERT_ALL_RESETS :
           begin 
            //This is the state into which the FSM will always jump back if any
            //time-outs will occur. 
            //The number of retries is reported on the output RETRY_COUNTER. In 
            //case the transceiver never comes up for some reason, this machine 
            //will still continue its best and rerun until the FPGA is turned off
            //or the transceivers come up correctly.
            if (TX_QPLL_USED == "TRUE") 
            begin
              if (pll_reset_asserted == 1'b0)
              begin
                QPLL_RESET          <= `DLY  1'b1;
                pll_reset_asserted  <= `DLY  1'b1;
              end
              else
                QPLL_RESET          <= `DLY  1'b0;
            end
            else
            begin
              if (pll_reset_asserted == 1'b0)
              begin
                CPLL_RESET <= `DLY  1'b1;
                pll_reset_asserted  <= `DLY  1'b1;
              end
              else
                CPLL_RESET          <= `DLY  1'b0;
            end
            TXUSERRDY               <= `DLY  1'b0;
            GTTXRESET               <= `DLY  1'b1;
            MMCM_RESET              <= `DLY  1'b1;
            reset_time_out          <= `DLY  1'b0;
            run_phase_alignment_int <= `DLY  1'b0;     
            RESET_PHALIGNMENT       <= `DLY  1'b1;
            
            if ((TX_QPLL_USED == "TRUE" && QPLLREFCLKLOST == 1'b0 && pll_reset_asserted) ||
               (TX_QPLL_USED == "FALSE" && CPLLREFCLKLOST == 1'b0 && pll_reset_asserted)) 
              tx_state  <= `DLY  RELEASE_PLL_RESET;

           end           
            
           RELEASE_PLL_RESET :
           begin 
            //PLL-Reset of the GTX gets released and the time-out counter
            //starts running.
            pll_reset_asserted  <= `DLY  1'b0;
            
            if ((TX_QPLL_USED == "TRUE" && qplllock_ris_edge == 1'b1) ||
               (TX_QPLL_USED == "FALSE" && cplllock_ris_edge == 1'b1)) 
           begin
              tx_state  <= `DLY  RELEASE_MMCM_RESET;
              reset_time_out  <= `DLY  1'b1;
           end 
            
            if (time_out_2ms == 1'b1)
            begin
                if (retry_counter_int == MAX_RETRIES) 
                // If too many retries are performed compared to what is specified in 
                // the generic, the counter simply wraps around.
                retry_counter_int <= `DLY  0;
                else
                retry_counter_int <= `DLY  retry_counter_int + 1;
              tx_state            <= `DLY  ASSERT_ALL_RESETS; 
            end
           end           

           RELEASE_MMCM_RESET :
           begin 
            GTTXRESET <= `DLY  1'b0;
            reset_time_out  <= `DLY  1'b0;
            //Release of the MMCM-reset. Waiting for the MMCM to lock.
            MMCM_RESET <= `DLY  1'b0;
            if (mmcm_lock_reclocked == 1'b1)
            begin
              tx_state <= `DLY  WAIT_RESET_DONE;
              reset_time_out  <= `DLY  1'b1;
            end
            
            if (time_tlock_max == 1'b1 && mmcm_lock_reclocked == 1'b0)
            begin
              if (retry_counter_int == MAX_RETRIES)
                // If too many retries are performed compared to what is specified in 
                // the generic, the counter simply wraps around.
                retry_counter_int <= `DLY  0;
              else
                retry_counter_int <= `DLY  retry_counter_int + 1;
              tx_state            <= `DLY  ASSERT_ALL_RESETS; 
            end
           end            
            
           WAIT_RESET_DONE :
           begin 
            TXUSERRDY <= `DLY  1'b1;
            reset_time_out  <= `DLY  1'b0;
            if (txresetdone_s3 == 1'b1)
            begin              
              tx_state      <= `DLY  DO_PHASE_ALIGNMENT;               
              reset_time_out  <= `DLY  1'b1;
            end          

            if (time_out_500us == 1'b1)
            begin
              if (retry_counter_int == MAX_RETRIES) 
                // If too many retries are performed compared to what is specified in 
                // the generic, the counter simply wraps around.
                retry_counter_int <= `DLY  0;
              else
                retry_counter_int <= `DLY  retry_counter_int + 1;
              tx_state            <= `DLY  ASSERT_ALL_RESETS; 
            end 
           end            
          
           DO_PHASE_ALIGNMENT :
           begin 
            //The direct handling of the signals for the Phase Alignment is done outside
            //this state-machine. 
            RESET_PHALIGNMENT       <= `DLY  1'b0;
            run_phase_alignment_int <= `DLY  1'b1;
            reset_time_out          <= `DLY  1'b0;
            
            if (PHALIGNMENT_DONE == 1'b1)
              tx_state        <= `DLY  RESET_FSM_DONE;
            
            if (time_out_wait_bypass_s3 == 1'b1)
            begin
              if (retry_counter_int == MAX_RETRIES) 
                // If too many retries are performed compared to what is specified in 
                // the generic, the counter simply wraps around.
                retry_counter_int <= `DLY  0;
              else
                retry_counter_int <= `DLY   retry_counter_int + 1;
              tx_state            <= `DLY  ASSERT_ALL_RESETS; 
            end           
           end

           RESET_FSM_DONE :
           begin 
            reset_time_out        <= `DLY  1'b1;
            tx_fsm_reset_done_int <= `DLY  1'b1;
           end

           default:
              tx_state            <= `DLY  INIT; 

        endcase
      end
    end

endmodule

