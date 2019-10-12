library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity comparator is
port(
	DINL : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
	append_bit : in std_logic;
	DINR : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);

	DOUT : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
	isGreaterEq : out std_logic
);
end entity comparator;

architecture behavior of comparator is

	signal DINL_int, DINR_int, DOUT_int : integer;
	signal DINL_append : std_logic_vector (DIVISOR_WIDTH downto 0);

begin

	DINL_append <= DINL & append_bit;
	
	--Convert std_logic_vector to integer
	DINL_int <= (to_integer(signed(DINL_append)));
	DINR_int <= (to_integer(signed(DINR)));

	--Perform comparator operation
	DOUT_int <= DINL_int - DINR_int when DINL_int >= DINR_int
		else DINL_int;
	
	--Write subtraction output
	DOUT <= std_logic_vector(to_signed(DOUT_int, DIVISOR_WIDTH));
	
	--write comparison output
	isGreaterEq <= '1' when DINL_int >= DINR_int 
		else '0';

---------------------------------------------------------------

--	signal DINL_int, DINR_int, DOUT_int : integer;
--	signal DINL_append : std_logic_vector (DIVISOR_WIDTH downto 0);
--
--begin

--	DINL_append <= DINL & append_bit;
	
	--Convert std_logic_vector to integer
--	DINL_int <= (to_integer(unsigned(DINL_append)));
--	DINR_int <= (to_integer(unsigned(DINR)));

	--Perform comparator operation
--	DOUT_int <= DINL_int - DINR_int when DINL_int >= DINR_int
--		else DINL_int;
	
	--Write subtraction output
--	DOUT <= std_logic_vector(to_unsigned(DOUT_int, DIVISOR_WIDTH));
	
	--write comparison output
--	isGreaterEq <= '1' when DINL_int >= DINR_int 
--		else '0';
	
end architecture behavior;