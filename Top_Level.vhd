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
	signal tx_empty          : std_logic;
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



function ascii_to_hex(char : std_logic_vector(7 downto 0)) return std_logic_vector is
begin
    if char >= x"30" and char <= x"39" then return char(3 downto 0); -- 0-9
    elsif char >= x"41" and char <= x"46" then return std_logic_vector(unsigned(char(3 downto 0)) + 9); -- A-F
    elsif char >= x"61" and char <= x"66" then return std_logic_vector(unsigned(char(3 downto 0)) + 9); -- a-f
    else return x"0"; end if;
end function;

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
    variable pulse_cnt : integer range 0 to 255 := 0;
begin
    if Reset_Master = '1' then
        uart_fsm <= UART_IDLE;
        ld_tx_pulse <= '0';
        pulse_cnt := 0;
    elsif rising_edge(iClk) then
        ld_tx_pulse <= '0'; -- Default

        case uart_fsm is
            when UART_IDLE =>
                if uart_trigger = '1' and tx_empty = '1' then
                    tx_data  <= uart_val_to_send;
                    uart_fsm <= UART_LOAD;
                end if;

            when UART_LOAD =>
                ld_tx_pulse <= '1'; -- Hold high for UART to see
                if pulse_cnt < 50 then 
                    pulse_cnt := pulse_cnt + 1;
                else
                    pulse_cnt := 0;
                    uart_fsm <= UART_WAIT_BUSY;
                end if;

            when UART_WAIT_BUSY =>
                if tx_empty = '0' then -- UART has started sending
                    uart_fsm <= UART_WAIT_EMPTY;
                end if;

            when UART_WAIT_EMPTY =>
                if tx_empty = '1' then -- UART is finished
                    uart_fsm <= UART_IDLE;
                end if;
        end case;
    end if;
end process;

	
-- ==========================================
-- 2. LCD Manager: Keyboard -> LCD
-- ==========================================
LCD_MANAGER : process(iClk, Reset_Master)
begin
    if Reset_Master = '1' then
        lcd_fsm <= LCD_IDLE;
        lcd_en <= '0';
    elsif rising_edge(iClk) then
        lcd_en <= '0'; -- Pulse only

        case lcd_fsm is
            when LCD_IDLE =>
                if lcd_print_req = '1' and lcd_busy = '0' then
                    lcd_data <= char_to_lcd;
                    lcd_rs <= '1'; -- Data Mode
                    lcd_en <= '1';
                    lcd_fsm <= LCD_WAIT;
                elsif lcd_bs_req = '1' and lcd_busy = '0' then
                    lcd_data <= x"10"; -- Shift Cursor Left command
                    lcd_rs <= '0'; -- Command Mode
                    lcd_en <= '1';
                    lcd_fsm <= LCD_BS_STEP2;
                end if;

            when LCD_BS_STEP2 => -- Print space to "erase"
                if lcd_busy = '0' then
                    lcd_data <= x"20"; -- Space char
                    lcd_rs <= '1';
                    lcd_en <= '1';
                    lcd_fsm <= LCD_BS_STEP3;
                end if;

            when LCD_BS_STEP3 => -- Shift Left again to reset cursor
                if lcd_busy = '0' then
                    lcd_data <= x"10";
                    lcd_rs <= '0';
                    lcd_en <= '1';
                    lcd_fsm <= LCD_WAIT;
                end if;

            when LCD_WAIT =>
                if lcd_busy = '0' then lcd_fsm <= LCD_IDLE; end if;
        end case;
    end if;
end process;

-- ==========================================
-- 3. System Manager:
-- ==========================================
SYSTEM_MANAGER : process(iClk, Reset_Master)
begin
    if Reset_Master = '1' then
        main_state <= BOOT;
        buf_ptr <= 0;
    elsif rising_edge(iClk) then
        uart_trigger <= '0';
        lcd_print_req <= '0';
        lcd_bs_req <= '0';

        case main_state is
            when BOOT =>
                -- Logic to send "Hardware Ready" string
                main_state <= RUN;

            when RUN =>
                -- PRIORITY 1: Rotary Encoders (Instant UART)
                if (count_enR = '1' or count_enL = '1') and uart_fsm = UART_IDLE then
                    uart_trigger <= '1';
                    if count_enR = '1' then
                        uart_val_to_send <= x"52" when count_upR = '1' else x"4C"; -- R/L
                    elsif count_enL = '1' then
                        uart_val_to_send <= x"55" when count_upL = '1' else x"44"; -- U/D
                    end if;

                -- PRIORITY 2: Keyboard Input
                elsif ascii_new = '1' then
                    if ascii_code = x"0D" then -- ENTER: Send Buffer to PC
                        main_state <= SEND_BUFFER;
                        buf_idx <= 0;
                    elsif ascii_code = x"08" then -- BACKSPACE
                        if buf_ptr > 0 then
                            buf_ptr <= buf_ptr - 1;
                            lcd_bs_req <= '1';
                        end if;
                    else -- Regular Char: Echo to LCD & Save
                        char_to_lcd <= '0' & ascii_code;
                        lcd_print_req <= '1';
                        cmd_buffer(buf_ptr) <= '0' & ascii_code;
                        if buf_ptr < 15 then buf_ptr <= buf_ptr + 1; end if;
                    end if;
                end if;

            when SEND_BUFFER =>
                -- Loop through cmd_buffer and trigger UART for each byte
		if cmd_buffer(0) = x"23" and buf_ptr >= 7 then
        		-- Parse #RRGGBB (indices 1-2 for Red, 3-4 for Green, 5-6 for Blue)
        		current_color(23 downto 16) <= ascii_to_hex(cmd_buffer(1)) & ascii_to_hex(cmd_buffer(2));
        		current_color(15 downto 8)  <= ascii_to_hex(cmd_buffer(3)) & ascii_to_hex(cmd_buffer(4));
        		current_color(7 downto 0)   <= ascii_to_hex(cmd_buffer(5)) & ascii_to_hex(cmd_buffer(6));
    		end if;
                if uart_fsm = UART_IDLE then
                    uart_val_to_send <= cmd_buffer(buf_idx);
                    uart_trigger <= '1';
                    if buf_idx < buf_ptr - 1 then
                        buf_idx <= buf_idx + 1;
                    else
                        buf_ptr <= 0; -- Clear buffer for next command
                        main_state <= RUN;
                    end if;
                end if;
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
