----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/26/2026 08:58:45 PM
-- Design Name: 
-- Module Name: ps2_tb - Behavioral
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

entity ps2_tb is
--  Port ( );
end ps2_tb;

architecture Behavioral of ps2_tb is

component ps2_receiver is
    Port ( ps2_clk : in STD_LOGIC;
           ps2_data : in STD_LOGIC;
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           scan_code : out std_logic_vector(7 downto 0);
           pulse : out STD_LOGIC
     );
end component;

component ps2_ascii_decoder is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ps2_scan_code : in STD_LOGIC_VECTOR (7 downto 0);
           ps2_pulse : in STD_LOGIC;
           ascii : out STD_LOGIC_VECTOR (7 downto 0);
           ascii_pulse : out STD_LOGIC);
end component;

signal clk : std_logic := '0';
signal rst : std_logic;

signal ps2_clk : std_logic;
signal ps2_data : std_logic;
signal ps2_pulse : std_logic;
signal ps2_scan_code : std_logic_vector(7 downto 0);

signal ascii_pulse : std_logic;
signal ascii : std_logic_vector(7 downto 0);

constant ps2_clk_period : time := 100 us; -- 10 kHz

begin

    Inst_ps2_reciever : ps2_receiver
        port map (
            ps2_clk => ps2_clk,
            ps2_data => ps2_data,
            clk => clk,
            rst => rst,
            scan_code => ps2_scan_code,
            pulse => ps2_pulse
         );
    
    Inst_ps2_ascii_decoder : ps2_ascii_decoder
        port map (
            clk => clk,
            rst => rst,
            ps2_scan_code => ps2_scan_code,
            ps2_pulse => ps2_pulse,
            ascii => ascii,
            ascii_pulse => ascii_pulse
        );
        
    clk <= not clk after 4 ns;

    process
        procedure keypress (
            constant data_byte : in std_logic_vector(7 downto 0)
        ) is
            variable parity : std_logic := '1'; -- store parity bit for later
        begin
            -- send start bit
            ps2_data <= '0';
            wait for ps2_clk_period/2;
            ps2_clk <= '0';
            wait for ps2_clk_period/2;
            ps2_clk <= '1';
            
            -- send data with lsb first
            for i in 0 to 7 loop
                ps2_data <= data_byte(i);
                parity := parity xor data_byte(i);
                
                wait for ps2_clk_period/2;
                ps2_clk <= '0';
                wait for ps2_clk_period/2;
                ps2_clk <= '1';
            end loop;
            
            -- send odd parity
            ps2_data <= not parity; 
            wait for ps2_clk_period/2;
            ps2_clk <= '0';
            wait for ps2_clk_period/2;
            ps2_clk <= '1';
            
            -- send stop bit
            ps2_data <= '1';
            wait for ps2_clk_period/2;
            ps2_clk <= '0';
            wait for ps2_clk_period/2;
            ps2_clk <= '1';
            
            -- idle the lines
            ps2_data <= '1';
            wait for ps2_clk_period * 2;
        end procedure;
    
    begin
        rst <= '1';
        ps2_clk <= '1';
        ps2_data <= '1';
        wait for 100 us;
        
        rst <= '0';
        wait for 100 us;
    
        keypress(x"1C"); -- make a
        keypress(x"F0"); -- break
        keypress(x"1C"); -- a
        
        wait for 1 ms;
        
        keypress(x"32"); -- make b
        keypress(x"F0"); -- break
        keypress(x"32"); -- b
        
        wait for 1 ms;
        
        keypress(x"21"); -- make c
        keypress(x"F0"); -- break
        keypress(x"21"); -- c
        
        wait for 1 ms;
        
        keypress(x"23"); -- make d
        keypress(x"F0"); -- break
        keypress(x"23"); -- d
        
        wait;
    end process;

end Behavioral;
