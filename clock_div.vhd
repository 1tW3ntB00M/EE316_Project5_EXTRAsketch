----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Joshua Smith
-- 
-- Create Date: 03/05/2026 03:10:23 PM
-- Design Name: 
-- Module Name: clock_div - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: This file was ment to generate clocks for a UART 
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_div is
  generic(
    clock     : integer := 125;  --The internal board clock rate in MHz
    Baud_rate : integer := 9600; --The baud rate you want to hit
    Bytes     : integer := 16    --The number of byts you want to send
  );
  Port (
    iClk        : in std_logic;
    reset       : in std_logic;
    oTX_Clk_Div : out std_logic;
    oRX_Clk_Div : out std_logic
  );
end clock_div;

architecture Behavioral of clock_div is

    signal clk_num_TX  : integer := ((clock*(10 ** 6))/Baud_rate)/2;
    signal clk_num_RX  : integer := ((clock*(10 ** 6))/(Baud_rate*Bytes))/2;
    signal clk_cnt_TX  : integer :=0;
    signal clk_cnt_RX  : integer :=0;
	signal clk_en_TX   : std_logic;
	signal clk_gen_TX  : std_logic := '1';
	signal clk_en_RX   : std_logic;
	signal clk_gen_RX  : std_logic := '1';

begin

--MATHULATION: process(iClk)
--	 begin
--	   if reset = '1' then
--	       clk_num_TX <= 0;
--	       clk_num_RX <= 0;
--	   else
--           clk_num_TX <= (clock*(10 ** 6))/Baud_rate;
--           clk_num_RX <= (clock*(10 ** 6))/(Baud_rate*Bytes);
           
--       end if;
--end process;

Clock_Division_TX: process(iClk)
	 begin
	   if rising_edge(iClk) then
	       if reset = '1' then
	           clk_cnt_TX <= 0;
	           clk_gen_TX <= '0';
	       else
	           if (clk_cnt_TX = clk_num_TX) then
	               clk_gen_TX <= not clk_gen_TX;
	               clk_cnt_TX <= 0;
	           else
	               clk_cnt_TX <= clk_cnt_TX +1;
	           end if;
	       end if;
       end if;
end process;

Clock_Division_RX: process(iClk)
	 begin
	   if rising_edge(iClk) then
	       if reset = '1' then
	           clk_cnt_RX <= 0;
	           clk_gen_RX <= '0';
	       else
	           if (clk_cnt_RX = clk_num_RX) then
	               clk_gen_RX <= not clk_gen_RX;
	               clk_cnt_RX <= 0;
	           else
	               clk_cnt_RX <= clk_cnt_RX +1;
	           end if;
	       end if;
       end if;
end process;

oTX_Clk_Div <= clk_gen_TX;
oRX_Clk_Div <= clk_gen_RX;

end Behavioral;