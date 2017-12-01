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


entity led_fsm is
  port ( 
      reset_i  : in std_logic;
      clk_i    : in std_logic;
      button_i : in std_logic;
      LEDs_o   : out std_logic_vector(1 downto 0)
  );
end led_fsm;

architecture Behavioral of led_fsm is

    -- Custom state 
    type state_t is (IDLE, BLINK_SLOW, BLINK_FAST, COUNTER);
    
    signal state      : state_t := IDLE;

    signal button_pre : std_logic;
    
    signal slow_blinker : std_logic;
    
    signal fast_blinker : std_logic;
    
    signal counter_blinker : unsigned(1 downto 0);
    
    signal countdown : integer;

begin

    --================================--
    -- State switcher
    --================================--

    process(clk_i)
    begin
        if (rising_edge(clk_i)) then            
            if (reset_i = '1') then 
                state <= IDLE;
                button_pre <= button_i;
            else
                button_pre <= button_i;
                
                case state is
                    when IDLE => 
                        if (button_pre = '1' and button_i = '0') then
                            state <= BLINK_SLOW;
                        end if;
                    when BLINK_SLOW => 
                        if (button_pre = '1' and button_i = '0') then
                            state <= BLINK_FAST;
                        end if;
                    when BLINK_FAST => 
                        if (button_pre = '1' and button_i = '0') then
                            state <= COUNTER;
                        end if;           
                    when COUNTER => 
                        if (button_pre = '1' and button_i = '0') then
                            state <= IDLE;
                        end if;
                    when others => state <= IDLE;
                end case;
            end if;
        end if;
    end process; 



    --================================--
    -- States
    --================================--

    process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (reset_i = '1') then
                LEDs_o <= (others => '0');
            else
                case state is 
                    when IDLE => LEDs_o <= (others => '1');
                    when BLINK_SLOW => LEDs_o <= (others => slow_blinker);
                    when BLINK_FAST => LEDs_o <= (others => fast_blinker);
                    when COUNTER => LEDs_o <= std_logic_vector(counter_blinker);
                    when others => LEDs_o <= (others => '0');
                end case;
            end if;
        end if;
    end process;

    --================================--
    -- Blinkers
    --================================--
    
    i_slowblinker : entity work.led_fsm_blinker
        generic map(
            g_COUNTDOWN => 20_000_000
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            blinker_o => slow_blinker
        );

    i_fastblinker : entity work.led_fsm_blinker
        generic map(
            g_COUNTDOWN => 4_000_000
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            blinker_o => fast_blinker
        );
        
    process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            if (reset_i = '1') then
                countdown <= 40_000_000;
                counter_blinker <= (others => '0');
            else
                if (countdown > 0) then
                    countdown <= countdown - 1;
                else
                    countdown <= 40_000_000;
                    counter_blinker <= counter_blinker + 1; -- wraps around
                end if;
            end if;
        end if;
    end process;    

end Behavioral;
