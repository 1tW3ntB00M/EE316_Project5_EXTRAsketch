----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2026 11:34:10 AM
-- Design Name: 
-- Module Name: toplevel - Behavioral
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

entity toplevel is
    Port (
        clk : in std_logic;
        rst_btn : in std_logic;
        ttl_tx : out std_logic;
        ps2_clk : in std_logic;
        ps2_data : in std_logic;
        led0 : out std_logic_vector(2 downto 0)
    );
end toplevel;

architecture Behavioral of toplevel is

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
    
    component TTL_serial is
        GENERIC (
            CONSTANT cnt_max : integer := 13021); 
            port (
            reset_n				: in std_logic; 
            clk				: in std_logic; 
            ena 				: in std_logic;	
            idata				: in std_logic_vector(7 downto 0);
            busy 				: out std_logic;
            TX				: out std_logic
            );
    end component;
    
    component Reset_Delay IS	
    PORT (
        SIGNAL iCLK : IN std_logic;	
        SIGNAL oRESET : OUT std_logic
			);	
    END component;
    
    signal ps2_pulse : std_logic;
    signal ps2_scan_code : std_logic_vector(7 downto 0);
    
    signal ascii_pulse : std_logic;
    signal ascii : std_logic_vector(7 downto 0);
    
    signal por : std_logic;
    signal rst : std_logic;
    signal rst_n : std_logic;
    
    signal ttl_en : std_logic;
    signal ttl_busy : std_logic;
    
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of ps2_pulse : signal is "TRUE";
    attribute MARK_DEBUG of ps2_scan_code : signal is "TRUE";
    attribute MARK_DEBUG of ascii_pulse : signal is "TRUE";
    attribute MARK_DEBUG of ascii : signal is "TRUE";
    attribute MARK_DEBUG of rst : signal is "TRUE";
    attribute MARK_DEBUG of ttl_en : signal is "TRUE";
    attribute MARK_DEBUG of ttl_busy : signal is "TRUE";
    attribute MARK_DEBUG of ps2_clk : signal is "TRUE";
    attribute MARK_DEBUG of ps2_data : signal is "TRUE";
    attribute MARK_DEBUG of ttl_tx : signal is "TRUE";

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
        
    Inst_TTL_serial : TTL_serial
        GENERIC map (
            cnt_max => 13021
        ) 
        port map (
            reset_n => rst_n,
            clk => clk,
            ena => ttl_en,
            idata => ascii,
            busy => ttl_busy,
            TX => ttl_tx
        );
    
    Inst_Reset_Delay : Reset_Delay
    PORT map (
        iCLK => clk,	
        oRESET => por
			);	
    
    rst <= por or rst_btn;
    rst_n <= not rst;
    
    led0(0) <= ttl_busy;
    
    process(clk, rst)
    begin
    
        if rst = '1' then
            ttl_en <= '0';
            
        elsif rising_edge(clk) then
            if ascii_pulse = '1' then
                ttl_en <= '1';
            end if;
                
            if ttl_en = '1' and ttl_busy = '1' then
                ttl_en <= '0';
            end if;
            
        end if;
    end process;

end Behavioral;
