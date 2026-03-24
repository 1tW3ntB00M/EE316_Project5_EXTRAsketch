-- I2C LCD display user logic
-- Sigmond Kukla

-- Adapted from Sig's 7-segment I2C user logic
-- and Scott Larson's I2C master examples
-- from https://forum.digikey.com/t/i2c-master-vhdl/12797

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.i2c_utilities.all;

entity i2c_lcd_user_logic is
    Generic (
        CLK_FREQ : integer := 125_000_000
    );
	Port (
		clk : in STD_LOGIC;
		rst : in std_logic;
		
		-- LCD client interface
		rs : in std_logic; -- 0 for command register, 1 for data register
		data : in std_logic_vector(7 downto 0); -- byte to send (can be a control word or ASCII)
		ena : in std_logic;
		busy : out std_logic := '1';
		
		-- I2C arbiter control
		arb_req : out std_logic;
		arb_grant : in  std_logic;
		arb_addr : out std_logic_vector(6 downto 0);
		arb_cmd_len : out integer range 0 to MAX_CMDS;
		arb_cmds : out i2c_cmd_array_t;
		arb_done : in  std_logic
	);
end i2c_lcd_user_logic;

architecture Behavioral of i2c_lcd_user_logic is

    constant LCD_I2C_ADDR : std_logic_vector(6 downto 0) := "0100111";--"0100000";

	-- init sequence format
	type init_cmd_t is record
		data : std_logic_vector(7 downto 0);
		dl : std_logic; -- data length, 0 for 4-bit, 1 for 8-bit. if 4-bit, only a nibble is sent. if 8-bit, whole sent as 2 nibbles.
	end record;
	
	constant INIT_LEN : integer := 9;
	type init_seq_t is array (0 to INIT_LEN-1) of init_cmd_t;
	constant INIT_SEQ : init_seq_t := (
		(x"30", '0'), -- 0x3 (when dl=0 i.e. single nibble, only D7..D4 are used)
		(x"30", '0'), -- 0x3
		(x"30", '0'), -- 0x3
		(x"20", '0'), -- 0x2 (switch to 4-bit interface)
		(x"28", '1'), -- 0x28 (Function set: 4-bit, 2 lines, 5x8)
		(x"08", '1'), -- 0x08 (Display on/off set: off)
		(x"01", '1'), -- 0x01 (Clear display)
		(x"06", '1'), -- 0x06 (Entry mode set)
		(x"0C", '1')  -- 0x0C (Display on/off set: on)
	);
	signal init_idx : integer range 0 to INIT_LEN := 0;

	-- FSM States
	type state_t is (
	    POR_DELAY,
		INIT_LOAD,
		CLIENT_LOAD,
		TRANSMIT_REQ, -- request arbiter
		TRANSMIT_WAIT, -- wait for arbiter done
		DELAY, -- after transmit delay
		IDLE -- after command fully finished
	);
	signal state : state_t := DELAY;
	
	-- Timers
	constant DELAY_TIM_MAX : integer := (CLK_FREQ / 1000) * 40; -- for now assume longest delay needed to be 40 ms
	signal delay_tim_end : integer range 0 to DELAY_TIM_MAX;
	signal delay_tim : integer range 0 to DELAY_TIM_MAX := 0;
	
	signal rst_n : std_logic;
	signal init_done : std_logic := '0';
	
	signal data_buf : std_logic_vector(7 downto 0);
	signal rs_buf : std_logic;

begin
	-- no instantiations needed
	-- Always assignments
	rst_n <= not rst;
	
	-- combinatorial busy signal should update immediately
	-- if state == IDLE and ena == 0 then not busy essentially
	busy <= '1' when (state /= IDLE) or (ena = '1') else '0';
	
	-- Processes
	process (clk, rst)
	begin
        if rst = '1' then
          -- go to power on delay, setup for 40 ms
		  state <= POR_DELAY;			
		  delay_tim_end <= 40 * (CLK_FREQ / 1000);
		  delay_tim <= 0;
		
		  -- reset signals
		  arb_req <= '0';
		  -- busy <= '1';
		  init_idx <= 0; -- signed integer, should roll around to 0 when incremented in first delay
		  arb_addr <= LCD_I2C_ADDR;
		  init_done <= '0';
			
		elsif rising_edge(clk) then
			case state is
			    when POR_DELAY =>
					if delay_tim < delay_tim_end then 
                        delay_tim <= delay_tim + 1;
                    else
                        delay_tim <= 0;
                        state <= INIT_LOAD;
                    end if;
			
				when INIT_LOAD => 
                    -- format data for I2C IO expander before sending to arbiter
                    -- D7 D6 D5 D4 BL=1 EN=0-1-0 RW=0 RS=0
                    
                    -- high nibble is always sent whether in 4 or 8 bit mode
                    arb_cmds(0).rw <= '0'; 
                    arb_cmds(0).data <= INIT_SEQ(init_idx).data(7 downto 4) & "1000"; -- BL=1 EN=0
                    arb_cmds(1).rw <= '0'; 
                    arb_cmds(1).data <= INIT_SEQ(init_idx).data(7 downto 4) & "1100"; -- BL=1 EN=1
                    arb_cmds(2).rw <= '0'; 
                    arb_cmds(2).data <= INIT_SEQ(init_idx).data(7 downto 4) & "1000"; -- BL=1 EN=0
                    
                    if INIT_SEQ(init_idx).dl = '0' then -- if 4-bit init command
                        arb_cmd_len <= 3; -- only send high nibble, ignore lower
                    else -- 8-bit init command
                        -- send high then low nibble
                        arb_cmds(3).rw <= '0'; 
                        arb_cmds(3).data <= INIT_SEQ(init_idx).data(3 downto 0) & "1000"; -- BL=1 EN=0
                        arb_cmds(4).rw <= '0'; 
                        arb_cmds(4).data <= INIT_SEQ(init_idx).data(3 downto 0) & "1100"; -- BL=1 EN=1
                        arb_cmds(5).rw <= '0'; 
                        arb_cmds(5).data <= INIT_SEQ(init_idx).data(3 downto 0) & "1000"; -- BL=1 EN=0
                        arb_cmd_len <= 6;
                    end if;
                    
                    state <= TRANSMIT_REQ;

				when CLIENT_LOAD => -- load command from client
                    -- D7 D6 D5 D4 BL=1 EN=0-1-0 RW=0 RS=as requested
                    
                    -- high nibble
                    arb_cmds(0).rw <= '0'; 
                    arb_cmds(0).data <= data_buf(7 downto 4) & "100" & rs_buf; -- EN=0
                    arb_cmds(1).rw <= '0'; 
                    arb_cmds(1).data <= data_buf(7 downto 4) & "110" & rs_buf; -- EN=1
                    arb_cmds(2).rw <= '0'; 
                    arb_cmds(2).data <= data_buf(7 downto 4) & "100" & rs_buf; -- EN=0
                    
                    -- low nibble
                    arb_cmds(3).rw <= '0'; 
                    arb_cmds(3).data <= data_buf(3 downto 0) & "100" & rs_buf; -- EN=0
                    arb_cmds(4).rw <= '0'; 
                    arb_cmds(4).data <= data_buf(3 downto 0) & "110" & rs_buf; -- EN=1
                    arb_cmds(5).rw <= '0'; 
                    arb_cmds(5).data <= data_buf(3 downto 0) & "100" & rs_buf; -- EN=0
                    
                    arb_cmd_len <= 6;
                    state <= TRANSMIT_REQ;

				when TRANSMIT_REQ => -- arbiter start sequence
					arb_req <= '1'; -- request arbiter
					if arb_grant = '1' then -- wait until granted
						state <= TRANSMIT_WAIT;
					end if;

				when TRANSMIT_WAIT => -- wait for arbiter to finish
					arb_req <= '0'; -- its granted so we're good now
					if arb_done = '1' then -- wait until transaction done
						
						if init_done = '1' then -- was from client
						  delay_tim_end <= 2 * (CLK_FREQ/1000);
						else -- was init, needs longer delay
						  delay_tim_end <= 5 * (CLK_FREQ/1000);
						end if;
                        
                        state <= DELAY;
					end if;

				when DELAY =>
					if delay_tim < delay_tim_end then 
                        delay_tim <= delay_tim + 1;
                    else
                        delay_tim <= 0;
                        
                        -- decide where to go
                        if init_done = '1' then -- if init done, we should be ready to accept client commands
                          state <= IDLE;
                        else -- init not done
                          if init_idx < (INIT_LEN - 1) then -- if not on the last init command
                            -- go to next init step
                            init_idx <= init_idx + 1;
                            state <= INIT_LOAD;
                          else -- just finished last init command
                              init_done <= '1';
                              state <= IDLE;
                          end if;
                        end if;
                    end if;

				when IDLE =>
					-- busy <= '0';
					if ena = '1' then -- if command from clients
						-- busy <= '1';
						data_buf <= data;
						rs_buf <= rs;
						state <= CLIENT_LOAD;
					end if;
					
			end case;
		end if;
	end process;
end Behavioral;
