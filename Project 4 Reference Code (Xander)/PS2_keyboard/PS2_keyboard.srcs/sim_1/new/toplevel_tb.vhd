----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2026 11:48:56 AM
-- Design Name: 
-- Module Name: toplevel_tb - Behavioral
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

entity toplevel_tb is
--  Port ( );
end toplevel_tb;

architecture Behavioral of toplevel_tb is

    component toplevel is
        Port (
            clk : in std_logic;
            rst_btn : in std_logic;
            ttl_tx : out std_logic;
            ps2_clk : in std_logic;
            ps2_data : in std_logic
        );
    end component;
    
    signal clk : std_logic := '0';
    signal rst : std_logic;
    
    signal ps2_clk : std_logic;
    signal ps2_data : std_logic;
    constant ps2_clk_period : time := 100 us; -- 10 kHz
    
    signal ttl_tx : std_logic;

begin
    
    Inst_toplevel : toplevel
        Port map (
            clk => clk,
            rst_btn => rst,
            ttl_tx => ttl_tx,
            ps2_clk => ps2_clk,
            ps2_data => ps2_data
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
        wait for 5 ms;
    
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
