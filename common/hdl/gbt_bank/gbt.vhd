library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

-- Custom libraries and packages:
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_banks_user_setup.all;
use work.gem_pkg.all;

--=================================================================================================--
--#######################################   Entity   ##############################################--
--=================================================================================================--

entity gbt is
    generic(
        GBT_BANK_ID     : integer              := 0;
        NUM_LINKS       : integer              := 1;
        TX_OPTIMIZATION : integer range 0 to 1 := STANDARD;
        RX_OPTIMIZATION : integer range 0 to 1 := STANDARD;
        TX_ENCODING     : integer range 0 to 1 := GBT_FRAME;
        RX_ENCODING     : integer range 0 to 1 := GBT_FRAME
    );
    port(
        reset_i                     : in  std_logic;

        --========--
        -- Clocks --     
        --========--

        tx_frame_clk_i              : in  std_logic;
        rx_frame_clk_i              : in  std_logic;
        tx_word_clk_arr_i           : in  std_logic_vector(NUM_LINKS - 1 downto 0);
        rx_word_clk_arr_i           : in  std_logic_vector(NUM_LINKS - 1 downto 0);
        rx_word_common_clk_i        : in  std_logic;

        --========--
        -- GBT TX --
        --========--

        tx_ready_arr_i              : in  std_logic_vector(NUM_LINKS - 1 downto 0);
        tx_we_arr_i                 : in  std_logic_vector(NUM_LINKS - 1 downto 0);
        tx_data_arr_i               : in  t_gbt_frame_array(NUM_LINKS - 1 downto 0);
        tx_sca_data_arr_i           : in  t_std2_array(NUM_LINKS - 1 downto 0);
        tx_ic_data_arr_i            : in  t_std2_array(NUM_LINKS - 1 downto 0);
        tx_gearbox_aligned_arr_o    : out std_logic_vector(NUM_LINKS - 1 downto 0);
        tx_gearbox_align_done_arr_o : out std_logic_vector(NUM_LINKS - 1 downto 0);

        --========--              
        -- GBT RX --              
        --========-- 

        rx_frame_clk_rdy_arr_i      : in  std_logic_vector(NUM_LINKS - 1 downto 0);
        rx_word_clk_rdy_arr_i       : in  std_logic_vector(NUM_LINKS - 1 downto 0);
        
        rx_rdy_arr_o                : out std_logic_vector(NUM_LINKS - 1 downto 0);
        rx_bitslip_nbr_arr_o        : out rxBitSlipNbr_mxnbit_A(NUM_LINKS - 1 downto 0);
        rx_header_arr_o             : out std_logic_vector(NUM_LINKS - 1 downto 0);
        rx_header_locked_arr_o      : out std_logic_vector(NUM_LINKS - 1 downto 0);
        rx_data_valid_arr_o         : out std_logic_vector(NUM_LINKS - 1 downto 0);
        rx_data_arr_o               : out t_gbt_frame_array(NUM_LINKS - 1 downto 0);
        rx_sca_data_arr_o           : out t_std2_array(NUM_LINKS - 1 downto 0);
        rx_ic_data_arr_o            : out t_std2_array(NUM_LINKS - 1 downto 0);
        
        --========--              
        --   MGT  --              
        --========-- 
        
        mgt_rx_rdy_arr_i            : in  std_logic_vector(NUM_LINKS - 1 downto 0);
        mgt_tx_data_arr_o           : out t_gt_gbt_tx_data_arr(NUM_LINKS - 1 downto 0);
        mgt_rx_data_arr_i           : in  t_gt_gbt_rx_data_arr(NUM_LINKS - 1 downto 0)
        
    );
end gbt;

--=================================================================================================--
--####################################   Architecture   ###########################################-- 
--=================================================================================================--

architecture gbt_arch of gbt is

    --================================ Component Declarations ================================--
    
    component sync_fifo_gth_40
        port (
            rst       : IN  STD_LOGIC;
            wr_clk    : IN  STD_LOGIC;
            rd_clk    : IN  STD_LOGIC;
            din       : IN  STD_LOGIC_VECTOR(39 DOWNTO 0);
            wr_en     : IN  STD_LOGIC;
            rd_en     : IN  STD_LOGIC;
            dout      : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
            full      : OUT STD_LOGIC;
            overflow  : OUT STD_LOGIC;
            empty     : OUT STD_LOGIC;
            valid     : OUT STD_LOGIC;
            underflow : OUT STD_LOGIC
        );
    end component;
    
    --================================ Signal Declarations ================================--

    --========--
    -- GBT TX --
    --========--   

    -- Comment: TX word width is device dependent.

    signal tx_wordNbit_from_gbtTx : word_mxnbit_A(NUM_LINKS - 1 downto 0);
    signal phaligned_from_gbtTx   : std_logic_vector(NUM_LINKS - 1 downto 0);
    signal phcomputing_from_gbtTx : std_logic_vector(NUM_LINKS - 1 downto 0);

    signal tx_data_arr            : t_gbt_frame_array(NUM_LINKS - 1 downto 0);

    --==================================--              
    -- Multi Gigabit Transceivers (MGT) --          
    --==================================--                 

    -- Comment: RX word width is device dependent.

    signal rxReady_from_mgt        : std_logic_vector(NUM_LINKS - 1 downto 0);
    signal rx_wordNbit_from_mgt    : word_mxnbit_A(NUM_LINKS - 1 downto 0);

    --========--              
    -- GBT RX --              
    --========--     

    -- Comment: GBT RX bitslip width is device dependent.   

    signal rxBitSlipNbr_from_gbtRx   : rxBitSlipNbr_mxnbit_A(NUM_LINKS - 1 downto 0);
    signal rxHeaderLocked_from_gbtRx : std_logic_vector(NUM_LINKS - 1 downto 0);

    signal rx_common_word_clk        : std_logic;
    signal mgt_sync_rx_data_arr      : t_gt_gbt_rx_data_arr(NUM_LINKS - 1 downto 0);
    signal mgt_sync_rx_valid_arr     : std_logic_vector(NUM_LINKS - 1 downto 0);
   
    signal rx_data_arr               : t_gbt_frame_array(NUM_LINKS - 1 downto 0);
    --== constant signals ==--
    
    signal tied_to_ground   : std_logic;
    signal tied_to_vcc      : std_logic;    
        
--=====================================================================================--

--=================================================================================================--
begin                                   --========####   Architecture Body   ####========-- 
--=================================================================================================--

    rx_data_arr_o <= rx_data_arr;

    -- constant signals
    tied_to_ground <= '0';
    tied_to_vcc <= '1';

   --===============--
   -- RX Sync FIFOs --
   --===============--

    -- put the data from all GBT MGT RXs through sync a FIFO immediately to get it out of the BUFH domain and put it on a common clock domain which is on BUFG
    -- This is to let the GBT cores to be placed more freely (not constrained to the area that the RX BUFHs are spanning)
   
    rx_common_word_clk <= rx_word_common_clk_i;
    
    g_rx_sync_fifos : for i in 0 to NUM_LINKS - 1 generate
        
        i_rx_sync_fifo : component sync_fifo_gth_40
            port map(
                rst       => reset_i and not mgt_rx_rdy_arr_i(i),
                wr_clk    => rx_word_clk_arr_i(i),
                rd_clk    => rx_common_word_clk,
                din       => rx_wordNbit_from_mgt(i),
                wr_en     => tied_to_vcc,
                rd_en     => tied_to_vcc,
                dout      => mgt_sync_rx_data_arr(i),
                full      => open,
                overflow  => open,
                empty     => open,
                valid     => mgt_sync_rx_valid_arr(i),
                underflow => open
            );
            
        rx_wordNbit_from_mgt(i) <= mgt_rx_data_arr_i(i);
        
    end generate;
   
   --========--
   -- GBT TX --
   --========--
	gbtTx_param_generic_src_gen: if GBT_BANK_ID = 0 generate		
		gbtTx_gen: for i in 0 to NUM_LINKS -1 generate 
			gbtTx: entity work.gbt_tx        
				generic map (			
						GBT_BANK_ID                         => GBT_BANK_ID,
						NUM_LINKS									=> NUM_LINKS,
						TX_OPTIMIZATION							=> TX_OPTIMIZATION,
						RX_OPTIMIZATION							=> RX_OPTIMIZATION,
						TX_ENCODING									=> TX_ENCODING,
						RX_ENCODING									=> RX_ENCODING
				)
				port map (            
					-- Reset & Clocks:
					TX_RESET_I                          => reset_i,
					TX_FRAMECLK_I                       => tx_frame_clk_i,
					TX_WORDCLK_I                        => tx_word_clk_arr_i(i),
					-- Control:              
					TX_MGT_READY_I                      => tx_ready_arr_i(i),
				    PHASE_ALIGNED_O					    => phaligned_from_gbtTx(i),
					PHASE_COMPUTING_DONE_O				=> phcomputing_from_gbtTx(i),
					TX_ISDATA_SEL_I                     => tx_we_arr_i(i), 
					-- Data & Word:        
					TX_DATA_I                           => tx_data_arr(i),
					TX_WORD_O                           => tx_wordNbit_from_gbtTx(i),
					------------------------------------
					TX_EXTRA_DATA_WIDEBUS_I             => (others => '0')
				); 
				
				i_sync_gearbox_aligned : entity work.synchronizer
				    generic map(
				        N_STAGES => 2
				    )
				    port map(
				        async_i => phaligned_from_gbtTx(i),
				        clk_i   => tx_frame_clk_i,
				        sync_o  => tx_gearbox_aligned_arr_o(i)
				    );
				
				i_sync_gearbox_align_done : entity work.synchronizer
				    generic map(
				        N_STAGES => 2
				    )
				    port map(
				        async_i => phcomputing_from_gbtTx(i),
				        clk_i   => tx_frame_clk_i,
				        sync_o  => tx_gearbox_align_done_arr_o(i)
				    );
				
				mgt_tx_data_arr_o(i)         <= tx_wordNbit_from_gbtTx(i);
				
				tx_data_arr(i)              <= tx_ic_data_arr_i(i) & tx_sca_data_arr_i(i) & tx_data_arr_i(i)(79 downto 0);
				
			end generate;
	end generate;   

   --========--              
   -- GBT RX --              
   --========--
	gbtRx_param_generic_src_gen: if GBT_BANK_ID = 0 generate
		gbtRx_gen: for i in 0 to NUM_LINKS -1 generate    
		
			gbtRx: entity work.gbt_rx            
				generic map (
					GBT_BANK_ID                         => GBT_BANK_ID,
					NUM_LINKS									=> NUM_LINKS,
					TX_OPTIMIZATION							=> TX_OPTIMIZATION,
					RX_OPTIMIZATION							=> RX_OPTIMIZATION,
					TX_ENCODING									=> TX_ENCODING,
					RX_ENCODING									=> RX_ENCODING
				)         
				port map (              
					-- Reset & Clocks:
					RX_RESET_I                          => reset_i,
					RX_WORDCLK_I                        => rx_common_word_clk,
					RX_FRAMECLK_I                       => rx_frame_clk_i,                  
					-- Control:    
					RX_MGT_RDY_I                        => rxReady_from_mgt(i) and mgt_sync_rx_valid_arr(i),        
					RX_WORDCLK_READY_I                  => rx_word_clk_rdy_arr_i(i),
					RX_FRAMECLK_READY_I                 => rx_frame_clk_rdy_arr_i(i),
					------------------------------------
					RX_BITSLIP_NBR_O                    => rxBitSlipNbr_from_gbtRx(i),            
					RX_HEADER_LOCKED_O                  => rxHeaderLocked_from_gbtRx(i),                 
					RX_HEADER_FLAG_O                    => rx_header_arr_o(i),
					RX_ISDATA_FLAG_O                    => rx_data_valid_arr_o(i),            
					RX_READY_O                          => rx_rdy_arr_o(i),
					-- Word & Data:                  
					RX_WORD_I                           => mgt_sync_rx_data_arr(i),                  
					RX_DATA_O                           => rx_data_arr(i),
					------------------------------------
					RX_EXTRA_DATA_WIDEBUS_O             => open
				);             
				

            rxReady_from_mgt(i)                       <= mgt_rx_rdy_arr_i(i);
			rx_bitslip_nbr_arr_o(i)                   <= rxBitSlipNbr_from_gbtRx(i);                         
			rx_header_locked_arr_o(i)                 <= rxHeaderLocked_from_gbtRx(i);
            rx_sca_data_arr_o(i)                      <= rx_data_arr(i)(81 downto 80);
            rx_ic_data_arr_o(i)                       <= rx_data_arr(i)(83 downto 82);			
	 
		end generate;
	end generate;

   --=====================================================================================--
end gbt_arch;
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--