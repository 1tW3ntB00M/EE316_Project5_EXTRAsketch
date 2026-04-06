library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_etch is
    port (
        clk_25    : in  std_logic;
        reset_n   : in  std_logic;

        -- Framebuffer interface (read-only for VGA side)
        fb_color  : in  std_logic_vector(23 downto 0); -- R[23:16], G[15:8], B[7:0]
        fb_x      : out unsigned(7 downto 0);  -- 0..255
        fb_y      : out unsigned(7 downto 0);  -- 0..255
        fb_en     : out std_logic;

        -- VGA outputs
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic_vector(3 downto 0);
        vga_g     : out std_logic_vector(3 downto 0);
        vga_b     : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of vga_etch is
    signal hsync, vsync, video_on : std_logic;
    signal pixel_x, pixel_y       : unsigned(9 downto 0);

    constant X_OFFSET : integer := 192;
    constant Y_OFFSET : integer := 112;
begin

    -- Instantiate sync generator
    sync_inst : entity work.vga_sync
        port map (
            clk      => clk_25,
            reset_n  => reset_n,
            hsync    => hsync,
            vsync    => vsync,
            video_on => video_on,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y
        );

    vga_hsync <= hsync;
    vga_vsync <= vsync;

    process(pixel_x, pixel_y, video_on, fb_color)
        variable x_int, y_int : integer;
    begin
        -- Default: background white
        vga_r <= (others => '1');
        vga_g <= (others => '1');
        vga_b <= (others => '1');
        fb_en <= '0';
        fb_x  <= (others => '0');
        fb_y  <= (others => '0');

        if video_on = '1' then
            x_int := to_integer(pixel_x);
            y_int := to_integer(pixel_y);

            if (x_int >= X_OFFSET and x_int < X_OFFSET + 256 and
                y_int >= Y_OFFSET and y_int < Y_OFFSET + 256) then

                -- Inside 256x256 sketch area
                fb_en <= '1';
                fb_x  <= to_unsigned(x_int - X_OFFSET, fb_x'length);
                fb_y  <= to_unsigned(y_int - Y_OFFSET, fb_y'length);

                -- Map 8-bit per channel to 4-bit VGA outputs
                vga_r <= fb_color(23 downto 20);
                vga_g <= fb_color(15 downto 12);
                vga_b <= fb_color(7 downto 4);
            else
                -- Outside sketch area: background (white)
                vga_r <= (others => '1');
                vga_g <= (others => '1');
                vga_b <= (others => '1');
            end if;
        end if;
    end process;

end architecture;