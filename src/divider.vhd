library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity divider is
port(
	start : in std_logic;
	dividend : in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	divisor : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);

	quotient : out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
	remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
	overflow : out std_logic
);
end entity divider;

architecture behavior of divider is

	component comparator is
	port(
		DINL : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
		append_bit : in std_logic;
		DINR : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
		DOUT : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
		isGreaterEq : out std_logic
	);
	end component comparator;
	
	type MyArray is array (DIVIDEND_WIDTH - 1 downto 0) of std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
	signal DOUT_array : MyArray;
	
	signal dividend_new : std_logic_vector (DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto 0); 
	signal isGreaterEq_array : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);

	begin						
		dividend_new <= (DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto dividend'length => '0') & dividend;
		
		comparator_gen_loop : for jj in 0 to DIVIDEND_WIDTH - 1 generate begin
			first_element: if jj = 0 generate begin 
				my_comparator : comparator
				port map(
					dividend_new(DIVIDEND_WIDTH + DIVISOR_WIDTH - 1 downto DIVIDEND_WIDTH), 
					dividend(DIVIDEND_WIDTH - 1),
					divisor,
					DOUT_array(jj),
					isGreaterEq_array(DIVIDEND_WIDTH - jj - 1)
				);
			end generate;
			
			sec_element: if jj > 0 generate begin
				my_comparators_2 : comparator
				port map(
					DOUT_array(jj - 1), 
					dividend(DIVIDEND_WIDTH - jj - 1),
					divisor,
					DOUT_array(jj),
					isGreaterEq_array(DIVIDEND_WIDTH - jj - 1)
				);
			end generate;
		end generate;
				
	behavior_proc : process (start, dividend, divisor, isGreaterEq_array, DOUT_array) is
	begin
	if (rising_edge(start)) then
		quotient <= isGreaterEq_array;	
		remainder <= DOUT_array(DIVIDEND_WIDTH - 1);
		if to_integer(signed(divisor)) = 0 then
			overflow <= '1';	
		else overflow <= '0';
		end if;
		
	end if;
	end process;
		
end architecture behavior;