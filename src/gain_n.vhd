library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity gain_n is
port( 
    clk : in std_logic; 
    rst : in std_logic;

    FIN_dout : in std_logic_vector (31 downto 0);
    FIN_rd_en : out std_logic;
    FIN_empty : in std_logic;

    FOUT_wr_en : out std_logic;
    FOUT_din : out std_logic_vector (31 downto 0);
    FOUT_full : in std_logic
);

end entity gain_n;

architecture behavior of gain_n is

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

    comb_proc : process (FIN_empty, FIN_dout, FOUT_full, state)
    begin 

        next_state <= state;
        FIN_rd_en <= '0';
        FOUT_wr_en <= '0';
        FOUT_din <= (others => '0');

        case (state) is 
            when s0 => 
                if (FIN_empty = '0' and FOUT_full = '0') then
                    FIN_rd_en <= '1';
                    FOUT_wr_en <= '1';
                    
                    FOUT_din <= std_logic_vector( signed( DEQUANTIZE( signed(FIN_dout) * to_signed(VOLUME_LEVEL, 32) ) ) sll (14 - BITS) );
                end if;

        end case;

    end process;

end architecture;