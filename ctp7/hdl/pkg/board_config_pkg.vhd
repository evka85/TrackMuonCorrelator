-------------------------------------------------------------------------------
--                                                                            
--       Unit Name: board_config_package
--                                                                            
--     Description: Configuration for CTP7 board
--
--                                                                            
-------------------------------------------------------------------------------
--                                                                            
--           Notes:                                                           
--                                                                            
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

--============================================================================
--                                                         Package declaration
--============================================================================
package board_config_package is

    constant CFG_BOARD_TYPE     : std_logic_vector(3 downto 0) := x"1"; 

    constant CFG_MP7_QUADS_NUM  : integer := 3;                     -- number of MP7 transceiver quads to instantiate
    constant CFG_MUON_LINK_NUM  : integer := CFG_MP7_QUADS_NUM * 4; -- number of muon links


    --========================--
    --== Link configuration ==--
    --========================--
    
    type t_muon_link_config_arr is array (0 to (CFG_MP7_QUADS_NUM * 4) - 1) of integer range 0 to 79;
    
    constant CFG_MUON_LINK_CONFIG_ARR : t_muon_link_config_arr := (
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11
    );

    -- this record is used in CXP fiber to GTH map (holding tx and rx GTH index)
    type t_cxp_fiber_to_gth_link is record
        tx      : integer range 0 to 35; -- GTH TX index
        rx      : integer range 0 to 35; -- GTH RX index
    end record;
    
    -- this array is meant to hold mapping from CXP fiber index to GTH TX and RX indexes
    type t_cxp_fiber_to_gth_link_map is array (0 to 35) of t_cxp_fiber_to_gth_link;

    -- defines the GTH TX and RX index for each index of the CXP fiber
    constant CFG_CXP_FIBER_TO_GTH_MAP : t_cxp_fiber_to_gth_link_map := (
        (1, 2), -- fiber 0 (CXP 0)
        (3, 0), -- fiber 1
        (5, 4), -- fiber 2
        (0, 3), -- fiber 3
        (2, 5), -- fiber 4
        (4, 1), -- fiber 5
        (10, 7), -- fiber 6
        (8, 9), -- fiber 7
        (6, 10), -- fiber 8
        (11, 6), -- fiber 9
        (9, 8), -- fiber 10
        (7, 11), -- fiber 11
        (13, 15), -- fiber 12 (CXP 1)
        (15, 12), -- fiber 13
        (17, 16), -- fiber 14
        (12, 14), -- fiber 15 
        (14, 18), -- fiber 16
        (16, 13), -- fiber 17
        (22, 19), -- fiber 18
        (20, 23), -- fiber 19
        (18, 20), -- fiber 20
        (23, 17), -- fiber 21
        (21, 21), -- fiber 22
        (19, 22), -- fiber 23
        (25, 27), -- fiber 24 (CXP 2)
        (27, 24), -- fiber 25
        (29, 28), -- fiber 26
        (24, 26), -- fiber 27
        (26, 30), -- fiber 28
        (28, 25), -- fiber 29
        (34, 31), -- fiber 30
        (32, 35), -- fiber 31
        (30, 32), -- fiber 32
        (35, 29), -- fiber 33
        (33, 33), -- fiber 34
        (31, 34)  -- fiber 35
    );
    
end package board_config_package;
--============================================================================
--                                                                 Package end 
--============================================================================

