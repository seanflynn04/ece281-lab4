library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal w_Hex_elevator1 : std_logic_vector(3 downto 0);
    signal w_elevator_clk : std_logic;
    signal w_sevenseg_clk : std_logic;
    signal w_fsm_reset : std_logic;
    signal w_clk_reset : std_logic;
    signal w_TDM : std_logic_vector(3 downto 0);
    signal w_Hex_elevator2 : std_logic_vector(3 downto 0);
    
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 25000000); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
     sevenseg_decoder_uut: sevenseg_decoder port map(
        i_Hex => w_TDM,
        o_seg_n => seg
       ); 	
       
       
     elevator1_controller_fsm_uut:  elevator_controller_fsm port map(
        i_clk => w_elevator_clk,
        i_reset => w_fsm_reset,
        is_stopped => sw(0),
        go_up_down => sw(1),
        o_floor => w_Hex_elevator1
        );
        
      elevator2_controller_fsm_uut:  elevator_controller_fsm port map(
        i_clk => w_elevator_clk,
        i_reset => w_fsm_reset,
        is_stopped => sw(14),
        go_up_down => sw(15),
        o_floor => w_Hex_elevator2
        );
        
     TDM4_uut: TDM4
      generic map(k_WIDTH => 4) -- bits in input and output
       port map ( 
       i_clk => w_sevenseg_clk,
       i_reset => btnU,
       i_D3 => "1111",
       i_D2 => w_Hex_elevator2,
       i_D1 => "1111",
       i_D0 => w_Hex_elevator1,
       o_data => w_TDM,
       o_sel => an
       );
        
      
	  clkdiv_sevenseg_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 100000 ) -- 1 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => w_clk_reset,
            o_clk   => w_sevenseg_clk
        );    
        
       clkdiv_elevator_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 50000000 ) -- 1 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => w_clk_reset,
            o_clk   => w_elevator_clk
        );    
        
	-- CONCURRENT STATEMENTS ----------------------------
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
    led(15) <= w_elevator_clk;
	led(14 downto 0) <= (others => '0');
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	masterResetproc : process(btnU,btnL,btnR)
	begin
     if btnU = '1' then    
        w_fsm_reset <= '1';
        w_clk_reset <= '1';   
     else
        w_clk_reset <= btnL;
        w_fsm_reset <= btnR;
     end if;
    end process;
     
     
end top_basys3_arch;
