--Main Prog J.S.
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.Numeric_std.all;
	
entity S_RAM_Contrl is
		port ( 
		iCLK           : in std_LOGIC;
		iReset         : in std_logic;
		iEnable			: in std_logic; -- R_W
		pulse_in       : in std_LOGIC;
		iAddress			: in std_logic_vector(7 downto 0);
		iSData         : in std_logic_vector(15 downto 0);
		oSData         : out std_logic_vector(15 downto 0);
		addr           : out std_LOGIC_VECTOR(19 downto 0);
		we_n           : out std_logic; --Write enable input
		oe_n           : out std_logic; --Output enable input
		ce_n           : out std_logic; --Chip Enable input
		lb_n           : out std_logic; --Lower-byte Control
		ub_n           : out std_logic; --Upper-byte Control
		i_o            : inout std_LOGIC_VECTOR(15 downto 0)
		);
end S_RAM_Contrl;

architecture Structural of S_RAM_Contrl is

 type state_type is (init, ready, r1, r2, w1, w2);
 signal state    :  state_type;
 signal Ten      :  std_LOGIC;

--sim:/S_RAM_Contrl

begin

ce_n <= '0';
lb_n <= '0';
ub_n <= '0';
addr <= X"000" & iAddress;

	process(iCLK, iReset)
	begin
		
		if iReset = '1' then
			state  <=  init;
			Ten    <=  '1';
			we_n   <=  '1';
			oe_n   <=  '1';
		elsif (iCLK'event and iCLK = '1') then
			case state is
				when init =>
					state <= ready;
				when ready =>
					if pulse_in = '1' then
						if iEnable = '1' then
							we_n  <=  '0';
							oe_n  <=  '1';
							Ten   <=  '1';
							state <=  w1;
						else
							we_n  <=  '1';
							oe_n  <=  '0';
							Ten   <=  '0';
							state <=  r1;
						end if;
					end if;
				when r1 => 
					oSData <= i_o;
					state  <= r2;
				when r2 =>
					oe_n   <= '1';
					state  <= ready;
				when w1 =>
					state  <= w2;
				when w2 =>
					we_n   <= '1';
					state  <= ready;
				end case;
			end if;	
		
	end process;

-- i/o for SRAM Chip
i_o <= iSData when Ten = '1' else (others => 'Z');
end Structural;



