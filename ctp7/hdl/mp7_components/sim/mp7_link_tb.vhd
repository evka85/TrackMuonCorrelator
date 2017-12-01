-- This testbench allows users to exercise the ipbus in a purely VHDL environment
-- as opposed to using the ModelSim Foreign Language Interface (FLI).  The FLI 
-- offers a more comprehensive test enevironment, particularly for exercising 
-- the UDP/IP aspects and the concatention of ipbus requests. However, the FLI is
-- complex to setup and it is a proprietary standard of ModelSim.
--
-- The test bench is built upon the "ipbus_simulation" package that provides the 
-- read/writes procedures that would normsally be executed by a CPU. 
--
-- Greg Iles, July 2013


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.ipbus.all;
use work.ipbus_trans_decl.all;
use work.ipbus_simulation.all;

entity mp7_link_tb is
end mp7_link_tb;

architecture behave of mp7_link_tb is

  -- The number of Out-Of-Band interfaces to the ipbus master (i.e. not from the Ethernet MAC)   
  constant N_OOB: natural := 1;
  -- The number of ipbus slaves used in this example. 
  constant NSLV: positive := 1;

  -- Base addreses of ipbus slaves.  THis is defined in package "ipbus_addr_decode"
  constant BASE_ADD_MP7: unsigned(31 downto 0) := x"40002000";
 
  signal clk, rst: std_logic := '1'; 

  -- The ipbus interface to the ipbus master.
  -- The record type "ipb_wbus" contains elements ipb_addr, ipb_wdata, ipb_strobe, ipb_write
  -- The record type "ipb_rbus" contains elements ipb_rdata, ipb_ack, ipb_err
	signal ipb_out_m: ipb_wbus;
	signal ipb_in_m : ipb_rbus;

  -- The following should be ignored by the user.  They simply provide a communication 
  -- path from the read/write procedures into the ibus master for ipbus transactions.
	signal oob_in: ipbus_trans_in := ('0', X"00000000", '0');
	signal oob_out: ipbus_trans_out := (X"000", '0', '0', X"000", X"00000000");

  -- Array of ipbus records for communication to the ipbus slaves. 
	signal ipbw: ipb_wbus_array(NSLV - 1 downto 0);
	signal ipbr: ipb_rbus_array(NSLV - 1 downto 0);

  -- A register...
	signal ctrl: std_logic_vector(31 downto 0);

begin


  clk <= not clk after 10 ns;
  
  -----------------------------------------------------------------------
  -- Stage 1: CPU Simulator 
  --
  -- The following mimics a CPU executing a series of writes & reads.
  -- At present it just verifies that the following procedures behave 
  -- as expected.  The user should replace these reads & writes with 
  -- whatever they wish to test.
  --
  -- ipbus_write & ipbus_read
  -- ipbus_block_write & ipbus_block_read
  -- ipbus_read_modify_write
  ----------------------------------------------------------------------- 
   
  cpu: process
    
    variable rdata, wdata: std_logic_vector(31 downto 0) := x"00000000";
    variable rdata_buf, wdata_buf: type_ipbus_buffer(4 downto 0) := (others => x"00000000");
    variable mask: std_logic_vector(31 downto 0) := x"00000000";
  
  begin
  
    -- Wait for 1ns to get rid of all those pesky warnings at startup
    wait for 100 ns;
      
      report 
      " "  & CR & LF & 
      "----------------------------------------------------------------"  & CR & LF & 
      "Starting Simulation"  & CR & LF & 
      "----------------------------------------------------------------"  & CR & LF & 
      " ";

    wait for 100 ns;
      rst <= '0';
      report "### Exiting reset"  & CR & LF;
      -- Allow end of reset to propagate
    wait for 100 ns;
    
      report  "### Checking magic ID ###"  & CR & LF;
      wdata := x"DEADBEAF";
      ipbus_write(clk, oob_in, oob_out, std_logic_vector(BASE_ADD_MP7), wdata);
      ipbus_read(clk, oob_in, oob_out, std_logic_vector(BASE_ADD_MP7), rdata);
      assert (wdata = rdata)
        report "ID read doesn't equal expected" severity failure;
      
      report  "### Checking IPbus daisy chain of transmission buffers ###"  & CR & LF;
      wdata := x"00000000";
      mask := x"fe000000";
      ipbus_read_modify_write(clk, oob_in, oob_out, std_logic_vector(BASE_ADD_MP7 + x"6"), mask, wdata);
      wdata := x"00000000";
      ipbus_write(clk, oob_in, oob_out, std_logic_vector(BASE_ADD_MP7 + x"1004"), wdata);
      wdata_buf := (x"55555555", x"44444444", x"33333333", x"22222222", x"11111111");
      ipbus_block_write(clk, oob_in, oob_out, std_logic_vector(BASE_ADD_MP7 + x"1005"), wdata_buf, false);
      
      report 
      " "  & CR & LF & 
      "----------------------------------------------------------------"  & CR & LF & 
      "Ending Simulation"  & CR & LF & 
      "----------------------------------------------------------------"  & CR & LF & 
      " ";

      -- Following stops modelsim restarting....
    wait for 10 ms;

  end process;


  -----------------------------------------------------------------------
  -- Stage 2: The ipbus master.  
  --
  -- The bus master processes the ipbus requests generated in the 
  -- read/write procedures and passed into the master via "oob_in".  
  -- The ipbus read/write cycles take place on the bus and the result 
  -- is returned via "oob_out".  The user should not touch "oob_in" or
  -- "oob_out" - they are just the communication channel from the 
  -- read/write procedures to the ipbus bus master.
  -----------------------------------------------------------------------
   

  -- MAC input must have clock, even if usused, to avoid undefined signals (reset clocked).
	ipbus: entity work.ipbus_ctrl
		generic map(
			N_OOB => N_OOB)
		port map(
			mac_clk => clk,
			rst_macclk => '1',
			ipb_clk => clk,
			rst_ipb => rst,
			mac_rx_data => x"00",
			mac_rx_valid => '0',
			mac_rx_last => '0',
			mac_rx_error => '0',
			mac_tx_data => open,
			mac_tx_valid => open,
			mac_tx_last => open,
			mac_tx_error => open,
			mac_tx_ready => '0',
			ipb_out => ipb_out_m,
			ipb_in => ipb_in_m,
			mac_addr => x"000000000000",
			ip_addr => x"00000000",
			oob_in(0) => oob_in,
			oob_out(0) => oob_out);

  -----------------------------------------------------------------------
  -- Stage 3: Bus distribution, address decoder and bus slaves
  --
  -- The reads & writes are tested with the "ipbus_fabric" and
  -- slaves: "ipbus_ctrlreg", "ipbus_reg" and "ipbus_ram".  The "fabric"
  -- distributes the master ipbus signals "ipb_out_m" and "ipb_out_m" 
  -- to an array of ipbus slaves with "ipbw(x)" and fans back in their 
  -- response with array "ipbr(x)".  The fabric also contains an 
  -- addres decoder with parameters set in package "ipbus_addr_decode".  
  -- The user needs to create their own version of this file if they wish 
  -- to set up slaves with different base addresses.  The different slaves 
  -- are selected by either forwadrding or blocking the strobe.
  --
  -- While the fabric and slaves have been used in this test bench 
  -- the user is free to remove them and hang whatever they like 
  -- on the master bus: "ipb_out_m" and "ipb_out_m".  
  -----------------------------------------------------------------------
   
--	fabric: entity work.ipbus_fabric
--    generic map(NSLV => NSLV)
--    port map(
--      ipb_in => ipbus_out_m,
--      ipb_out => ipbus_in_m,
--      ipb_to_slaves => ipbw,
--      ipb_from_slaves => ipbr
--    );
    
  -- Generic ipbus ram block for testing
  -- generic addr_width defines number of significant address bits
  -- In order to allow Xilinx block RAM to be inferred:
  -- Reset does not clear the RAM contents (not implementable in Xilinx)
  -- There is one cycle of latency on the read / write
	slave0: entity work.mp7_link_sim
		port map(
			ipb_clk => clk,
			ipb_rst => rst,
			ipb_in => ipb_out_m,
			ipb_out => ipb_in_m
		);


end behave;