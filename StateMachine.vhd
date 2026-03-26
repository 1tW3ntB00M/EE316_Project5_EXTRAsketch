library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Required for numeric operations

entity StateMachine is
	PORT (
		reset: IN std_logic;
		clk: IN std_logic;
		A: IN std_logic;
		B: IN std_logic;
		count_in: IN std_logic_vector(4 downto 0); -- Corrected input
		max_cars: OUT std_logic; -- Corrected output
		min_cars: OUT std_logic; -- Corrected output
		count_en : OUT std_logic;
		count_up : OUT std_logic;
		full_lot: OUT std_logic
	);
end StateMachine;

architecture Behavioral of StateMachine is

	type State_type is (INIT, L1, L2, L3, SUB, R1, R2, R3, ADD);
	signal CS : state_type; -- current state
	signal AB : std_logic_vector (1 downto 0);

begin

	AB <= A & B;

	sync : process (clk, reset)
	begin
		if (reset = '1') then
			CS <= INIT;
		elsif rising_edge (clk) then
			case CS is
				when INIT =>
					if AB = "10" then
						CS <= L1;
					elsif AB = "01" then
						CS <= R1;
					else
						CS <= INIT; -- Stay in INIT if no change
					end if;
				when L1 =>
					if AB = "00" then
						CS <= L2;
					elsif AB = "11" then
						CS <= INIT;
					else
						CS <= L1; -- Stay in L1
					end if;
				when L2 =>
					if AB = "01" then
						CS <= L3;
					elsif AB = "10" then
						CS <= L1;
					else
						CS <= L2; -- Stay in L2
					end if;
				when L3 =>
					if AB = "11" then
						CS <= SUB;
					elsif AB = "00" then
						CS <= L2;
					else
						CS <= L3; -- Stay in L3
					end if;
				when SUB =>
					CS <= INIT;

				when R1 =>
					if AB = "00" then
						CS <= R2;
					elsif AB = "11" then
						CS <= INIT;
					else
						CS <= R1; -- Stay in R1
					end if;
				when R2 =>
					if AB = "10" then
						CS <= R3;
					elsif AB = "01" then
						CS <= R1;
					else
						CS <= R2; -- Stay in R2
					end if;
				when R3 =>
					if AB = "11" then
						CS <= ADD;
					elsif AB = "00" then
						CS <= R2;
					else
						CS <= R3; -- Stay in R3
					end if;
				when ADD =>
					CS <= INIT;
			end case;
		end if;
	end process;

	-- Assign outputs based on the current state (Moore-style FSM)
	output_logic : process(CS, count_in)
	begin
		-- Default values for safety
		count_en <= '0';
		count_up <= '0';
		full_lot <= '0';
		max_cars <= '0';
		min_cars <= '0';

		case CS is
			when INIT =>
				full_lot <= '0';
				count_en <= '0';
				count_up <= '0';
			when SUB =>
				if unsigned(count_in) > 0 then
					count_en <= '1';
					count_up <= '0';
				end if;
			when ADD =>
				if unsigned(count_in) < 25 then
					count_en <= '1';
					count_up <= '1';
				end if;
			when others =>
				null;
		end case;

		-- Logic to set max/min car flags for the counter
		if unsigned(count_in) = 25 then
			full_lot <= '1';
			max_cars <= '1';
		else
			full_lot <= '0';
			max_cars <= '0';
		end if;
		
		if unsigned(count_in) = 0 then
			min_cars <= '1';
		else
			min_cars <= '0';
		end if;

	end process;

end Behavioral;
