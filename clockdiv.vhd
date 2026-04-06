----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 02:44:09 PM
-- Design Name: 
-- Module Name: clockdiv - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clockdiv is
    generic(
        INTERNAL_clk : integer := 125; --IN MHz
        divider      : integer := 5 
    );
    Port (
        CLK     : in std_logic;
        RESET   : in std_logic;
        CLK_div : out std_logic
    );
end clockdiv;

architecture Behavioral of clockdiv is

signal Clk_Val  : integer := (INTERNAL_clk*(10 ** 6))/divider;
signal Clk_Cnt  : integer := 0;
signal CLK_logi : std_logic;

begin

ClockUlator : process(CLK)
    begin
        if rising_edge(CLK) then
	       if RESET = '1' then
	           Clk_Cnt <= 0;
	           CLK_logi <= '0';
	       else
	           if (Clk_Cnt = Clk_Val) then
	               CLK_logi <= not CLK_logi;
	               Clk_Cnt <= 0;
	           else
	               Clk_Cnt <= Clk_Cnt +1;
	           end if;
	       end if;
       end if;
end process; 

end Behavioral;
