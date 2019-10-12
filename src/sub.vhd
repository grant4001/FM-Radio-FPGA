library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity sub is
port( 
    clk : in std_logic; 
    rst : in std_logic;

    sub_in1_dout : in std_logic_vector (31 downto 0);
    sub_in1_rd_en : out std_logic;
    sub_in1_empty : in std_logic;

    sub_in2_dout : in std_logic_vector (31 downto 0);
    sub_in2_rd_en : out std_logic;
    sub_in2_empty : in std_logic;

    FOUT_wr_en : out std_logic;
    FOUT_din : out std_logic_vector (31 downto 0);
    FOUT_full : in std_logic
);

end entity sub;

architecture behavior of sub is

    type state_type is (s0);
    signal state, next_state : state_type := s0;

begin

    reg_proc : process (clk, rst)
    begin
        if rst = '1' then
            state <= s0;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    comb_proc : process ( state, sub_in1_empty, sub_in2_empty, FOUT_full, sub_in1_dout, sub_in2_dout ) 
    begin 
        next_state <= state;

        sub_in1_rd_en <= '0';
        sub_in2_rd_en <= '0';
        FOUT_wr_en <= '0';
        FOUT_din <= (others => '0');

        case (state) is 
            when s0 => 
                if (sub_in1_empty = '0' and sub_in2_empty = '0' and FOUT_full = '0') then

                    sub_in1_rd_en <= '1';
                    sub_in2_rd_en <= '1';
                    
                    FOUT_wr_en <= '1';
                    FOUT_din <= std_logic_vector( resize( signed(sub_in1_dout) - signed(sub_in2_dout) , 32) );
                    
                end if;

        end case;

    end process;

end architecture;