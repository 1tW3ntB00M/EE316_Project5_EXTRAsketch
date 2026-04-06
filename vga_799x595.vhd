----------------------------------------------------------------------------------
-- Company:  LBE BOOKS
-- Engineer: ?
-- 
-- Create Date: 04/02/2026 03:24:10 PM
-- Design Name: 
-- Module Name: vga_799x595 - Behavioral
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
-- https://www.youtube.com/watch?v=7j7brGz7u6M
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

entity vga_799x595 is
    Port (
        Clk : in std_logic;
        CLR : in std_logic;
        hsync : out std_logic;
        vsync : out std_logic;
        hc    : out std_logic_vector(9 downto 0);
        vc    : out std_logic_vector(9 downto 0);
        vidon : out std_logic
    );
end vga_799x595;

architecture Behavioral of vga_799x595 is

--CONSTANTS
constant hpixles : std_logic_vector(9 downto 0) := "1100100000";
    --Value of pixels in a horizontal line = 800
constant vlines  : std_logic_vector(9 downto 0) := "1000001101";
    --Number of horizontal lines in the display = 525
constant hbp     : std_logic_vector(9 downto 0) := "0010010000";
    --Horizontal back porch = 144 (128+16)
constant hfp     : std_logic_vector(9 downto 0) := "1100010000";
    --Horizontal front porch = 784 (128+16+640)
constant vbp     : std_logic_vector(9 downto 0) := "0000100011";
    --Vertical back porch = 35 (2+29)
constant vfp     : std_logic_vector(9 downto 0) := "1000000011";
    --Vertical  front porch = 515 (2+29+480)
    
--SIGNAS
signal hcs, vcs : std_logic_vector(9 downto 0);
    -- Horizontal and Vertical Counters
signal vsenable : std_logic;
    -- Enable for the Vertical counter 

begin
    --Counter for the Horizontal sync signal
    HCS_Conuitbulator : process(Clk, clr)
    begin
        if clr = '1' then
            hcs <= "0000000000";

        elsif(Clk'event and Clk = '1') then
            if unsigned(hcs) = unsigned(hpixles) - 1 then
                --The counter has reached the end
                hcs <= "0000000000";
                --Reset The counter
                vsenable <= '1';
            else
                hcs <= std_logic_vector(unsigned(hcs) + 1);
                --Increment the counter by 1
                vsenable <= '0';
                --Leave VSENSABLE OFF
            end if;
        end if;
    end process;
    hsync <= '0' when to_integer(unsigned(hcs)) < 128 else '1';
        --horizontal sync pulse is low when hc is 0 - 127
    
    --counter for the Vertical sync signal   
    VCS_Conuitbulator : process(Clk, clr)
        begin
            if clr = '1' then
                vcs <= "0000000000";
            elsif(Clk'event and Clk = '1' and vsenable = '1') then
                -- Increment when enabled
                if unsigned(vcs) =  unsigned(vlines) - 1 then
                    --reset when the number of lines is reaches
                    vcs <= "0000000000";
                else
                    vcs <= std_logic_vector(unsigned(vcs) + 1); -- increment vertical counter
                end if;
             end if;                   
    end process;
    --Vertical sync pulse is low when vc is 0 or 1
    vsync <= '0' when to_integer(unsigned(vcs)) < 2 else '1';
    
    --enable video out when within the porches
    vidon <= '1' when (unsigned(hcs) < unsigned(hfp) and unsigned(hcs) >= unsigned(hbp)) 
              and (unsigned(vcs) < unsigned(vfp) and unsigned(vcs) >= unsigned(vbp)) 
         else '0';
    
    --output horizontal and vertical counters
    hc <= hcs;
    vc <= vcs; 
                
end Behavioral;
