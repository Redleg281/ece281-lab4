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
    signal w_FSM1_o: std_logic_vector (3 downto 0);
    signal w_FSM2_o: std_logic_vector (3 downto 0);
    signal w_FSM_clk: std_logic;
    signal w_TDM4_clk: std_logic;
    signal w_orGate1: std_logic;
    signal w_orGate2: std_logic;
    signal w_Fseg: std_logic_vector (6 downto 0);
    signal w_seg1: std_logic_vector (6 downto 0);
    signal w_seg2: std_logic_vector (6 downto 0);

 
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
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
	
	clock_Div1 : clock_divider
	generic map (k_DIV => 25000000)
	port map(
	   i_clk => clk,
	   i_reset => w_orGate2,
	   o_clk => w_FSM_clk
	);
	
	clock_Div2 : clock_divider
	generic map (k_DIV => 200000)
	port map(
	   i_clk => clk,
	   i_reset => w_orGate2,
	   o_clk => w_TDM4_clk
	);
    	
   	FSM1_inst : elevator_controller_fsm port map(
        
    go_up_down => sw(0),
    i_reset => w_orGate1,
    i_clk => clk,
    is_stopped => sw(1),
    o_floor => w_FSM1_o
     
    );
    
   	FSM2_inst : elevator_controller_fsm port map(
        
    go_up_down => sw(15),
    i_reset => w_orGate1,
    i_clk => w_FSM_clk,
    is_stopped => sw(14),
    o_floor => w_FSM2_o
     
    );
    
    sevenseg1_inst : sevenseg_decoder port map(
    
    i_Hex => w_FSM1_o,
    o_seg_n => w_seg1
    
    );
   
    sevenseg2_inst : sevenseg_decoder port map(
    
    i_Hex => w_FSM2_o,
    o_seg_n => w_seg2
    
    );
    
    sevensegF_inst : sevenseg_decoder port map(
    
    i_Hex => "1111",
    o_seg_n => w_Fseg
    
    );
    
    TDM4_inst: TDM4
    generic map (k_WIDTH => 7)
    port map (
        i_reset => w_orGate1,
        i_clk => w_TDM4_clk,
        i_D3 => w_Fseg,
        i_D2 => w_seg2,
        i_D1 => w_Fseg,
        i_D0 => w_seg1,
        o_data => seg(6 downto 0),
        o_sel => an(3 downto 0)
        --C3C Josh Burke helped me realize I was using the wrong seg and an here.
       );
    
    
    
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	w_orGate1 <= btnU or btnL;
	w_orGate2 <= btnU or btnR;
	
	led(15) <= w_FSM_clk;
	led(14 downto 0) <= (others => '0');

	
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;
