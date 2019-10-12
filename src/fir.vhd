library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity fir is
generic (
    TAPS : integer := 32;
    DECIMATION : integer := 10
);
port( 
    clk : in std_logic; 
    rst : in std_logic;

    FIN_dout : in std_logic_vector (31 downto 0);
    FIN_rd_en : out std_logic;
    FIN_empty : in std_logic;

    FOUT_wr_en : out std_logic;
    FOUT_din : out std_logic_vector (31 downto 0);
    FOUT_full : in std_logic;

    coeff_sel : in std_logic_vector (2 downto 0)
);

end entity fir;

architecture behavior of fir is

    type taps_type is array (0 to TAPS - 1) of std_logic_vector (31 downto 0);
    type state_type is (s0, s1, s2, s3);

    signal state, next_state : state_type := s0;
    signal dec, dec_c : std_logic_vector (7 downto 0) := (others => '0');
    signal x, x_c : taps_type := (others => (others => '0'));
    signal y, y_c : taps_type := (others => (others => '0'));
    signal j, j_c : std_logic_vector (7 downto 0) := (others => '0');
    signal y_out, y_out_c : std_logic_vector (31 downto 0) := (others => '0');

begin

    reg_proc : process (clk, rst)
    begin
        if rst = '1' then
            state <= s0;
            dec <= (others => '0');
            x <= (others => (others => '0'));
            y <= (others => (others => '0'));
            j <= (others => '0');
            y_out <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;
            dec <= dec_c;
            x <= x_c;
            y <= y_c;
            j <= j_c;
            y_out <= y_out_c;
        end if;
    end process;

    comb_proc : process (coeff_sel, FIN_empty, FIN_dout, FOUT_full, state, dec, x, y, j, y_out) 

        variable j_int : integer := 0;
        
    begin 

        next_state <= state;
        dec_c <= dec;
        x_c <= x;
        y_c <= y;
        j_c <= j;
        y_out_c <= y_out;

        FIN_rd_en <= '0';
        FOUT_wr_en <= '0';
        FOUT_din <= (others => '0');
            
        case (state) is 
            when s0 => 
                if (FIN_empty = '0') then
                    FIN_rd_en <= '1';
                    
                    for i in TAPS - 1 downto 1 loop
                        x_c(i) <= x(i - 1);
                    end loop;

                    x_c(0) <= FIN_dout;

                    if (to_integer(signed(dec)) = DECIMATION - 1) then
                        next_state <= s1;
                        dec_c <= (others => '0');
                    else 
                        dec_c <= std_logic_vector(resize(signed(dec) + to_signed(1, 8), 8));
                    end if;

                end if;

            when s1 =>
                j_int := to_integer(signed(j));    

                    if coeff_sel = "001" then
                        y_c(j_int) <= DEQUANTIZE( signed(AUDIO_LPR_COEFFS(TAPS - 1 - j_int)) * signed(x(j_int)) );
                    elsif coeff_sel = "010" then
                        y_c(j_int) <= DEQUANTIZE( signed(BP_PILOT_COEFFS(TAPS - 1 - j_int)) * signed(x(j_int)) );
                    elsif coeff_sel = "011" then
                        y_c(j_int) <= DEQUANTIZE( signed(HP_COEFFS(TAPS - 1 - j_int)) * signed(x(j_int)) );
                    elsif coeff_sel = "100" then
                        y_c(j_int) <= DEQUANTIZE( signed(BP_LMR_COEFFS(TAPS - 1 - j_int)) * signed(x(j_int)) );
                    elsif coeff_sel = "101" then
                        y_c(j_int) <= DEQUANTIZE( signed(AUDIO_LMR_COEFFS(TAPS - 1 - j_int)) * signed(x(j_int)) );
                    end if;

                if (j_int = TAPS - 1) then
                    next_state <= s2;
                    j_c <= (others => '0');
                else
                    j_c <= std_logic_vector(resize( signed(j) + to_signed(1, 8) , 8) );
                end if;
                    
            when s2 =>
                j_int := to_integer(signed(j));

                y_out_c <= std_logic_vector( resize( resize(signed(y_out), 32) + resize(signed(y(j_int)), 32), 32) );

                if (j_int = TAPS - 1) then
                    next_state <= s3;
                    j_c <= (others => '0');
                else
                    j_c <= std_logic_vector(resize(signed(j) + to_signed(1, 8) , 8) );
                end if;

            when s3 =>
                if (FOUT_full = '0') then
                    FOUT_wr_en <= '1';
                    FOUT_din <= y_out;
                    next_state <= s0;
                    y_out_c <= (others => '0');
                end if;

        end case;

    end process;

end architecture;