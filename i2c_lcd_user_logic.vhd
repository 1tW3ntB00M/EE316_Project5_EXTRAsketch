library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.i2c_utilities.all;

entity i2c_lcd_user_logic is
    Generic ( CLK_FREQ : integer := 125_000_000 );
    Port (
        clk, rst    : in std_logic;
        rs          : in std_logic; -- 0: Command, 1: Data
        data_in     : in std_logic_vector(7 downto 0); 
        ena         : in std_logic;
        busy        : out std_logic;
        sda, scl    : inout std_logic
    );
end i2c_lcd_user_logic;

architecture Behavioral of i2c_lcd_user_logic is
    -- Internal Signals for Master
    signal i2c_ena, i2c_busy, i2c_rw : std_logic;
    signal i2c_data_wr : std_logic_vector(7 downto 0);
    signal i2c_addr : std_logic_vector(6 downto 0) := "0100111"; -- Change if needed (0x27)

    -- Sequencing logic
    signal i2c_cmds    : i2c_cmd_array_t;
    signal i2c_cmd_len : integer range 0 to MAX_CMDS;
    signal busy_cnt    : integer range 0 to MAX_CMDS := 0;
    signal busy_prev   : std_logic := '0';

    -- FSM States
    type state_t is (POR_DELAY, INIT_STEP, CLIENT_LOAD, TRANSMIT, DELAY, IDLE);
    signal state : state_t := POR_DELAY;
    
    signal init_idx : integer range 0 to 10 := 0;
    signal timer    : unsigned(31 downto 0) := (others => '0');
    
    --Reset NOT sig
    signal rst_n   : std_logic;

begin
    --Reset NOT
    rst_n        <= not rst ;
    -- Instantiate the original I2C Master
    MASTER_INST : entity work.i2c_master
        generic map (input_clk => CLK_FREQ, bus_clk => 100_000)
        port map (
            clk => clk, 
            reset_n => rst_n, 
            ena => i2c_ena, 
            addr => i2c_addr,
            rw => i2c_rw, 
            data_wr => i2c_data_wr, 
            busy => i2c_busy, 
            sda => sda, 
            scl => scl
        );

    busy <= '1' when state /= IDLE else '0';

    process(clk, rst)
    begin
        if rst = '1' then
            state <= POR_DELAY; timer <= (others => '0'); i2c_ena <= '0'; init_idx <= 0;
        elsif rising_edge(clk) then
            busy_prev <= i2c_busy;
            case state is
                when POR_DELAY => -- 40ms Power-on delay
                    if timer < (CLK_FREQ/1000)*40 then timer <= timer + 1;
                    else timer <= (others => '0'); state <= INIT_STEP; end if;

                when INIT_STEP => -- Hardcoded 4-bit Init Sequence
                    case init_idx is
                        when 0 => i2c_cmds(0).data <= x"3C"; -- 0x3, EN=1
                                  i2c_cmds(1).data <= x"38"; -- 0x3, EN=0
                                  i2c_cmd_len <= 2;
                        when 1 => i2c_cmds(0).data <= x"2C"; -- Switch to 4-bit mode (0x2)
                                  i2c_cmds(1).data <= x"28";
                                  i2c_cmd_len <= 2;
                        when others => state <= IDLE;
                    end case;
                    i2c_ena <= '1'; state <= TRANSMIT;

                when CLIENT_LOAD => -- Pulse EN high-low for high then low nibbles
                    i2c_cmds(0).data <= data_in(7 downto 4) & '1' & '1' & '0' & rs; -- EN=1
                    i2c_cmds(1).data <= data_in(7 downto 4) & '1' & '0' & '0' & rs; -- EN=0
                    i2c_cmds(2).data <= data_in(3 downto 0) & '1' & '1' & '0' & rs; -- EN=1
                    i2c_cmds(3).data <= data_in(3 downto 0) & '1' & '0' & '0' & rs; -- EN=0
                    i2c_cmd_len <= 4;
                    i2c_ena <= '1'; state <= TRANSMIT;

                when TRANSMIT =>
                    if busy_prev = '0' and i2c_busy = '1' then
                        busy_cnt <= busy_cnt + 1;
                    elsif busy_prev = '1' and i2c_busy = '0' then
                        if busy_cnt = i2c_cmd_len then
                            i2c_ena <= '0'; busy_cnt <= 0; state <= DELAY;
                        end if;
                    end if;
                    i2c_rw <= '0';
                    i2c_data_wr <= i2c_cmds(busy_cnt).data;

                when DELAY =>
                    if timer < (CLK_FREQ/1000)*2 then timer <= timer + 1;
                    else timer <= (others => '0'); 
                         if init_idx < 2 then init_idx <= init_idx + 1; state <= INIT_STEP;
                         else state <= IDLE; end if;
                    end if;

                when IDLE =>
                    if ena = '1' then state <= CLIENT_LOAD; end if;
            end case;
        end if;
    end process;
end Behavioral;


