library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity fir_cmplx is
generic (
    TAPS : integer := 20;
    DECIMATION : integer := 1
);
port( 
    clk : in std_logic; 
    rst : in std_logic;

    I_dout : in std_logic_vector (31 downto 0);
    I_rd_en : out std_logic;
    I_empty : in std_logic;

    Q_dout : in std_logic_vector (31 downto 0);
    Q_rd_en : out std_logic;
    Q_empty : in std_logic;

    real_wr_en : out std_logic;
    real_din : out std_logic_vector (31 downto 0);
    real_full : in std_logic;

    imag_wr_en : out std_logic;
    imag_din : out std_logic_vector (31 downto 0);
    imag_full : in std_logic
);

end entity fir_cmplx;

architecture behavior of fir_cmplx is

    type taps_type is array (0 to TAPS - 1) of std_logic_vector (31 downto 0);
    type state_type is (s0, s1, s2, s3);
    
    signal state, next_state : state_type := s0;
    signal dec, dec_c : std_logic_vector (7 downto 0) := (others => '0');
    signal x_real, x_real_c : taps_type := (others => (others => '0'));
    signal x_imag, x_imag_c : taps_type := (others => (others => '0'));
    signal y_real, y_real_c : taps_type := (others => (others => '0'));
    signal y_imag, y_imag_c : taps_type := (others => (others => '0'));
    signal j, j_c : std_logic_vector (7 downto 0) := (others => '0');
    signal y_real_out, y_real_out_c : std_logic_vector (31 downto 0) := (others => '0');
    signal y_imag_out, y_imag_out_c : std_logic_vector (31 downto 0) := (others => '0');

begin

    reg_proc : process (clk, rst)
    begin
        if rst = '1' then

            state <= s0;
            dec <= (others => '0');
            x_real <= (others => (others => '0'));
            x_imag <= (others => (others => '0'));
            y_real <= (others => (others => '0'));
            y_imag <= (others => (others => '0'));
            j <= (others => '0');
            y_real_out <= (others => '0');
            y_imag_out <= (others => '0');

        elsif rising_edge(clk) then

            state <= next_state;
            dec <= dec_c;
            x_real <= x_real_c;
            x_imag <= x_imag_c;
            y_real <= y_real_c;
            y_imag <= y_imag_c;
            j <= j_c;
            y_real_out <= y_real_out_c;
            y_imag_out <= y_imag_out_c;

        end if;
    end process;

    comb_proc : process (I_empty, I_dout, Q_empty, Q_dout, real_full, imag_full, 
        state, dec, x_real, x_imag, y_real, y_imag, j, y_real_out, y_imag_out) 

        variable j_int : integer := 0;

    begin 

        next_state <= state;
        dec_c <= dec;
        x_real_c <= x_real;
        x_imag_c <= x_imag;
        y_real_c <= y_real;
        y_imag_c <= y_imag;
        j_c <= j;
        y_real_out_c <= y_real_out;
        y_imag_out_c <= y_imag_out;

        real_wr_en <= '0';
        imag_wr_en <= '0';
        real_din <= (others => '0');
        imag_din <= (others => '0');
        I_rd_en <= '0';
        Q_rd_en <= '0';
            
        case (state) is 

            when s0 => 

                if (I_empty = '0' and Q_empty = '0') then

                    I_rd_en <= '1';
                    Q_rd_en <= '1';
                    
                    for i in TAPS - 1 downto 1 loop
                        x_real_c(i) <= x_real(i - 1);
                        x_imag_c(i) <= x_imag(i - 1);
                    end loop;
 
                    x_real_c(0) <= I_dout;
                    x_imag_c(0) <= Q_dout;
 
                    if (to_integer(signed(dec)) = DECIMATION - 1) then
                        next_state <= s1;
                        dec_c <= (others => '0');
                    else 
                        dec_c <= std_logic_vector( signed(dec) + to_signed(1, 8) );
                    end if;

                end if;

            when s1 =>
                j_int := to_integer(signed(j));  

                y_real_c(j_int) <= DEQUANTIZE( signed(CHANNEL_COEFFS_REAL(j_int)) * signed(x_real(j_int)) );
                y_imag_c(j_int) <= DEQUANTIZE( signed(CHANNEL_COEFFS_REAL(j_int)) * signed(x_imag(j_int)) );

                if (j_int = TAPS - 1) then
                    next_state <= s2;
                    j_c <= (others => '0');
                else
                    j_c <= std_logic_vector(signed(j) + to_signed(1, 8));
                end if;
                    
            when s2 =>
                j_int := to_integer(signed(j));

                y_real_out_c <= std_logic_vector( resize( resize(signed(y_real_out), 32) + resize(signed(y_real(j_int)), 32), 32) );
                y_imag_out_c <= std_logic_vector( resize( resize(signed(y_imag_out), 32) + resize(signed(y_imag(j_int)), 32), 32) );

                if (j_int = TAPS - 1) then
                    next_state <= s3;
                    j_c <= (others => '0');
                else
                    j_c <= std_logic_vector(signed(j) + to_signed(1, 8));
                end if;

            when s3 =>
                if (real_full = '0' and imag_full = '0') then
                    real_wr_en <= '1';
                    imag_wr_en <= '1';

                    real_din <= y_real_out;
                    imag_din <= y_imag_out;
                    next_state <= s0;

                    y_real_out_c <= (others => '0');
                    y_imag_out_c <= (others => '0');
                end if;

        end case;

    end process;

end architecture;