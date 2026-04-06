library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
    port (
        clk       : in  std_logic;  -- 25 MHz pixel clock
        reset_n   : in  std_logic;
        hsync     : out std_logic;
        vsync     : out std_logic;
        video_on  : out std_logic;
        pixel_x   : out unsigned(9 downto 0); -- 0..639
        pixel_y   : out unsigned(9 downto 0)  -- 0..479
    );
end entity;

architecture rtl of vga_sync is
    -- Horizontal timing
    constant H_VISIBLE      : integer := 640;
    constant H_FRONT_PORCH  : integer := 16;
    constant H_SYNC_PULSE   : integer := 96;
    constant H_BACK_PORCH   : integer := 48;
    constant H_TOTAL        : integer := H_VISIBLE + H_FRONT_PORCH +
                                         H_SYNC_PULSE + H_BACK_PORCH;

    -- Vertical timing
    constant V_VISIBLE      : integer := 480;
    constant V_FRONT_PORCH  : integer := 10;
    constant V_SYNC_PULSE   : integer := 2;
    constant V_BACK_PORCH   : integer := 33;
    constant V_TOTAL        : integer := V_VISIBLE + V_FRONT_PORCH +
                                         V_SYNC_PULSE + V_BACK_PORCH;

    signal h_count : unsigned(9 downto 0) := (others => '0'); -- 0..799
    signal v_count : unsigned(9 downto 0) := (others => '0'); -- 0..524
begin

    -- Horizontal & vertical counters
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            h_count <= (others => '0');
            v_count <= (others => '0');
        elsif rising_edge(clk) then
            if h_count = to_unsigned(H_TOTAL - 1, h_count'length) then
                h_count <= (others => '0');
                if v_count = to_unsigned(V_TOTAL - 1, v_count'length) then
                    v_count <= (others => '0');
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;

    -- Visible region coordinates
    pixel_x <= h_count;
    pixel_y <= v_count;

    -- Generate sync pulses (active low)
    hsync <= '0' when (h_count >= to_unsigned(H_VISIBLE + H_FRONT_PORCH, h_count'length) and
                       h_count <  to_unsigned(H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE, h_count'length))
             else '1';

    vsync <= '0' when (v_count >= to_unsigned(V_VISIBLE + V_FRONT_PORCH, v_count'length) and
                       v_count <  to_unsigned(V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE, v_count'length))
             else '1';

    -- Video on only in visible area
    video_on <= '1' when (h_count < to_unsigned(H_VISIBLE, h_count'length) and
                          v_count < to_unsigned(V_VISIBLE, v_count'length))
                else '0';

end architecture;