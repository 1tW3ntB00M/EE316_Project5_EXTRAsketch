----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/24/2026 01:09:02 PM
-- Design Name: 
-- Module Name: Top_Level - Behavioral
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

entity Top_Level is
        port (
        btn0                : in std_logic; 
        iClk                : in std_logic;
        
        PS2_Clk             : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
        PS2_Data            : IN  STD_LOGIC;
           
        -- LCD I2C
        LCD_SDA             : inout std_logic;
        LCD_SCL             : inout std_logic;
        
        -- On board LEDS
        led0_g              : out std_logic;
        led0_b              : out std_logic;
        led0_r              : out std_logic;
        led1_g              : out std_logic;
        
        --PMOD LEDS
        Pmod_LEDS           : out std_logic_vector(3 downto 0);
        
        --UART PINS
        UART_RX             : in std_logic;
        UART_TX             : out std_logic;
        
        --Left Rotary Encoder (Up Down)
        L                   : in std_logic;
        L_CLK               : in std_logic;
        
        --Right Rotary Encoder (Left Right)
        R                   : in std_logic;
        R_CLK               : in std_logic;
        
        --PMOD VGA!
        VS                  : out std_logic;
        HS                  : out std_logic;
        NC                  : out std_logic_vector(1 downto 0);
        Red                 : out std_logic_vector(3 downto 0);
        Blue                : out std_logic_vector(3 downto 0);
        Green               : out std_logic_vector(3 downto 0)
        
--        LED0                   : out std_logic;
--        LED1                    : out std_logic;
--        LED2                    : out std_logic;
--        LED3                    : out std_logic
        );
end Top_Level;

architecture Structural of Top_Level is

-------------------------------------------------------------------------------------------------

component Reset_Delay is
        Port (
            iCLK        : IN  STD_LOGIC;                     --system clock input
            oRESET      : OUT  STD_LOGIC                    --clock signal from PS2 keyboard
            
        );
    end component;

-------------------------------------------------------------------------------------------------

component btn_debounce_toggle is
	generic ( CNTR_MAX: STD_LOGIC_VECTOR(15 downto 0) := X"FFFF"); 
    Port ( BTN_I 		: in   STD_LOGIC;
           CLK 			: in   STD_LOGIC;
           BTN_O 		: out  STD_LOGIC;
           TOGGLE_O	   	: out  STD_LOGIC;
		   PULSE_O 		: out  STD_LOGIC);
	end component;

-------------------------------------------------------------------------------------------------

component i2c_lcd_user_logic is
    Generic (
        CLK_FREQ    : integer := 125_000_000
    );
	Port (
		clk         : in STD_LOGIC;
		rst         : in std_logic;
		
		-- LCD client interface
		rs          : in std_logic; -- 0 for command register, 1 for data register
		data_in 	: in std_logic_vector(7 downto 0); -- byte to send (can be a control word or ASCII)
		ena         : in std_logic;
		busy        : out std_logic := '1';
		sda 		: inout std_logic;
		scl 		: inout std_logic
		
	);
end component;

-------------------------------------------------------------------------------------------------

component RotaryEN_SM is
  Port (
    reset    : IN std_logic;
	clk      : IN std_logic;
	A        : IN std_logic;
	B        : IN std_logic;
	count_en : OUT std_logic;
	count_up : OUT std_logic
  );
end component;

-------------------------------------------------------------------------------------------------

component ps2_keyboard_to_ascii is
        GENERIC(
            clk_freq                  : INTEGER := 50_000_000; --system clock frequency in Hz
            ps2_debounce_counter_size : INTEGER := 8);         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
        Port (
            clk        : IN  STD_LOGIC;                     --system clock input
            ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
            ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
            ascii_new  : OUT STD_LOGIC;                     --output flag indicating new ASCII value
            ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    end component;

-------------------------------------------------------------------------------------------------
        
 component clock_div is
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
end component;

-------------------------------------------------------------------------------------------------

component uart is
        Port (
            reset       :in  std_logic;
            txclk       :in  std_logic;
            ld_tx_data  :in  std_logic;
            tx_data     :in  std_logic_vector (7 downto 0);
            tx_enable   :in  std_logic;
            tx_out      :out std_logic;
            tx_empty    :out std_logic;
            rxclk       :in  std_logic;
            uld_rx_data :in  std_logic;
            rx_data     :out std_logic_vector (7 downto 0);
            rx_enable   :in  std_logic;
            rx_in       :in  std_logic;
            rx_empty    :out std_logic
        );
    end component;

-------------------------------------------------------------------------------------------------

    -- ==========================================
    -- INTERNAL SIGNALS
    -- ==========================================

    signal btn0_o            : std_logic;
    signal Reset_o           : std_logic;
    signal iReset            : std_logic;
    signal Reset_Master      : std_logic;
    signal Reset_Master_n    : std_logic;
    -- PS2 Keybord signals
    signal ascii_new         : std_logic;
    signal ascii_code        : std_logic_VECTOR(6 DOWNTO 0);
    signal ascii_code8       : std_logic_VECTOR(7 DOWNTO 0);
    --Uart Signals
    signal tx_data           : std_logic_vector(7 downto 0);
    signal ld_tx_pulse       : std_logic;
    signal uld_rx_data       : std_logic;
    signal rx_enable         : std_logic;
    signal rx_empty          : std_logic;
    signal rx_full           : std_logic;
    signal rx_in             : std_logic;
    signal TX_Clk            : std_logic;
    signal RX_Clk            : std_logic;
    signal rx_data           : std_logic_Vector(7 downto 0);
    signal btn_sync          : std_logic_vector(1 downto 0);
    --LCD Signals
    signal lcd_rs 			: std_logic;
	signal lcd_en			: std_logic;
	signal lcd_busy 		: std_logic;
    signal lcd_data 		: std_logic_vector(7 downto 0);
    -- Direction moved fuck you ROTARY
    signal direction        : std_logic_vector(3 downto 0); --Up, Down, Left, Right
	signal dbL 	: std_logic;
	signal dbL_CLK	: std_logic;
	signal dbR 	: std_logic;
	signal dbR_CLK	: std_logic;
	signal count_enL : std_logic;
	signal count_upL : std_logic;
	signal count_enR : std_logic;
	signal count_upR : std_logic;

	-- Control Registers
	signal current_color : std_logic_vector(23 downto 0) := x"000000"; -- Default Black
	signal pen_width     : std_logic_vector(1 downto 0) := "01";
	signal sketch_size   : std_logic := '0'; -- 0 for S2, 1 for S1

	-- Buffer for typing (up to 16 chars)
	type char_array is array (0 to 15) of std_logic_vector(7 downto 0);
	signal cmd_buffer : char_array := (others => x"20"); 
	signal buf_ptr    : integer range 0 to 15 := 0;
	signal status_ptr    : integer range 0 to 17 := 0;

	-- FSM for LCD/System Manager
	type main_state_t is (BOOT_DELAY, SEND_READY, IDLE, TX_CHAR, CMD_PARSE, UPDATE_STATUS, LCD_BS_STEP1, LCD_BS_STEP2, LCD_BS_STEP3);
	signal main_state : main_state_t := BOOT_DELAY;
	signal ready_str  : string(1 to 14) := "Hardware Ready";
	signal str_ptr    : integer range 1 to 15 := 1;

	-- Sub-states for multi-byte UART transmission
    	type uart_tx_state_t is (TX_IDLE, TX_START, TX_BYTE1, TX_BYTE2, TX_BYTE3, TX_WAIT1, TX_WAIT2, TX_WAIT3);
    	signal tx_fsm : uart_tx_state_t := TX_IDLE;
    
    	-- Internal registers for parsed values
    	signal hex_val : unsigned(3 downto 0); -- temporary for decoding


--------------------------------------------------------------------------------------

begin

--------------------------------------------------------------------------------------

Reset_Master   <= Reset_o or iReset;
Reset_Master_n <= not Reset_Master;
led0_g         <= ascii_new;
led1_g         <= Reset_Master;

--led0_b         <= LCD_en;
--rx_full        <= not rx_empty;

    -- ==========================================
    -- MIC Processes
    -- ==========================================

-- ==========================================
-- 1. Tri-Color LED Logic (Active Low for Cora-Z7)
-- ==========================================
led0_r <= '0' when current_color(23 downto 16) > x"7F" else '1';
led0_g <= '0' when current_color(15 downto 8)  > x"7F" else '1';
led0_b <= '0' when current_color(7 downto 0)   > x"7F" else '1';

-- ==========================================
-- 2. UART Manager: Keyboard -> UART
-- ==========================================
UART_MANAGER : process(iClk, Reset_Master)
begin
	if Reset_Master = '1' then
        ld_tx_pulse <= '0';
        tx_data <= (others => '0');
        tx_fsm <= TX_IDLE;
    elsif rising_edge(iClk) then
        ld_tx_pulse <= '0'; -- Default to no pulse

        case tx_fsm is
			when TX_IDLE =>
                if tx_empty = '1' then
                    -- 1. Priority: Rotary Encoders (Immediate)
                    if count_enR = '1' then
                        ld_tx_pulse <= '1';
                        if count_upR = '1' then tx_data <= x"52"; -- 'R'
                        else tx_data <= x"4C"; end if;           -- 'L'
                    elsif count_enL = '1' then
                        ld_tx_pulse <= '1';
                        if count_upL = '1' then tx_data <= x"55"; -- 'U'
                        else tx_data <= x"44"; end if;           -- 'D'
					elsif main_state = CMD_PARSE then
						tx_fsm <= TX_START;
					end if;
				end if;
				ld_tx_pulse <= '0'; -- Explicitly clear the load signal
                main_state <= UPDATE_STATUS; -- Return to the main system flow
			when TX_START =>
            	tx_data <= cmd_buffer(0); -- Send the Tag (#, W, or S)
                ld_tx_pulse <= '1';
                tx_fsm <= TX_WAIT1;

			when TX_WAIT1 => tx_fsm <= TX_BYTE1;

            when TX_BYTE1 =>
                tx_data <= cmd_buffer(1); -- Send the Value
                ld_tx_pulse <= '1';
			    if cmd_buffer(0) = x"23" then
					tx_fsm <= TX_WAIT2;
			    else 
					tx_fsm <= TX_IDLE;
			    end if;

			when TX_WAIT2 => tx_fsm <= TX_BYTE2;

    		when TX_BYTE2 =>
        		tx_data <= cmd_buffer(2); -- Send Green
        		ld_tx_pulse <= '1';
        		tx_fsm <= TX_WAIT3;

			when TX_WAIT3 => tx_fsm <= TX_BYTE3;

    		when TX_BYTE3 =>
        		tx_data <= cmd_buffer(3); -- Send Blue
        		ld_tx_pulse <= '1';
			    tx_fsm <= TX_IDLE;

			when others => tx_fsm <= TX_IDLE;
		end case;
	
-- ==========================================
-- 2. LCD Manager: Keyboard -> LCD
-- ==========================================
LCD_MANAGER : process(iClk, Reset_Master)
begin
    if Reset_Master = '1' then
        main_state <= BOOT_DELAY;
        str_ptr <= 1;
        buf_ptr <= 0;
        lcd_en <= '0';
    elsif rising_edge(iClk) then
        lcd_en <= '0';         

        case main_state is
            when BOOT_DELAY =>
                if lcd_busy = '0' then main_state <= SEND_READY; end if;

            when SEND_READY =>
                if lcd_busy = '0' then
                    lcd_rs   <= '1';
                    lcd_data <= std_logic_vector(to_unsigned(character'pos(ready_str(str_ptr)), 8));
                    lcd_en   <= '1';
                    ld_tx_pulse <= '1'; -- Send "Hardware Ready" to PC UART too
                    if str_ptr < 14 then str_ptr <= str_ptr + 1;
                    else main_state <= IDLE; end if;
                end if;

            when IDLE =>

                if ascii_new = '1' then
                    if ascii_code = x"0D" then -- ENTER
                        main_state <= CMD_PARSE;
                    elsif ascii_code = x"08" then -- BACKSPACE
                        if buf_ptr > 0 then 
			    			buf_ptr <= buf_ptr - 1;
			    			main_state <= LCD_BS_STEP1; 
						end if;
                    else
                        -- Echo to LCD and Buffer
                        cmd_buffer(buf_ptr) <= '0' & ascii_code;
                        lcd_data <= '0' & ascii_code;
                        lcd_rs   <= '1';
                        lcd_en   <= '1';
                        if buf_ptr < 15 then buf_ptr <= buf_ptr + 1; end if;
                    end if;
                end if;

            when CMD_PARSE =>
                -- Color Change: #[RRGGBB] -> Tag '#'
                if cmd_buffer(0) = x"23" then 
                    -- Basic parsing: only first 2 chars for brevity, add others as needed
		    		if cmd_buffer(1) = x"66" and cmd_buffer(2) = x"66" then
                		current_color(23 downto 16) <= x"FF";
		    		else current_color(23 downto 16) <= x"00";
		    		end if;
		    		if cmd_buffer(3) = x"66" and cmd_buffer(4) = x"66" then
                		current_color(15 downto 8) <= x"FF";
		    		else current_color(15 downto 8) <= x"00";
		    		end if;
		    		if cmd_buffer(5) = x"66" and cmd_buffer(6) = x"66" then
                		current_color(7 downto 0) <= x"FF";
		    		else current_color(7 downto 0) <= x"00";
		    		end if;

                    tx_fsm <= TX_START; 

                -- Width Change: W[1-3] -> Tag 'W'
                elsif cmd_buffer(0) = x"57" then
                    pen_width <= cmd_buffer(1)(1 downto 0);
                    tx_fsm <= TX_START;

                -- Size Change: S[1-2] -> Tag 'S'
                elsif cmd_buffer(0) = x"53" then
                    sketch_size <= cmd_buffer(1)(0);
                    tx_fsm <= TX_START;
                end if;
                
                buf_ptr <= 0;
				main_state <= UPDATE_STATUS;

		-- S: Size, C: Color (Hex), W: Width
			when UPDATE_STATUS =>
    			if lcd_busy = '0' then
        			case status_ptr is
            			when 0 => lcd_rs <= '0'; lcd_data <= x"C0"; -- Jump to Row 2
           				when 1 => lcd_rs <= '1'; lcd_data <= x"53"; -- 'S'
						when 2 => lcd_rs <= '1'; lcd_data <= x"3A"; -- ':'
            			when 3 => lcd_rs <= '1';
							if sketch_size = '1' then 
        						lcd_data <= x"31"; -- Show '1'
   							else 
        						lcd_data <= x"32"; -- Show '2'
    						end if;
            			when 4 => lcd_rs <= '1'; lcd_data <= x"20"; -- space
            			when 5 => lcd_rs <= '1'; lcd_data <= x"43"; -- 'C'
            			when 6 => lcd_rs <= '1'; lcd_data <= x"3A"; -- ':'
						when 7 => lcd_rs <= '1'; 
							if current_color(23 downto 20) = x"F" then 
								lcd_data <= x"46";
							else lcd_data <= x"30"; end if;
						when 8 => lcd_rs <= '1'; 
							if current_color(19 downto 16) = x"F" then 
								lcd_data <= x"46";
							else lcd_data <= x"30"; end if;
						when 9 => lcd_rs <= '1'; 
							if current_color(15 downto 12) = x"F" then 
								lcd_data <= x"46";
							else lcd_data <= x"30"; end if;
						when 10 => lcd_rs <= '1'; 
							if current_color(11 downto 8) = x"F" then 
								lcd_data <= x"46";
							else lcd_data <= x"30"; end if;
						when 11 => lcd_rs <= '1'; 
							if current_color(7 downto 4) = x"F" then 
								lcd_data <= x"46";
							else lcd_data <= x"30"; end if;
						when 12 => lcd_rs <= '1'; 
							if current_color(3 downto 0) = x"F" then 
								lcd_data <= x"46";
							else lcd_data <= x"30"; end if;
            			when 13 => lcd_rs <= '1'; lcd_data <= x"20"; -- space
            			when 14 => lcd_rs <= '1'; lcd_data <= x"57"; -- 'W'
						when 15 => lcd_rs <= '1'; lcd_data <= x"3A"; -- ':'
            			when 16 => lcd_rs <= '1'; lcd_data <= x"30" or ("000000" & pen_width); -- Width '1', '2', or '3'
           				when 17 => 
                			lcd_rs <= '0'; 
							lcd_data <= std_logic_vector(to_unsigned(128 + buf_ptr, 8)); -- Jump back to Row 1 for typing
                			main_state <= IDLE;
							status_ptr <= 0;
            			when others => null;
        			end case;
        			lcd_en <= '1';
        			status_ptr <= status_ptr + 1;
    			end if;

	    	when LCD_BS_STEP1 =>
                if lcd_busy = '0' then
                    lcd_rs <= '0'; lcd_data <= x"10"; -- Shift Left
                    lcd_en <= '1'; main_state <= LCD_BS_STEP2;
                end if;

       	 	when LCD_BS_STEP2 =>
                if lcd_busy = '0' then
                    lcd_rs <= '1'; lcd_data <= x"20"; -- Print Space
                    lcd_en <= '1'; main_state <= LCD_BS_STEP3;
                end if;

        	when LCD_BS_STEP3 =>
                if lcd_busy = '0' then
                    lcd_rs <= '0'; lcd_data <= x"10"; -- Shift Left again
                    lcd_en <= '1'; main_state <= IDLE;
                end if;

        	when others => main_state <= IDLE;
        end case;
    end if;
end process;


    -- ==========================================
    -- Port Maping
    -- ==========================================
    
    inst_Reset_Delay : entity work.Reset_Delay
        port map (
            iCLK    => iClk,
            oRESET  => Reset_o
        );        

-------------------------------------------------------------------------------------------------
    
    inst_Reset_btn : btn_debounce_toggle
        generic map ( CNTR_MAX => X"0FFF" )
        port map (
            BTN_I    => btn0,
            CLK      => iClk,
            BTN_O    => iReset,
            TOGGLE_O => open,
            PULSE_O  => open
        );

-------------------------------------------------------------------------------------------------
    
    inst_RotaryL : btn_debounce_toggle
        generic map ( CNTR_MAX => X"0FFF" )
        port map (
            BTN_I    => L,
            CLK      => iClk,
            BTN_O    => dbL,
            TOGGLE_O => open,
            PULSE_O  => open
        );

-------------------------------------------------------------------------------------------------
    
    inst_RotaryL_clk : btn_debounce_toggle
        generic map ( CNTR_MAX => X"0FFF" )
        port map (
            BTN_I    => L_CLK,
            CLK      => iClk,
            BTN_O    => dbL_CLK,
            TOGGLE_O => open,
            PULSE_O  => open
        );

-------------------------------------------------------------------------------------------------
    
    inst_RotaryR : btn_debounce_toggle
        generic map ( CNTR_MAX => X"0FFF" )
        port map (
            BTN_I    => R,
            CLK      => iClk,
            BTN_O    => dbR,
            TOGGLE_O => open,
            PULSE_O  => open
        );

-------------------------------------------------------------------------------------------------
    
    inst_RotaryR_clk : btn_debounce_toggle
        generic map ( CNTR_MAX => X"0FFF" )
        port map (
            BTN_I    => R_CLK,
            CLK      => iClk,
            BTN_O    => dbR_CLK,
            TOGGLE_O => open,
            PULSE_O  => open
        );
        
-------------------------------------------------------------------------------------------------

init_I2C_LCD : i2c_lcd_user_logic
    Generic map (
        CLK_FREQ    => 125_000_000
    )
	Port map (
		clk         => iClk,
		rst         => Reset_Master,
		
		-- LCD client interface
		rs          => lcd_rs, -- 0 for command register, 1 for data register
		data_in     => lcd_data, -- byte to send (can be a control word or ASCII)
		ena         => lcd_en,
		busy 		=> lcd_busy,
		sda			=> LCD_SDA,
		scl 		=> LCD_SCL
		
	);
	
-------------------------------------------------------------------------------------------------
	
inst_Rotary_EncoderL: RotaryEN_SM --Up, Down
  Port map(
    reset    => Reset_Master,
	clk      => iClk,
	A        => dbL,
	B        => dbL_CLK,
	count_en => count_enL,
	count_up => count_upL
  );

-------------------------------------------------------------------------------------------------

inst_Rotary_EncoderR: RotaryEN_SM --Left, Right
  Port map(
    reset    => Reset_Master,
	clk      => iClk,
	A        => dbR,
	B        => dbR_CLK,
	count_en => count_enR,
	count_up => count_upR
  );

-------------------------------------------------------------------------------------------------

inst_ps2_keyboard_to_ascii : ps2_keyboard_to_ascii
    GENERIC map(
      clk_freq                  => 125_000_000, --system clock frequency in Hz
      ps2_debounce_counter_size => 9)            --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
        port map (
            clk          => iClk,
            ps2_clk      => PS2_Clk,
            ps2_data     => PS2_Data,
            ascii_new    => ascii_new,
            ascii_code   => ascii_code
        );
   
 -------------------------------------------------------------------------------------------------
 
 inst_CLK_div_Uart : entity work.clock_div
  generic map(
    clock     => 125,  --The internal board clock rate in MHz
    Baud_rate => 9600, --The baud rate you want to hit
    Bytes     => 16    --The number of byts you want to send
  )
  Port map(
    iClk        => iClk,
    reset       => Reset_Master,
    oTX_Clk_Div => TX_Clk,
    oRX_Clk_Div => RX_Clk
  );

-------------------------------------------------------------------------------------------------

inst_uart : entity work.uart
        port map (
            reset           =>   Reset_Master,
            txclk           =>   TX_Clk,
            ld_tx_data      =>   ld_tx_pulse,
            tx_data         =>   tx_data,--ascii_code8,
            tx_enable       =>   '1',
            tx_out          =>   UART_TX,    --The Pin to TX
            tx_empty        =>   tx_empty,
            
            rxclk           =>   RX_Clk,
            uld_rx_data     =>   rx_full,
            rx_data         =>   rx_data,
            rx_enable       =>   '1',
            rx_in           =>   UART_RX,
            rx_empty        =>   rx_empty    
        );

end Structural;
