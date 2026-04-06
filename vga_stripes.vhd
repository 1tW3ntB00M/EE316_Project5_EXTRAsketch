----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 05:03:18 PM
-- Design Name: 
-- Module Name: vga_stripes - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.all; 

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_stripes is
    Port (
        vidon   : in std_logic;
        hc      : in std_logic_vector(9 downto 0);
        vc      : in std_logic_vector(9 downto 0);
        RED     : out std_logic_vector(2 downto 0);
        GREEN   : out std_logic_vector(2 downto 0);
        BLUE    : out std_logic_vector(1 downto 0)
    );
end vga_stripes;

architecture Behavioral of vga_stripes is

begin
    
    process(vidon, vc)
    begin
        RED   <= "000";
        GREEN <= "000";
        BLUE  <= "00";
        if vidon = '1' then
            RED   <= vc(4) & vc(4) & vc(4);
            GREEN <= not(vc(4) & vc(4) & vc(4));
        end if;
    end process;

end Behavioral;
