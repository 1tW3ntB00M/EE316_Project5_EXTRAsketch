----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2026 07:47:26 PM
-- Design Name: 
-- Module Name: i2c_utilities - Behavioral
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

package i2c_utilities is
    constant NUM_DRIVERS : integer := 2; -- number of drivers sharing this bus 
    constant MAX_CMDS : integer := 8; -- max bytes (read and write combined) per transaction
    
    type i2c_cmd_t is record -- represents one byte over I2C
        rw   : std_logic; -- 0 for write, 1 for read, can change throughout transaction w/ repeated start
        data : std_logic_vector(7 downto 0); -- data to write, can be left alone for read bytes
    end record;
    
    type i2c_cmd_array_t is array (0 to MAX_CMDS-1) of i2c_cmd_t; -- one transaction is an array of commands
    
    -- Arbiter inputs
    type driver_cmd_array_t is array (0 to NUM_DRIVERS-1) of i2c_cmd_array_t;
    type driver_len_array_t is array (0 to NUM_DRIVERS-1) of integer range 0 to MAX_CMDS;
    type driver_addr_array_t is array (0 to NUM_DRIVERS-1) of std_logic_vector(6 downto 0);
    
    -- Read data outputs
    type i2c_read_array_t is array (0 to MAX_CMDS-1) of std_logic_vector(7 downto 0);
    type driver_read_array_t is array (0 to NUM_DRIVERS-1) of i2c_read_array_t;
end package i2c_utilities;
