--Main Prog K.S.

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.Numeric_std.all;
	
entity ModeSM is
	port ( 
		iClk				: in std_logic;
		Reset				: in std_logic;
		iKey			  	: in std_logic_vector(3 downto 0); --input of current key as hex
		iData          : in std_logic_vector(15 downto 0); ---data from Sram
		oAddress       : out std_logic_vector(7 downto 0); --Address to give Sram
		oData          : out std_logic_vector(15 downto 0);
		oSRAMEn        : out std_logic; --Sram read or write mode
		oPWMEn			: out std_logic;
		oClkEn			: out std_logic;
		oMode				: out std_logic_vector(1 downto 0);
		oFreq				: out std_logic_vector(1 downto 0);
		HEX0		      : out std_logic_vector(6 downto 0);
		HEX1		      : out std_logic_vector(6 downto 0);
     	HEX2		      : out std_logic_vector(6 downto 0);
     	HEX3		      : out std_logic_vector(6 downto 0);
     	HEX4		      : out std_logic_vector(6 downto 0);
     	HEX5		      : out std_logic_vector(6 downto 0);
		HEX6		      : out std_logic_vector(6 downto 0);
     	HEX7		      : out std_logic_vector(6 downto 0)
	);
end ModeSM;

architecture Structural of ModeSM is

component ROM IS
	PORT
	(
		address 		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock			: IN STD_LOGIC;
		q				: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;

component SevSegLUT is
		port ( 
		iClk			: in std_logic; 
		iHex			: in std_logic_vector(3 downto 0);
		oSevSeg			: out std_logic_vector(6 downto 0)
		);
end component;

component univ_bin_counter is
   generic(N: integer := 8; N2: integer := 255; N1: integer := 0);
   port(
		clk, reset			   		: in std_logic;
		syn_clr, load, en, up 		: in std_logic;
		clk_en 					   	: in std_logic := '1';			
		d						    : in std_logic_vector(N-1 downto 0);
		max_tick, min_tick			: out std_logic;
		q						    : out std_logic_vector(N-1 downto 0)		
   );
end component;

type state is (Init, Test, Pause, PWMGen);
signal MODE : state;
signal q 					: STD_LOGIC_VECTOR (15 DOWNTO 0);
signal address_sig  		: unsigned (7 DOWNTO 0):= "00000000";
signal init_done  			: std_logic;
signal direction         	: std_logic:= '1';
signal cnt_en				: std_logic;
signal clk_cnt				: integer range 0 to 49999999;
signal clk_en				: std_logic;
signal clk_cnt_12ns		 	: integer range 0 to 2;
signal clk_en_12ns		 	: std_logic;
signal hex_data          	: std_logic_vector(15 downto 0):= "0000000000000000";
signal add_data			 	: std_logic_vector(7 downto 0):= "00000000";
signal SRamDataBuffer    	: std_logic_vector(15 downto 0);
signal SRamAddressBuffer 	: std_logic_vector(7 downto 0);
signal hex_disp 		    : std_logic;
signal count				: std_logic_vector(7 downto 0);
signal freq					: unsigned(1 downto 0);

begin

ROM_INST : ROM
	port map(
			address 	=> std_logic_vector(address_sig),
			clock		=> iCLK,
			q		    => q
	);

inst_Counter_1s : univ_bin_counter
   port map(
			clk 		=> iCLK, 
			reset 		=> Reset,
			syn_clr 	=> Reset, 
			load 		=> '0', 
			en 			=> cnt_en, 
			up 			=> direction,
			clk_en 		=> clk_en,			
			d 			=>(others => '0'),
			max_tick 	=> open, 
			min_tick 	=> open,
			q 			=> count		
   );
	
inst_Hex0 : SevSegLUT
   port map(
			iClk							=> iClk,
			iHex							=> hex_data(3 downto 0),
			oSevSeg						=> HEX0
   );
	
inst_Hex1 : SevSegLUT
   port map(
			iClk							=> iClk,
			iHex							=> hex_data(7 downto 4),
			oSevSeg						=> HEX1
   );
	
inst_Hex2 : SevSegLUT
   port map(
			iClk							=> iClk,
			iHex							=> hex_data(11 downto 8),
			oSevSeg						=> HEX2
   );
	
inst_Hex3 : SevSegLUT
   port map(
			iClk							=> iClk,
			iHex							=> hex_data(15 downto 12),
			oSevSeg						=> HEX3
   );
	
inst_Hex4 : SevSegLUT
   port map(
			iClk							=> iClk,
			iHex							=> add_data(3 downto 0),
			oSevSeg						=> HEX4
   );
	
inst_Hex5 : SevSegLUT
   port map(
			iClk							=> iClk,
			iHex							=> add_data(7 downto 4),
			oSevSeg						=> HEX5
   );
-- clock enable 1 SEC

process(iClk)
	begin
		if rising_edge(iClk) then
			if (clk_cnt = 49999999) then --For sim - 49, for use 49999999
				clk_cnt <= 0;
				clk_en <= '1';
			else 
				clk_cnt <= clk_cnt + 1;
				clk_en <= '0';
			end if;
		end if;
end process;
	
-- Clock enable 12 ns
process(iClk)
	begin
		if rising_edge(iClk) then
			if (clk_cnt_12ns = 2) then 
				clk_cnt_12ns <= 0;
				clk_en_12ns <= '1';
			else 
				clk_cnt_12ns <= clk_cnt_12ns + 1;
				clk_en_12ns <= '0';
			end if;
		end if;
end process;
	
oClkEn <= clk_en or clk_en_12ns;
	
process(iCLK)
	begin
		if rising_edge(iCLK) then
			if Reset = '1' then
				cnt_en <= '0';
				oSRAMEn <= '1';
				oPWMEn <= '0';
				direction <= '1';
				address_sig <= "00000000";
				init_done <= '0';
				oMode <= "00";
				MODE <= Init;
			else		
				case MODE is 
					when Init =>
						HEX6 <= "1101111";
						HEX7 <= "1111111";
						if init_done = '0' and clk_en_12ns = '1' then
							oAddress <= std_logic_vector(address_sig);
							oData <= q;
							if address_sig = "11111111" then
								oAddress <= X"00";
								oData <= X"7FFF";
								oSRAMEn <= '0';
								init_done <= '1';
								cnt_en <= '1';
								oMode <= "01";
								Mode <= Test;
							end if;
							address_sig <= address_sig + 1;
						end if;
--						if iKey(0) = '1' then
--							cnt_en <= '1';
--							oMode <= "01";
--							Mode <= Test;
--						end if;

					when Test =>
						HEX6 <= "0101111";
						HEX7 <= "1111111";
						--If Key1 is pressed go to Pause mode
						if iKey(1) = '0' then
							cnt_en <='0';
							oMode <= "10";
							MODE <= Pause;
						--If Key2 is pressed go to PWMGen mode
						elsif iKey(2) = '0' then
							cnt_en <='0';
							oMode <= "11";
							oPWMEn <= '1';
							MODE <= PWMGen;
						end if;
						oAddress <= count;
						add_data <= count;
						hex_data <= iData;
									
					when Pause =>
						HEX6 <= "0001100";
						HEX7 <= "1111111";
						cnt_en <= '0';
						--If Key1 is pressed go to Test mode
						if iKey(1) = '0' then 
							cnt_en <= '1';
							oMode <= "01";
							MODE <= Test;
						end if;

					when PWMGen =>
						HEX6 <= "0010000";
						HEX7 <= "0001100";
						--If Key2 is pressed go to Test mode
						if iKey(2) = '0' then 
							cnt_en <= '1';
							oMode <= "01";
							oPWMEn <= '0';
							MODE <= Test;
						elsif iKey(3) = '0' then
							--Frequency change
							freq <= freq + 1;
							if freq = "11" then
								freq <= "00";
							end if;
							oFreq <= std_logic_vector(freq);
						end if;
				end case;
			end if;
		end if;
end process;


end Structural;








