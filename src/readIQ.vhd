library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use IEEE.math_real.all;
use IEEE.math_complex.all;
use work.constants.all;
 
entity readIQ is
port(
    signal clk : in std_logic;
    signal rst : in std_logic;
 
    signal FIN_dout: in std_logic_vector(7 downto 0);
    signal FIN_rd_en: out std_logic;
    signal FIN_empty: in std_logic;
 
    signal FOUT_i_wr_en: out std_logic;
    signal FOUT_i_din : out std_logic_vector(31 downto 0);
    signal FOUT_i_full : in std_logic;
    
    signal FOUT_q_wr_en: out std_logic;
    signal FOUT_q_din : out std_logic_vector(31 downto 0);
    signal FOUT_q_full : in std_logic
);
end entity;
 
architecture behavior of readIQ is

    type state_type is (s0, s1);

    signal state, next_state: state_type := s0;
    signal j, j_c: std_logic_vector (7 downto 0);
    signal my_i, my_i_c : std_logic_vector ( 15 downto 0 ) := (others => '0');
    signal my_q, my_q_c : std_logic_vector ( 15 downto 0 ) := (others => '0');
 
begin
 
    reg_proc : process (clk, rst)
    begin
        if rst = '1' then
            state <= s0;
            j <= (others => '0');
            my_i <= (others => '0');
            my_q <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;
            j <= j_c;
            my_i <= my_i_c;
            my_q <= my_q_c;
        end if;
    end process;

    comb_proc : process (FIN_dout, FIN_empty, FOUT_i_full, FOUT_q_full, state, j, my_i, my_q)
 
    begin

        next_state <= state;
        j_c <= j;
        my_i_c <= my_i;
        my_q_c <= my_q;
        
        FOUT_i_wr_en <= '0';
        FOUT_q_wr_en <= '0';
        FOUT_i_din <= (others=>'0');
        FOUT_q_din <= (others=>'0');
        FIN_rd_en <= '0';
 
        case ( state ) is

            when s0 =>
            
                if (FIN_empty = '0') then
                    FIN_rd_en <= '1';

                    if (to_integer(signed(j)) = 0) then
                        my_i_c(7 downto 0) <= FIN_dout;
                        j_c <= std_logic_vector(signed(j) + to_signed(1, 8));
                    elsif (to_integer(signed(j)) = 1) then
                        my_i_c(15 downto 8) <= FIN_dout;
                        j_c <= std_logic_vector(signed(j) + to_signed(1, 8));
                    elsif (to_integer(signed(j)) = 2) then
                        my_q_c(7 downto 0) <= FIN_dout;
                        j_c <= std_logic_vector(signed(j) + to_signed(1, 8));
                    elsif (to_integer(signed(j)) = 3) then
                        my_q_c(15 downto 8) <= FIN_dout;
                        j_c <= (others => '0');
                        next_state <= s1;
                    end if;
                end if;
    
            when s1 =>

                if (FOUT_q_full = '0' and FOUT_i_full = '0') then    
                    FOUT_q_wr_en <= '1';
                    FOUT_i_wr_en <= '1';

                    FOUT_i_din <= QUANTIZE( signed(my_i) );
                    FOUT_q_din <= QUANTIZE( signed(my_q) );

                    my_i_c <= (others => '0');
                    my_q_c <= (others => '0');
    
                    next_state <= s0;
                end if;

        end case;

    end process;
    
end architecture behavior;