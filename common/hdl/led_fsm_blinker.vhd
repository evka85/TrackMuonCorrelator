-------------------------------------------------------------------------------
--                                                                            
--       Unit Name: gem_ctp7                                            
--                                                                            
--     Description: 
--
--                                                                            
-------------------------------------------------------------------------------
--                                                                            
--           Notes:  State Machine for LEDs
--                                                                            
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

use work.gth_pkg.all;

use work.ctp7_utils_pkg.all;
use work.ttc_pkg.all;
use work.system_package.all;
use work.gem_pkg.all;
use work.ipbus.all;
use work.axi_pkg.all;
use work.ipb_addr_decode.all;



entity led_fsm_blinker is
  generic(
      g_COUNTDOWN : integer
  );
  port ( 
      clk_i     : in std_logic;
      reset_i   : in std_logic;
      blinker_o : out std_logic
  );
end led_fsm_blinker;

architecture Behavioral of led_fsm_blinker is

    signal countdown : integer := g_COUNTDOWN;
    signal blinker   : std_logic;

begin

    --================================--
    -- blinker
    --================================--
    blinker_o <= blinker;
    
    process(clk_i) 
    begin
        if (rising_edge(clk_i)) then
            if (reset_i = '1') then
                countdown <= g_COUNTDOWN;
            else            
                if (countdown > 0) then
                    countdown <= countdown - 1;
                else
                    countdown <= g_COUNTDOWN;
                    blinker <= not blinker;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
