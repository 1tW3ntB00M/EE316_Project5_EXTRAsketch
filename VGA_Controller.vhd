----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Joshua Smith 
-- 
-- Create Date: 04/02/2026 12:36:20 PM
-- Design Name: 
-- Module Name: VGA_Controller - Behavioral
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

entity VGA_Controller is
--  generic(
--    HIGHT : integer := 256;
--    WIDTH : integer := 256
--  );
  Port (
    CLK     : in std_logic;
    RESET   : in std_logic;
    --IN FROM UART
    UART_in : in std_logic_vector(7 downto 0);
    --RGB PORTS
    RED     : out std_logic_vector(2 downto 0);
    GREEN   : out std_logic_vector(2 downto 0);
    BLUE    : out std_logic_vector(1 downto 0);
    --Controll Signals
    HS_out  : out std_logic;
    VS_out  : out std_logic
  );
end VGA_Controller;

architecture Behavioral of VGA_Controller is

type State_type is (INIT, X, Y, Color);
signal CS                      : state_type; -- current state
signal color_out               : std_logic_vector(5 downto 0);
signal UART_TEMP               : std_logic_vector(7 downto 0);
signal Hcount                  : std_logic_vector(7 downto 0);
signal Vcount                  : std_logic_vector(7 downto 0);
signal Active_Tile_Address     : integer := 0; --((Hcount/8)+(Vcount/8))*80 

begin

Graphixalizer : process(CLK)
    begin
        if RESET = '1' then
            CS <= INIT;
        elsif rising_edge(CLK) then
            case CS is
				when INIT =>
				    CS <= X;
				when X =>
				    UART_TEMP <= UART_in;
				    Hcount    <= UART_in;
				    if UART_TEMP /= UART_in then
				        CS <= Y;
				    end if;
                when Y =>
                    UART_TEMP <= UART_in;
				    Vcount    <= UART_in;
				    Active_Tile_Address <= to_integer((unsigned(Hcount)/8)+(unsigned(Vcount)/8))*80;
				    if UART_TEMP /= UART_in then
				        CS <= Color;
				    end if;
				when Color =>
                    UART_TEMP <= UART_in;
				    Vcount    <= UART_in;
				    Active_Tile_Address <= ((unsigned(Hcount)/8)+(unsigned(Vcount)/8))*80;
				    if UART_TEMP /= UART_in then
				        CS <= Color;
				    end if;
			end case;
        end if;
end process;

end Behavioral;
