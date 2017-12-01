-- mp7_readout zero supression
-- can raise and lower the strobe to the readout buffer
-- JRF Feb 2016
-- The new ZS block consists of two state machines, the main state machine handles the bulk of the work, transfering the header to the fifo2 and filling the fifo1 with the data blocks. 
-- the second state machine manages the transfer of the data blocks from fifo1 to fifo2 once a decision has been made to keep or reject the data. Data blocks are stored in fifo1 for the 
-- length of the block which can be any number of 32 bit words as indicated in the length field of the 6 word header. 
--
-- The main state machine performs the following tasks:   
-- 1 IDLE.   N clocks: IDLE 
-- 2 HDR. 	6 clocks: write the remaining 5 headaer words into FIFO2 (5 x 32 bit words) then go to 3
-- 3 INIT.   N clocks: IDLE until the init arrives and store the word in init_word, then go to 4
-- 4 DATA. 	N clocks: reset the counter1 to N from the length in the block header word when it arrives 
--          (use STROBE to see arrival). Transfer data when strobe is high for each block then raise 
--          blk_done once each block is done to trigger the transfer state machien. 
--          At the same time another process is checking the data to see if it's all zero. Set a flag 
--          to keep keep_blk. Once all data is transfered on token, go to 5. Note that we idle in this
--          state once data is finished until the token arrives.
-- 5 DONE. 	N clocks. when transfer state machine is in IDLE, then go to 1. 
--	When counter1 = 1 set done_block high to trigger transfer state machine. 
-- 
--
-- The transfer state machine performs the following tasks:
-- 1 IDLE.	N clocks: IDLE until done_block high AND fifo1 not empty, 
-- 2. BLK.  N clocks: set counter2 from stored block_length when. when counter2=1 and done_block 
--          high stay in this state for next block, when counter2=1 and done block low, go to 1.
--	        Note. set fifo2 write enable only if keep_block = true and increment the total_len. 
--          

-- The output state machine peroforms the following tasks:
-- 1 IDLE.   N Clocks: IDLE until main state machien is done then go to 2
-- 2 HDR.    1 clock:  overwrite the total_len in the stored HEADER and push onto the output_bus store total_len in counter3
-- 2 DATA.   counter3 Clocks: readout all data before going back to IDLE
--   




library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
--use ieee.std_logic_arith.all;

-- JRF Feb 2016
-- Adding the folloing components to use block ram to buffer my ZS data
library unisim;
use unisim.VComponents.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;
use work.mp7_readout_decl.all;

entity mp7_readout_zero_suppression is
	port(
        clk: in std_logic;
        rst: in std_logic;
        ipb_in: in ipb_wbus;
        ipb_out: out ipb_rbus;
		clk_p: in std_logic; 
		rst_p: in std_logic;
		daq_bus_in: in daq_bus; 
		daq_bus_out: out daq_bus;
		done_in: in std_logic; --JRF feb 2016 added this to hijack the rob_last signal in readout
		done_out: out std_logic --JRF feb 2016 added this to output the hijacked signal to the rob
	);

end mp7_readout_zero_suppression;


architecture rtl of mp7_readout_zero_suppression is

-- V1 state machine
	signal dbus_plus_1clk, dbus_plus_2clk, dbus_plus_3clk, dbus_plus_4clk: daq_bus;
	type state_type is (ST_IDLE, ST_HDR, ST_DATA, ST_DONE);
	
-- V2 State machines	
	type main_state_type is (ST_IDLE, ST_HDR, ST_INIT, ST_DATA, ST_DONE);
	type fifo_transfer_state_type is (ST_IDLE, ST_BLK, ST_DONE); 
    type output_state_type is (ST_IDLE, ST_HDR, ST_DATA, ST_DONE);
	signal state_main, state_main_prev, state_main_prev2, state_main_prev3: main_state_type; -- JRF this state machine manages the bulk of the work, writing fifo1, writing header info to fifo2, calculating length and triggering the readout from fifo2
	signal state_fifo_transfer, state_fifo_transfer_prev: fifo_transfer_state_type; -- JRF this state machine manages the reading from fifo1 and transfering the blocks to fifo2. It also handles ignoring data that is all zero.
	signal state_data_out, state_data_out_plus_1clk, state_data_out_plus_2clk: output_state_type; -- JRF this state machine manages the output of the fifo2

-- Signals from V1 of ZS block
	signal ctr, ro_mask_ctr: unsigned(15 downto 0);
	signal strobe: std_logic;
	signal ro_mask: std_logic_vector(31 downto 0) ; 
	signal ctrl: ipb_reg_v(1 downto 0);
    signal stat: ipb_reg_v(1 downto 0);
    signal en, rst_p_int: std_logic;


-- New Signals for V2
	signal first_header_word: daq_bus; -- JRF contains the first header word which contains the length to be overwritten at the end
	signal init_word: std_logic_vector(31 downto 0);
	signal total_length, total_length_plus_1clk, total_length_plus_2clk, counter_fifo2_read, init_length: unsigned(15 downto 0); 
	signal block_length, block_length_plus_1clk,block_length_plus_2clk: unsigned(7 downto 0);
	signal token_latch, keep_blk, keep_blk_plus_1clk, keep_blk_plus_2clk, keep_blk_plus_3clk, keep_blk_plus_4clk, keep_blk_plus_5clk, done_blk, done_blk_plus_1clk : std_logic;
	signal fifo2_write_strobe, fifo2_write_strobe_plus_1clk, fifo2_write_strobe_plus_2clk, fifo2_write_strobe_plus_3clk : std_logic;
    signal counter_fifo1_write, counter_fifo1_read, counter_cap_id: unsigned(7 downto 0);
    signal counter_start_out: unsigned(2 downto 0); --JRF this counter delays the start of output state machine
    signal dbus_zs_fifo1_out:  std_logic_vector(35 downto 0);   -- JRF data returned from the fifo to be shipped out might not need this. wire the fifo output directly.
    signal dbus_zs_fifo1_in: std_logic_vector(35 downto 0); -- JRF data to be sotred in the fifo during ZS
    signal dbus_zs_fifo2_out:  std_logic_vector(35 downto 0);   -- JRF data returned from the fifo to be shipped out might not need this. wire the fifo output directly.
    signal dbus_zs_fifo2_in: std_logic_vector(35 downto 0); -- JRF data to be sotred in the fifo during ZS
    signal dbus_zs_fifo2_in_pre1: std_logic_vector(35 downto 0); -- JRF used to multiplex data into fifo2 from two processes
    signal dbus_zs_fifo2_in_pre2: std_logic_vector(35 downto 0); -- JRF used to multiplex data into fifo2 from two processes
            
    signal zs_fifo1_wen, zs_fifo1_ren, zs_fifo1_full, zs_fifo1_empty, zs_fifo1_valid:  std_logic;
    signal zs_fifo2_wen, zs_fifo2_ren, zs_fifo2_full, zs_fifo2_empty, zs_fifo2_valid:  std_logic;
    signal zs_fifo2_wen_pre1, zs_fifo2_wen_pre2, zs_fifo2_wen_pre2_minus1clk, token_out, done_out_int, done_hdr_out:  std_logic;
        
    signal ro_mask_read_addr: std_logic_vector(6 downto 0); -- JRF contains the address based upon the capture id and which of the 6 words we are on from the block    
    signal ro_cap_id: unsigned(3 downto 0); -- 4 bit capture id which will determin which mask to use from the mask ram,
    signal ro_mode_id, ro_val_mode_id: unsigned(7 downto 0); -- mode_id from header and required mode id to determin if this is a validation event
    signal ro_mask_en: std_logic;
    
    constant dummy_1 : std_logic := '1';
    constant dummy_0: std_logic := '0';
    constant dummy_0_vec_1 : std_logic_vector(0 downto 0) := (others => '0');
    constant dummy_1_vec_1 : std_logic_vector(0 downto 0) := (others => '1');
    constant dummy_0_vec_32: std_logic_vector(31 downto 0) := (others => '0');
    --constant ZS_ENABLED : std_logic := '0'; -- this is declared in top_decl.vhd for each project

begin 

-- JRF there are some things which are needed regardless of whether we build with ZS or not
	-- JRF add the entity for the zs output fifo1. 
    zs_fifo1: entity work.zs_fifo_8k_x_36b
        port map (
            clk =>clk_p, --: IN STD_LOGIC;
            rst =>rst_p_int, --: IN STD_LOGIC;
            din =>dbus_zs_fifo1_in, --: IN STD_LOGIC_VECTOR(35 DOWNTO 0);
            wr_en => zs_fifo1_wen, --: IN STD_LOGIC;
            rd_en => zs_fifo1_ren, --: IN STD_LOGIC;
            dout =>dbus_zs_fifo1_out, -- : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            full => zs_fifo1_full, --: OUT STD_LOGIC;
            empty => zs_fifo1_empty, --: OUT STD_LOGIC;
            valid => zs_fifo1_valid -- : OUT STD_LOGIC
        );

-- JRF add the entity for the zs transfer fifo2.
    zs_fifo2: entity work.zs_fifo_8k_x_36b
        port map (
            clk =>clk_p, --: IN STD_LOGIC;
            rst =>rst_p_int, --: IN STD_LOGIC;
            din =>dbus_zs_fifo2_in, --: IN STD_LOGIC_VECTOR(35 DOWNTO 0);
            wr_en => zs_fifo2_wen, --: IN STD_LOGIC;
            rd_en => zs_fifo2_ren, --: IN STD_LOGIC;
            dout =>dbus_zs_fifo2_out, -- : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            full => zs_fifo2_full, --: OUT STD_LOGIC;
            empty => zs_fifo2_empty, --: OUT STD_LOGIC;
            valid => zs_fifo2_valid -- : OUT STD_LOGIC
        );

-- JRF add the entity for block ram to store the masks
    zs_blk_mask_32x72: entity work.blk_mem_zs_mask_32x72
        port map (         
            clka => clk, --: IN STD_LOGIC;
            ena => dummy_1, --: IN STD_LOGIC;
            wea => dummy_1_vec_1, --: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra => ctrl(0)(10 downto 4), --: IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            dina => ctrl(1)(31 downto 0), --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            douta => open, -- ro_mask(31 downto 0), --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            clkb => clk_p, --: IN STD_LOGIC;
            enb => dummy_1, --: IN STD_LOGIC;
            web => dummy_0_vec_1, --: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addrb => ro_mask_read_addr, --: IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            dinb => dummy_0_vec_32, --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            doutb => ro_mask(31 downto 0) --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );	
		   
 csr: entity work.ipbus_ctrlreg_v
  generic map(
      N_CTRL => 2,
      N_STAT => 2
  )
  port map(
      clk => clk,
      reset => rst,
      ipbus_in => ipb_in,
      ipbus_out => ipb_out,
      d => stat,
      q => ctrl
  );
  
ZS_DISABLE: if (ZS_ENABLED = false) generate

-- give all the unused inputs some value
-- ro_mask_en <= '0';
 --ctrl(0) <= (others => '0');
 --ctrl(1) <= (others => '0');
 stat(0) <= X"00000000";
 stat(1) <= X"00080848"; -- bit 24 - ZS Enabled, fifo 1 36 x 8, fifo 2 36 x 8, mask ram, 32 x 72 (0x48)
     
 ro_mask_read_addr <= (others => '0');
 ro_mask <= (others => '0');
 dbus_zs_fifo1_in <= (others => '0');
 zs_fifo1_wen <= '0';
 zs_fifo1_ren <= '0';
 dbus_zs_fifo2_in <= (others => '0');
 zs_fifo2_wen <= '0';
 zs_fifo2_ren <= '0';
 process(clk_p) -- process to select which done signal to output, this depends if we are performing zero suppression or not
    begin
        if rising_edge(clk_p) then
            done_out <= done_in; -- in this case we have no ZS algo so we just pass through
        end if;
    end process;

 process(clk_p) -- process to output data to rob Note we use a 2clk delayed version of the output state machine to be sure we align the arrival of the data from the fifo
    begin
        if rising_edge(clk_p) then
             daq_bus_out <= daq_bus_in; -- passthrough do nothing
        end if;
    end process;

end generate;

    
ZS_ENABLE: if (ZS_ENABLED = true) generate


		
-- set up the status registers
-- start with fifo flags
    stat(0)(0) <= zs_fifo1_full;
	stat(0)(1) <= zs_fifo1_empty;
	stat(0)(2) <= zs_fifo2_full;
	stat(0)(3) <= zs_fifo2_empty;
	stat(0)(31 downto 4) <=   "000000000000000000000" 
	                        & std_logic_vector(to_unsigned(main_state_type'pos(state_main), 3))
	                        & std_logic_vector(to_unsigned(fifo_transfer_state_type'pos(state_fifo_transfer), 2)) 
	                        & std_logic_vector(to_unsigned(output_state_type'pos(state_data_out), 2)); -- [3]&[2]&[2]
	-- fifo sizes
	stat(1) <= X"01080848"; -- bit 24 - ZS Enabled, fifo 1 36 x 8, fifo 2 36 x 8, mask ram, 32 x 72 (0x48)
	
			
   process(clk_p) -- process to select which done signal to output, this depends if we are performing zero suppression or not
   begin
       if rising_edge(clk_p) then
           if rst_p_int = '1' then
               done_out_int <= '0';
           else
               if en ='0' then
                   done_out_int <= done_in;
               elsif   en ='1' AND token_out = '1' then --  if we are in zs mode and we have finished writing the event to fifo
                   done_out_int <= '1';
               else
                   done_out_int <= '0'; 
               end if;
           end if;
       end if;
   end process;
   

-- JRF process to manage the token_latch 
    process(clk_p) 
    begin
        if rising_edge(clk_p) then
             if rst_p_int = '1' then 
                token_latch <= '0';
             elsif (state_main /= ST_IDLE and daq_bus_in.token = '1') 
                or ( token_latch = '1' and token_out = '0' ) then
                token_latch <= '1'; 
             else 
                token_latch <= '0';
             end if;
         end if;
    end process;    
    
    
-- JRF process to manage the ro_mask_ram_en to make modelsim happy
--    process(clk) 
--    begin
--        if rising_edge(clk) then
--             if rst = '1' then
--                ro_mask_en <= '0';
--             elsif ro_mask_en = '1' OR en = '1' then
--                ro_mask_en <= '1'; -- we just latch the enable mask
--             else 
--                ro_mask_en <= '0';
--             end if;
--         end if;
--    end process;    

-- JRF V2 State Machines
   
    process(clk_p) --JRF data_output state machine
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                state_data_out <= ST_IDLE;
            else
                case state_data_out is
                when ST_IDLE => -- only leave this state once we are sure all data have been transfered to fifo2 and that the total_length is now correct
                    if state_fifo_transfer = ST_DONE and counter_start_out = 6 then
                        state_data_out <= ST_HDR;
                    end if;
                    
                when ST_HDR =>
                        state_data_out <= ST_DATA;
                    
                when ST_DATA =>
                    if counter_fifo2_read <= 1  then --JRF TODO check this note we added token latch
                    -- there are two cases, token comes before data are finished outputting, and token comes after data are finished, so we 
                    -- must wait for the token to latch before we complete
                        state_data_out <= ST_DONE;
                    end if;
                when ST_DONE =>
                    if token_latch = '1' then
                        state_data_out <= ST_IDLE;
                    end if;
                end case;
            end if;
        end if;
    end process;
   
    process(clk_p) -- Main State Machine. Note that all state tranitions occur one clock after the fact. So all data manipulation will have to be done from a pipelined data bus signal.
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                state_main <= ST_IDLE;
            else
                case state_main is
                    when ST_IDLE => -- here we wait until the header arrives, when it arrives change state to HDR
                        if daq_bus_in.data.strobe = '1' and daq_bus_in.data.start = '1' then
                            state_main <= ST_HDR;
                        end if;
                    when ST_HDR => -- here we store the first header word in first_header_word and the remaining 5 header words in fifo2
                        if daq_bus_in.init = '1' and ctr >= to_unsigned(DAQ_N_HDR_WORDS - 1, 16) then --note that we stay in this state until init arrives, although we don't do anything in between
                            state_main <= ST_INIT;
                        end if;
                    when ST_INIT => -- here we store the init word and  wait for the data to arrive when the first word arrives we store the length 
                        if daq_bus_in.data.strobe = '1' then 
                            state_main <= ST_DATA;
                        end if;
                    when ST_DATA =>
                        if dbus_plus_1clk.token = '1' then -- we stay in this state until token, again, we don't do anythign when strobe is low.
                            -- Note that we take token from 1 clock later since it comes on the last word, not after the last word
                            state_main <= ST_DONE;
                        end if;
                    when ST_DONE =>
                        if state_fifo_transfer = ST_IDLE then -- JRF gonna try ST_DONE to speed up ... didn't work...  ST_IDLE then
                            state_main <= ST_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;


    process(clk_p) -- state machine to handle transfer of blocks from fifo1 to fifo2
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                state_fifo_transfer <= ST_IDLE;
            else
                case state_fifo_transfer is
                when ST_IDLE =>
                    if done_blk = '1' then
                        state_fifo_transfer <= ST_BLK;
                    end if;
                when ST_BLK =>
                    if  state_main /= ST_DATA and counter_fifo1_read < 1 and zs_fifo1_empty = '1' then 
                    -- JRF changed this to check for empty fifo 1 before finishing the 
                    -- block transfer, much simpler. Also we must not quit the transfer 
                    -- until the main state leaves DATA, just in case of big gaps between blocks
                    -- this happens when you enable channels that are far apart e.g. 0 and 4 is far enough
                        state_fifo_transfer <= ST_DONE;
                    end if;
                when ST_DONE =>
                    if counter_start_out = 6 then
                        state_fifo_transfer <= ST_IDLE;
                    end if;
                end case;
            end if;
        end if;
    end process;
   
 
   
        
--    process(clk_p) -- process to manage the last block signal
--    begin
--        if rising_edge(clk_p) then
--            if rst_p_int = '1' then
--                last_blk <= '0';
--            else
--                if ctr >= unsigned(first_header_word.data.data(15 downto 0))*2 then --state_fifo_transfer = ST_BLK and (dbus_plus_4clk.token = '1' OR last_blk = '1') then
--                    -- note we latch last block only while we are still transfering the blocks
--                    last_blk <= '1';
--                else
--                    last_blk <= '0'; 
--                end if;
--            end if;
--        end if;
    
--    end process;
    
    process(clk_p) -- process to output data to rob Note we use a 2clk delayed version of the output state machine to be sure we align the arrival of the data from the fifo
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
                daq_bus_out <=  daq_bus_in;
            else
                if en ='0' then
                     daq_bus_out <= daq_bus_in; -- passthrough do nothing
                else
                    if state_data_out_plus_2clk = ST_HDR then
                        -- we must handle the two cases for ODD and EVEN numbers of words
                        -- before we check we must add one more word for the header since...
                        -- The total length in the header appears to be total number of 64 bit words padded to 64 bit boundary. 
                        -- remember to first add one 32 bit word for the header that was never written to the fifo2.
                        if (total_length_plus_2clk+1 REM 2) = 0 then --EVEN CASE 
                            daq_bus_out.data.data <= first_header_word.data.data(31 downto 16) & std_logic_vector(((total_length_plus_2clk+1)/2) + 1); -- TODO check this. 
			            else -- ODD CASE
			                daq_bus_out.data.data <= first_header_word.data.data(31 downto 16) & std_logic_vector(((total_length_plus_2clk+2)/2) + 1);
			            end if;
                        daq_bus_out.data.valid <= first_header_word.data.valid;
                        daq_bus_out.data.start <= first_header_word.data.start;
                        daq_bus_out.init <= first_header_word.init;
                        daq_bus_out.token <= '0';
                        daq_bus_out.data.strobe <= first_header_word.data.strobe; 
                    elsif state_data_out_plus_2clk = ST_DATA then
                        daq_bus_out.data.data <= dbus_zs_fifo2_out(31 downto 0);
                        daq_bus_out.data.valid <= dbus_zs_fifo2_out(35);
                        daq_bus_out.data.start <= dbus_zs_fifo2_out(34);
                        daq_bus_out.init <= dbus_zs_fifo2_out(33);
                        daq_bus_out.token <= token_out;
                        daq_bus_out.data.strobe <= dbus_zs_fifo2_out(32); 
		            else
			            daq_bus_out.data.data <= (others => '0');
                        daq_bus_out.data.valid <= '0';
                        daq_bus_out.data.start <= '0';
                        daq_bus_out.init <= '0';
                        daq_bus_out.token <= token_out;
                        daq_bus_out.data.strobe <= '0';
			
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_p) -- process to manage fifo2 read enable
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_data_out = ST_IDLE  or state_data_out = ST_HDR then
               	zs_fifo2_ren <= '0';
            elsif state_data_out = ST_DATA then 
       		zs_fifo2_ren <= '1';     	
	    end if;
        end if;
    end process;
    
    process(clk_p) -- process to manage output counter
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_data_out = ST_IDLE then
               counter_fifo2_read <= (others => '0');
            elsif state_data_out = ST_HDR then -- set the length for fifo read, and replace the total length in the header
               counter_fifo2_read <= total_length + init_length; -- we have to remember to readout the init words
            elsif state_data_out = ST_DATA and counter_fifo2_read > 0 then
               counter_fifo2_read <= counter_fifo2_read - 1;
            end if;
        end if;
    end process;

    process(clk_p) -- process to manage token_out
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' then
               	token_out <= '0';
            elsif state_data_out_plus_1clk = ST_IDLE and state_data_out_plus_2clk = ST_DONE then
               	token_out <= '1';
            else
		        token_out <= '0';
            end if;
        end if;
    end process;

    -- process to increment the header counter.
    process(clk_p) 
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_main = ST_IDLE then
                ctr <= (others => '0');
            else
                if daq_bus_in.data.strobe = '1' and  state_main = ST_HDR  then -- note we only increment when strobe is high, this allows for data to arrive at any time.
                    ctr <= ctr + 1;
                end if;
            end if;
        end if;
    end process;
 
     -- process to increment the start out counter. This counter is used to delay the start of the readout
     -- to ensure that the total_length has completed counting before we use it
    process(clk_p) 
    begin
        if rising_edge(clk_p) then
            if rst_p_int = '1' or state_fifo_transfer = ST_IDLE then
                counter_start_out <= (others => '0');
            else
                if  state_fifo_transfer = ST_DONE then 
                    counter_start_out <= counter_start_out + 1;
                end if;
            end if;
        end if;
    end process;
   
-- JRF TODO reinclude the ro_mask from V1, use the capture id to select masks from a lookup of masks    
--    V1 process
--    process(clk_p)
--    begin
--        if rising_edge(clk_p) then
--            if rst_p_int = '1' then
--                ro_mask <= (others => '0');
--            elsif daq_bus_in.init = '1' then
--                ro_mask <= daq_bus_in.data.data(CLOCK_RATIO + 21 downto 22) & '0';
--            end if;
--        end if;
--    end process;
--    
--    process(clk_p)
--    begin
--       if rising_edge(clk_p) then
--           if (rst_p_int = '1') or (state = ST_IDLE) or (ro_mask_ctr = (CLOCK_RATIO)) then -- clock ratio -1
--               ro_mask_ctr <= (others => '0');
--           elsif state = ST_DATA and daq_bus_in.data.strobe = '1' then
--               ro_mask_ctr <= ro_mask_ctr + 1;
--           end if;
--       end if;
--    end process;
                        
--    strobe <= not ro_mask(to_integer(ro_mask_ctr)) when en = '1' else '1'; -- masks words being read out
    
    


-- JRF we require the following processes to pipeline various signals  
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            dbus_plus_1clk.data.data <= daq_bus_in.data.data;
            dbus_plus_1clk.data.valid <= daq_bus_in.data.valid;
            dbus_plus_1clk.data.start <= daq_bus_in.data.start;
            dbus_plus_1clk.init <= daq_bus_in.init;
            dbus_plus_1clk.token <= daq_bus_in.token;
            dbus_plus_1clk.data.strobe <= daq_bus_in.data.strobe; 
            
            dbus_plus_2clk.data.data <= dbus_plus_1clk.data.data;
            dbus_plus_2clk.data.valid <= dbus_plus_1clk.data.valid;
            dbus_plus_2clk.data.start <= dbus_plus_1clk.data.start;
            dbus_plus_2clk.init <= dbus_plus_1clk.init;
            dbus_plus_2clk.token <= dbus_plus_1clk.token;
            dbus_plus_2clk.data.strobe <= dbus_plus_1clk.data.strobe;
 
            dbus_plus_3clk.data.data <= dbus_plus_2clk.data.data;
            dbus_plus_3clk.data.valid <= dbus_plus_2clk.data.valid;
            dbus_plus_3clk.data.start <= dbus_plus_2clk.data.start;
            dbus_plus_3clk.init <= dbus_plus_2clk.init;
            dbus_plus_3clk.token <= dbus_plus_2clk.token;
            dbus_plus_3clk.data.strobe <= dbus_plus_2clk.data.strobe;
 
            dbus_plus_4clk.data.data <= dbus_plus_3clk.data.data;
            dbus_plus_4clk.data.valid <= dbus_plus_3clk.data.valid;
            dbus_plus_4clk.data.start <= dbus_plus_3clk.data.start;
            dbus_plus_4clk.init <= dbus_plus_3clk.init;
            dbus_plus_4clk.token <= dbus_plus_3clk.token;
            dbus_plus_4clk.data.strobe <= dbus_plus_3clk.data.strobe;
                                                           
            done_blk_plus_1clk <= done_blk;
            keep_blk_plus_1clk <= keep_blk;
            keep_blk_plus_2clk <= keep_blk_plus_1clk;
            keep_blk_plus_3clk <= keep_blk_plus_2clk;
            keep_blk_plus_4clk <= keep_blk_plus_3clk;
            keep_blk_plus_5clk <= keep_blk_plus_4clk;
            block_length_plus_1clk <= block_length;
            block_length_plus_2clk <= block_length_plus_1clk;
            
            state_main_prev <= state_main;
            state_main_prev2 <= state_main_prev;
            state_main_prev3 <= state_main_prev2;
            state_fifo_transfer_prev <= state_fifo_transfer;
	        state_data_out_plus_1clk <= state_data_out;
	        state_data_out_plus_2clk <= state_data_out_plus_1clk;
	        total_length_plus_1clk <=  total_length;
            total_length_plus_2clk <= total_length_plus_1clk;
            zs_fifo2_wen_pre2 <= zs_fifo2_wen_pre2_minus1clk;
            fifo2_write_strobe_plus_1clk <= fifo2_write_strobe;
            fifo2_write_strobe_plus_2clk <= fifo2_write_strobe_plus_1clk;
            fifo2_write_strobe_plus_3clk <= fifo2_write_strobe_plus_2clk;
           
            done_out <= done_out_int;
            --rst_p_int <= rst_p; -- we have added this to try to help meet timing.
        end if;
    end process;

    
    
    -- JRF some processes to manage counters:
    process(clk_p)
    begin
       if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_main_prev2 = ST_IDLE)  then 
               counter_fifo1_write <= (others => '0');
               block_length <= (others => '0');
           elsif  dbus_plus_3clk.data.strobe = '1' -- don't do anything if there is no strobe
               and ( ( (state_main_prev2 = ST_DATA) and (state_main_prev3 = ST_INIT) and (counter_fifo1_write = 0) )
               or  ( (state_main_prev2 = ST_DATA) and (state_main_prev3 = ST_DATA) and (counter_fifo1_write = 1) ) ) then -- first data word
               -- set the counter from the length in the 1clock pipelined data. 
               -- we also store the captureid for later use during ZS of this block
               counter_fifo1_write <= unsigned(dbus_plus_3clk.data.data(23 downto 16)) + 1;
               block_length <= unsigned(dbus_plus_3clk.data.data(23 downto 16)) + 1; -- store the length to use for the transfer from fifo1 to fifo2 header contains N-1
               
           elsif state_main_prev2 = ST_DATA and dbus_plus_3clk.data.strobe = '1' then -- only decrement on strobe
               counter_fifo1_write <= counter_fifo1_write - 1;
           else 
               --do nothing
           end if;
       end if;
    end process;    
    
    -- JRF process to manage capid and mask read address:
    process(clk_p)
    begin
       if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_main = ST_IDLE)  then 
               counter_cap_id <= (others => '0');
               ro_cap_id <= (others => '0');
               
               ro_mask_read_addr <= (others => '0');
           elsif  dbus_plus_1clk.data.strobe = '1' -- don't do anything if there is no strobe
               and ( ( (state_main = ST_DATA) and (state_main_prev = ST_INIT) and (counter_cap_id = 0) )
                   or  ( (state_main = ST_DATA) and (state_main_prev = ST_DATA) and (counter_cap_id = 1) ) ) then -- first data word
              
               ro_cap_id <=  unsigned(dbus_plus_1clk.data.data(11 downto 8)); -- note that cap id is 4 bits only, despite what it says in the manual
               counter_cap_id <= unsigned(dbus_plus_1clk.data.data(23 downto 16)) + 1;
               ro_mask_read_addr <=    std_logic_vector(  resize((unsigned(dbus_plus_1clk.data.data(11 downto 8)) + 1) * 6,ro_mask_read_addr'length) + resize(( 5 - ((counter_cap_id-2) mod 6)), ro_mask_read_addr'length  ) );
                            
           elsif state_main = ST_DATA and dbus_plus_1clk.data.strobe = '1' then -- only decrement on strobe
               counter_cap_id <= counter_cap_id - 1;
               ro_mask_read_addr <=    std_logic_vector(  resize(ro_cap_id * 6,ro_mask_read_addr'length) + resize(( 5 - ((counter_cap_id-2) mod 6)), ro_mask_read_addr'length  ) );
                              
           else 
               --do nothing
           end if;
       end if;
    end process;    
    
    -- JRF process to manage the mask read address based upon capture id
--    process(clk_p)
--    begin
--        if rising_edge(clk_p) then
--            if (rst_p_int = '1')  then 
--                ro_mask_read_addr <= (others => '0');
--            else
--                ro_mask_read_addr <=    std_logic_vector(  resize(ro_cap_id * 6,ro_mask_read_addr'length) + resize(( 5 - ((counter_cap_id-2) mod 6)), ro_mask_read_addr'length  ) );
--            end if;
--        end if;
--    end process;
    
    process(clk_p) -- JRF process to manage the counter_fifo1_Read
    begin
       if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_fifo_transfer = ST_IDLE)  then 
               counter_fifo1_read <= (others => '0');
           else 
               if ( state_fifo_transfer = ST_BLK and done_blk_plus_1clk = '1' ) then 
                   counter_fifo1_read <= block_length_plus_2clk;  
               elsif ( state_fifo_transfer = ST_BLK and counter_fifo1_read > 0 ) then 
                   counter_fifo1_read <= counter_fifo1_read - 1;
               end if; 
              
           end if;
       end if;
    end process;

--JRF process to capture and store the first header word
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            if (rst_p_int = '1')  then
                first_header_word.data.data <= (others => '0');
                first_header_word.data.valid <= '0';
                first_header_word.data.start <= '0';
                first_header_word.init <= '0';
            	first_header_word.token <= '0';
            	first_header_word.data.strobe <= '0';
                ro_mode_id <= (others => '0'); -- we will grab the mode at the same time
           elsif state_main = ST_HDR and state_main_prev = ST_IDLE and daq_bus_in.data.strobe = '1' and daq_bus_in.data.start = '1' then -- JRF if this is the first word store the data for later
                first_header_word  <= dbus_plus_1clk; --daq_bus_in; 
		        -- this header word contains the length that we should replace with  total_length later before we push this out.
           elsif state_main_prev3 = ST_IDLE and state_main_prev2 = ST_HDR then
                ro_mode_id <= unsigned(daq_bus_in.data.data(7 downto 0));
           end if;
       end if;
    end process;

--JRF process to fire done_blk
    process(clk_p)
    begin
       if rising_edge(clk_p) then
           if (rst_p_int = '1') or (state_main_prev3 = ST_IDLE) then 
                done_blk <= '0';
           elsif state_main_prev3 = ST_DATA and dbus_plus_4clk.data.strobe = '1' and  counter_fifo1_write = 1 then -- JRF if this is the first word store the data for later
                done_blk <= '1'; 
		   else
		        done_blk <= '0';
           end if;
       end if;
    end process;

    process(clk_p) -- process to manage the total_length. This is incremented when we write into fifo2 only when not writing INIT words
    begin
       if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_main_prev2 = ST_IDLE) then
                total_length <= (others => '0'); -- we are starting a new event so we must reset the total event length count 
                init_length  <= (others => '0');                     
            elsif (zs_fifo2_wen = '1' ) then 
                if (state_main_prev2 = ST_INIT)  then -- TODO check this. do not increment for init words
                    init_length <= init_length + 1;
                else
                    total_length <= total_length + 1;
                end if;
            end if;
       end if;
    end process;
    
-- JRF process to write header and init words directly to fifo2.   This works in conjunction with two state_main.
    process(clk_p)
    begin
       if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_main = ST_IDLE) then -- JRF if this is the first word we don't need to put it in fifo2, we will add this later when we push data out. 
                    dbus_zs_fifo2_in_pre1 <= (others => '0');    
                    zs_fifo2_wen_pre1 <= '0'; -- no need to write to fifo2
                    
            elsif state_main = ST_HDR then -- JRF if this is the remaining 5 words of the header we store the header directly in fifo2
                if daq_bus_in.data.strobe = '1' then
                    dbus_zs_fifo2_in_pre1  <=   daq_bus_in.data.valid & 
                                                daq_bus_in.data.start &
                                                daq_bus_in.init &
                                                daq_bus_in.data.strobe &
                                                daq_bus_in.data.data; -- output the data
                    zs_fifo2_wen_pre1 <= '1'; -- enable  write to fifo
                else
                    zs_fifo2_wen_pre1 <= '0';
                end if;
            elsif state_main = ST_INIT then  
                if  dbus_plus_1clk.init = '1'  then -- in this state we have to store the stat word if the INIT bit is set only  
                    dbus_zs_fifo2_in_pre1  <=   dbus_plus_1clk.data.valid & 
                                                dbus_plus_1clk.data.start &
                                                dbus_plus_1clk.init &
                                                dbus_plus_1clk.data.strobe &
                                                dbus_plus_1clk.data.data; -- note that we don't need strobe for init to be valid
                    zs_fifo2_wen_pre1 <= '1'; -- enable  write to fifo2
                else 
                    zs_fifo2_wen_pre1 <= '0';
                end if;
            end if;
        end if;
    end process;

--JRF process to write data to fifo1 and work out if we want to suppress this block
    process(clk_p)
    begin
       if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_main_prev3 /= ST_DATA) then -- reset
                zs_fifo1_wen <= '0'; 
                dbus_zs_fifo1_in  <= (others => '0');
                keep_blk <='0'; -- default is to discard blocks
                
            elsif (state_main_prev3 = ST_DATA) then
                if (dbus_plus_4clk.data.strobe = '1') then
                    zs_fifo1_wen <= '1'; 
                    dbus_zs_fifo1_in  <=    dbus_plus_4clk.data.valid & 
                                            dbus_plus_4clk.data.start &
                                            dbus_plus_4clk.init &
                                            dbus_plus_4clk.data.strobe &
                                            dbus_plus_4clk.data.data;
                    if (counter_fifo1_write < block_length) then -- skip the block header when deciding whether to keep block
                        keep_blk <= keep_blk or (or_reduce(dbus_plus_4clk.data.data and ro_mask)); -- or all the bits in data keep if anything is non-zero
                    else
                        --use this opportunity to clear the keep_blk
                        keep_blk <= '0';
                    end if;
                    
                else
                    zs_fifo1_wen <= '0';
                    
                end if;
            end if;
        end if;
    end process;
    
    process(clk_p) -- process to enable read from fifo 1 to go to fifo 2
    begin
        if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_fifo_transfer = ST_IDLE) or (state_fifo_transfer = ST_DONE) then
                zs_fifo1_ren <= '0';
                dbus_zs_fifo2_in_pre2 <= (others => '0');
            elsif state_fifo_transfer = ST_BLK then
                if (counter_fifo1_read > 0) then 
                    zs_fifo1_ren <= '1';
                else
                    zs_fifo1_ren <= '0';
                end if;
            end if;
            dbus_zs_fifo2_in_pre2 <= dbus_zs_fifo1_out; -- always pass the fifo1 out to the fif2_in_pre.
            zs_fifo2_wen_pre2_minus1clk <= zs_fifo1_ren; -- this simply assures that the read enable is always 1clock after the write enable.
        end if;
    end process;  
              
        
    process(clk_p) -- process to create the fifo2_write_strobe, note that this strobe needs to be used much later
                   -- so will have to be pipelined 
    begin
        if rising_edge(clk_p) then
            if (rst_p_int = '1') or (state_fifo_transfer = ST_IDLE) then
                fifo2_write_strobe <= '0';
            elsif  (done_blk_plus_1clk = '1' and keep_blk_plus_1clk = '1')
                or ( done_blk_plus_1clk = '1' and ro_mode_id = ro_val_mode_id)  -- we only trigger strobe in this case for validation events. keep_blk is 0, but we want to keep data and tag it
                or ( fifo2_write_strobe = '1' and counter_fifo1_read > 1) then --note we are latching on the write strobe so keep blk need only be high for 1 clock to trigger
                fifo2_write_strobe <= '1';
            else 
                fifo2_write_strobe <= '0';
            end if;
        end if;
    end process; 
    
    process(clk_p) -- process merge data and write enable bit for fifo2
    begin
        if rising_edge(clk_p) then
             if (rst_p_int = '1') or (state_main = ST_IDLE) then 
                   dbus_zs_fifo2_in <= (others => '0');    
                   zs_fifo2_wen <= '0'; 
             else
                if ( state_main = ST_HDR or state_main = ST_INIT ) then
                   dbus_zs_fifo2_in <= dbus_zs_fifo2_in_pre1;
                   zs_fifo2_wen <= zs_fifo2_wen_pre1;
                elsif (counter_fifo1_read = block_length - 3  
                        and keep_blk_plus_5clk = '0'
                        and fifo2_write_strobe_plus_3clk = '1') then -- note that we had to pipeline keep_blk a lot because we are deep into 
                    --only the blk header when keep blk is flase( this only happens for validation events)
                    dbus_zs_fifo2_in <= dbus_zs_fifo2_in_pre2(35 downto 1) & '1';
                    zs_fifo2_wen <= zs_fifo2_wen_pre2;
                elsif (fifo2_write_strobe_plus_3clk = '1') then -- only transfer data if needed
                    dbus_zs_fifo2_in <= dbus_zs_fifo2_in_pre2;
                    zs_fifo2_wen <= zs_fifo2_wen_pre2;
                --elsif () then --This case is exclusively for validation blocks. i.e. keep_blk = 0 but we keep anyway and tag in header
                else
                    zs_fifo2_wen <= '0';
                end if;
             end if;
        end if;
    end process;     
    
    


end generate;
    
    en <= ctrl(0)(0); -- ZS enable or disable
    ro_val_mode_id <= unsigned(ctrl(0)(19 downto 12)); -- mode ID on which to output validation events



    process(clk_p)
    begin
        if rising_edge(clk_p) then
            rst_p_int <= rst_p; -- we have added this to try to help meet timing.
        end if;
    end process;


end rtl;
