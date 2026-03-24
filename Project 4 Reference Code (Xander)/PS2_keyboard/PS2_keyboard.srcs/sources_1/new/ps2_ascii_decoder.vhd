----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/26/2026 08:49:11 PM
-- Design Name: 
-- Module Name: ps2_ascii_decoder - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ps2_ascii_decoder is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ps2_scan_code : in STD_LOGIC_VECTOR (7 downto 0);
           ps2_pulse : in STD_LOGIC;
           ascii : out STD_LOGIC_VECTOR (7 downto 0);
           ascii_pulse : out STD_LOGIC);
end ps2_ascii_decoder;

architecture Behavioral of ps2_ascii_decoder is

    signal ignore : std_logic;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            ascii  <= (others => '0');
            ascii_pulse <= '0';
            ignore <= '0';
        elsif rising_edge(clk) then
            ascii_pulse <= '0';

            if ps2_pulse = '1' then -- only evaluate when PS/2 recieve indicates new data
                if ps2_scan_code = x"F0" then -- key released
                    ignore <= '1'; -- ignore next scan code
                elsif ignore = '1' then -- last data was 0xF0 so skip release code
                    ignore <= '0'; -- reset ignore flag for future
                else -- keypress
                    ascii_pulse <= '1'; -- indicate with pulse
                    case ps2_scan_code is -- decoding with set 2
                        when x"1C" => ascii <= x"61"; -- a
                        when x"32" => ascii <= x"62"; -- b
                        when x"21" => ascii <= x"63"; -- c
                        when x"23" => ascii <= x"64"; -- d
                        when x"24" => ascii <= x"65"; -- e
                        when x"2B" => ascii <= x"66"; -- f
                        when x"34" => ascii <= x"67"; -- g
                        when x"33" => ascii <= x"68"; -- h
                        when x"43" => ascii <= x"69"; -- i
                        when x"3B" => ascii <= x"6A"; -- j
                        when x"42" => ascii <= x"6B"; -- k
                        when x"4B" => ascii <= x"6C"; -- l
                        when x"3A" => ascii <= x"6D"; -- m
                        when x"31" => ascii <= x"6E"; -- n
                        when x"44" => ascii <= x"6F"; -- o
                        when x"4D" => ascii <= x"70"; -- p
                        when x"15" => ascii <= x"71"; -- q
                        when x"2D" => ascii <= x"72"; -- r
                        when x"1B" => ascii <= x"73"; -- s
                        when x"2C" => ascii <= x"74"; -- t
                        when x"3C" => ascii <= x"75"; -- u
                        when x"2A" => ascii <= x"76"; -- v
                        when x"1D" => ascii <= x"77"; -- w
                        when x"22" => ascii <= x"78"; -- x
                        when x"35" => ascii <= x"79"; -- y
                        when x"1A" => ascii <= x"7A"; -- z
                        when others => -- ignore non alphabetical characters
                            ascii <= (others => '0');
                            ascii_pulse <= '0'; 
                    end case;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
