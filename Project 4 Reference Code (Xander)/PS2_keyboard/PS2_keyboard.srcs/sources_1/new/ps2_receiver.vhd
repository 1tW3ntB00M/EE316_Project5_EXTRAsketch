----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/26/2026 03:20:56 PM
-- Design Name: 
-- Module Name: ps2 - Behavioral
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
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ps2_receiver is
    Port ( ps2_clk : in STD_LOGIC;
           ps2_data : in STD_LOGIC;
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           scan_code : out std_logic_vector(7 downto 0);
           pulse : out STD_LOGIC
     );
end ps2_receiver;

architecture Behavioral of ps2_receiver is
    -- synchronization, only final q2 outputs should be used
    signal ps2_clk_q1, ps2_clk_q2   : std_logic;
    signal ps2_data_q1, ps2_data_q2 : std_logic;

    signal ps2_clk_falling : std_logic; -- clock falling edge

    signal sr : std_logic_vector(10 downto 0) := (others => '0'); -- shift register for 11 bit frames
    signal bit_cnt : integer range 0 to 11 := 0; -- progress through frame
    
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of ps2_clk_q2 : signal is "TRUE";
    attribute MARK_DEBUG of ps2_clk_falling : signal is "TRUE";
    attribute MARK_DEBUG of sr : signal is "TRUE";
    attribute MARK_DEBUG of bit_cnt : signal is "TRUE";

begin
    -- prevents metastability hopefully with two flip flops
    synchronizer : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ps2_clk_q1  <= '1';
                ps2_clk_q2  <= '1';
                ps2_data_q1 <= '1';
                ps2_data_q2 <= '1';
            else
                ps2_clk_q1  <= ps2_clk;
                ps2_clk_q2  <= ps2_clk_q1;

                ps2_data_q1 <= ps2_data;
                ps2_data_q2 <= ps2_data_q1;
            end if;
        end if;
    end process;

    -- pulse on falling edge of clock (clock is 0 and used to be 1)
    -- one of the flip flops is used for this
    -- idk if that's the best way or not
    ps2_clk_falling <= '1' when (ps2_clk_q2 = '1' and ps2_clk_q1 = '0') else '0';

    process(clk, rst)
    begin
        if rst = '1' then
            bit_cnt <= 0;
            sr <= (others => '0');
            scan_code <= (others => '0');
            pulse <= '0';
            
        elsif rising_edge(clk) then           
            pulse <= '0';

            if ps2_clk_falling = '1' then -- if falling edge of PS/2 clock
                sr <= ps2_data_q2 & sr(10 downto 1); -- shift right as LSB is sent first

                if bit_cnt = 10 then -- frame is full and 8 downto 1 are data
                    scan_code <= sr(9 downto 2); -- because the shift hasn't happened yet
                    pulse <= '1';
                    bit_cnt <= 0; -- reset for next
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
                
            end if;
        end if;
    end process;

end Behavioral;