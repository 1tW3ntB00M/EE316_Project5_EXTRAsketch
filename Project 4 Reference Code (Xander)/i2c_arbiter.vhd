----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2026 07:47:26 PM
-- Design Name: 
-- Module Name: i2c_arbiter - Behavioral
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

use work.i2c_utilities.all;

entity i2c_arbiter is
    Generic (
        constant CLK_FREQ : integer := 125_000_000;
        constant BUS_FREQ : integer := 100_000
    );
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        
        -- individual connections to drivers
        req : in STD_LOGIC_VECTOR(NUM_DRIVERS-1 downto 0);
        grant : out STD_LOGIC_VECTOR(NUM_DRIVERS-1 downto 0);
        addr : in driver_addr_array_t;
        cmd_len : in driver_len_array_t; -- bytes in this transaction, in total
        cmds : in driver_cmd_array_t;
        
        -- read data outputs
        read_data : out driver_read_array_t;
        done : out STD_LOGIC_VECTOR(NUM_DRIVERS-1 downto 0);
        
        -- I2C master hardware connections
        sda : inout STD_LOGIC;
        scl : inout STD_LOGIC
    );
end i2c_arbiter;

architecture Behavioral of i2c_arbiter is

    -- component declarations
    component i2c_master is
        generic (
            input_clk : integer := 100_000_000; -- input clock speed from user logic in Hz
            bus_clk   : integer := 400_000 -- speed the i2c bus (scl) will run at in Hz
        );
        port (
            clk       : in     std_logic;                    	--system clock
            reset_n   : in     std_logic;                   	--active low reset
            ena       : in     std_logic;                    	--latch in command
            addr      : in     std_logic_vector(6 downto 0); 	--address of target slave
            rw        : in     std_logic;                    	--'0' is write, '1' is read
            data_wr   : in     std_logic_vector(7 downto 0); 	--data to write to slave
            busy      : out    std_logic;                    	--indicates transaction in progress
            data_rd   : out    std_logic_vector(7 downto 0); 	--data read from slave
            ack_error : buffer std_logic;                    	--flag if improper acknowledge from slave
            sda       : inout  std_logic;                    	--serial data output of i2c bus
            scl       : inout  std_logic								--serial clock output of i2c bus
        );
    end component;
    
    -- signals
    signal rst_n : std_logic;
    signal busy_cnt : integer range 0 to MAX_CMDS := 0;
    
    -- master's control signals
    signal i2c_ena     : std_logic := '0';
    signal i2c_addr    : std_logic_vector(6 downto 0) := (others => '0');
    signal i2c_rw      : std_logic := '0';
    signal i2c_data_wr : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_data_rd : std_logic_vector(7 downto 0);
    signal i2c_busy    : std_logic;
    signal busy_prev   : std_logic := '0';
    
    -- active state should be tracked by driver
    type state_t is (IDLE, ACTIVE);
    signal state : state_t := IDLE;
    signal active_driver : integer range 0 to NUM_DRIVERS-1 := 0; -- the driver currently using the master

begin
    -- Instantiations
	Inst_i2c_master : i2c_master
		generic map (
			input_clk => CLK_FREQ,-- input clock speed from user logic in Hz
			bus_clk => BUS_FREQ 		-- speed the i2c bus (scl) will run at in Hz.
		)
		port map (
			clk => clk, 				--system clock
			reset_n => rst_n, 		--active low reset
			ena => i2c_ena, 				--latch in command
			addr => i2c_addr, 		--address of target slave
			rw => i2c_rw, 					--'0' is write, '1' is read
			data_wr => i2c_data_wr, 		--data to write to slave
			busy => i2c_busy, 				--indicates transaction in progress
			data_rd => i2c_data_rd, 		--data read from slave
			ack_error => open, --flag if improper acknowledge from slave
			sda => sda, 				--serial data output of i2c bus
			scl => scl 					--serial clock output of i2c bus
		);
		
    -- Always assignments
    rst_n <= not rst;
    --data_rd <= i2c_data_rd; -- read data is broadcast to everyone, only driver notified by done cares tho

    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE; -- hold in idle
            i2c_ena <= '0'; -- disable master (it will also already be reset)
            grant <= (others => '0'); -- don't give anyone the bus
            done <= (others => '0'); -- no transfers have occurred
            
        elsif rising_edge(clk) then
            busy_prev <= i2c_busy; -- to track number of transfers with edge detection
            done <= (others => '0'); -- done pulses should go to zero of not otherwise asserted

            case state is
                when IDLE =>
                    i2c_ena <= '0'; -- don't start master
                    grant <= (others => '0'); -- remove any granted bus control
                    busy_cnt <= 0; -- reset for next transaction
                    
                    for i in 0 to NUM_DRIVERS-1 loop -- for all the drivers, checking lowest first
                        if req(i) = '1' and cmd_len(i) > 0 then -- if there is a request
                            grant(i) <= '1'; -- we can immediately grant it because we're idle
                            active_driver <= i; -- store that this driver won
                            
                            -- patch this driver in to the master
                            i2c_addr <= addr(i);
                            i2c_rw <= cmds(i)(0).rw;
                            i2c_data_wr <= cmds(i)(0).data;
                            
                            i2c_ena <= '1'; -- start transaction on master
                            state <= ACTIVE; -- transition to active (transferring) state
                            exit; -- end loop when request found
                        end if;
                    end loop;

                when ACTIVE =>
                    if busy_prev = '0' and i2c_busy = '1' then -- if rising edge of busy
                        busy_cnt <= busy_cnt + 1; -- count # of busy edges in this transaction
                    end if;
                    
                    -- therefore busy_cnt is tracking which cmd we're on
                    if busy_cnt = cmd_len(active_driver) then -- and we should stop when we reach the total length
                        i2c_ena <= '0'; -- deassert enable to stop transaction after last command
                    elsif busy_cnt > 0 and busy_cnt < cmd_len(active_driver) then -- otherwise we're in the middle of a transaction
                        -- load next command based on index from busy_cnt
                        i2c_rw <= cmds(active_driver)(busy_cnt).rw;
                        i2c_data_wr <= cmds(active_driver)(busy_cnt).data;
                    end if;

                    -- capture read data when busy drops low
                    if busy_prev = '1' and i2c_busy = '0' then -- if falling edge of busy
                        
                        if busy_cnt > 0 then
                            read_data(active_driver)(busy_cnt - 1) <= i2c_data_rd; -- get data from command that just finished, if applicable
                        end if;
                        
                        if i2c_ena = '0' then -- if ena goes low the transaction is ready to stop
                            done(active_driver) <= '1'; -- let the driver know the transaction is done
                            grant(active_driver) <= '0'; -- cancel the grant
                            state <= IDLE; -- transaction complete, go wait or handle another
                        end if;
                    end if;        

            end case;
        end if;
    end process;
end Behavioral;
