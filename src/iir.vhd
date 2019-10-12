library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity iir is
generic (
    TAPS : integer := 2;
    DECIMATION : integer := 1
);
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

end entity iir;

architecture behavior of iir is

    type taps_type is array (0 to TAPS - 1) of std_logic_vector (31 downto 0);
    signal x, x_c : taps_type := (others => (others => '0'));
    signal y, y_c : taps_type := (others => (others => '0'));

    signal mult_temp1, mult_temp1_c : taps_type := (others => (others => '0')); 
    signal mult_temp2, mult_temp2_c : taps_type := (others => (others => '0'));
    signal add_temp1, add_temp1_c : std_logic_vector (31 downto 0) := (others => '0');
    signal add_temp2, add_temp2_c : std_logic_vector (31 downto 0) := (others => '0'); 

    type state_type is (s0, s1, s2, s3);
    signal state, next_state : state_type := s0;
    signal dec, dec_c : std_logic_vector (7 downto 0) := (others => '0');
    signal j, j_c : std_logic_vector (7 downto 0) := (others => '0');

begin

    reg_proc : process (clk, rst)
    begin
        if rst = '1' then
            state <= s0;
            dec <= (others => '0');
            x <= (others => (others => '0'));
            y <= (others => (others => '0'));
            j <= (others => '0');

            mult_temp1 <= (others => (others => '0'));
            mult_temp2 <= (others => (others => '0'));
            add_temp1 <= (others => '0');
            add_temp2 <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;
            dec <= dec_c;
            x <= x_c;
            y <= y_c;
            j <= j_c;

            mult_temp1 <= mult_temp1_c;
            mult_temp2 <= mult_temp2_c;
            add_temp1 <= add_temp1_c;
            add_temp2 <= add_temp2_c;
        end if;
    end process;

    comb_proc : process (FIN_empty, FIN_dout, FOUT_full, state, dec, x, y, j,
        mult_temp1, mult_temp2, add_temp1, add_temp2) 

        variable j_int : integer := 0;
        
    begin 

        next_state <= state;
        dec_c <= dec;
        x_c <= x;
        y_c <= y;
        j_c <= j;

        FIN_rd_en <= '0';
        FOUT_wr_en <= '0';
        FOUT_din <= (others => '0');

        mult_temp1_c <= mult_temp1;
        mult_temp2_c <= mult_temp2;
        add_temp1_c <= add_temp1;
        add_temp2_c <= add_temp2;
            
        case (state) is 
            when s0 => 
                if (FIN_empty = '0') then
                    FIN_rd_en <= '1';
                    
                    for i in TAPS - 1 downto 1 loop
                        x_c(i) <= x(i - 1);
                    end loop;

                    x_c(0) <= FIN_dout;

                    if (to_integer(signed(dec)) = DECIMATION - 1) then

                        for k in TAPS - 1 downto 1 loop
                            y_c(k) <= y(k - 1);
                        end loop;

                        next_state <= s1;
                        dec_c <= (others => '0');
                    else 
                        dec_c <= std_logic_vector(signed(dec) + to_signed(1, 8));
                    end if;

                end if;

            when s1 =>
                j_int := to_integer(signed(j));    

                mult_temp1_c(j_int) <= DEQUANTIZE( signed(IIR_X_COEFFS(j_int)) * signed(x(j_int)) );
                mult_temp2_c(j_int) <= DEQUANTIZE( signed(IIR_Y_COEFFS(j_int)) * signed(y(j_int)) );

                if (j_int = TAPS - 1) then
                    next_state <= s2;
                    j_c <= (others => '0');
                else
                    j_c <= std_logic_vector(signed(j) + to_signed(1, 8));
                end if;
                    
            when s2 =>
                j_int := to_integer(signed(j));

                add_temp1_c <= std_logic_vector( resize( signed(add_temp1) + signed(mult_temp1(j_int)), 32 ) );
                add_temp2_c <= std_logic_vector( resize( signed(add_temp2) + signed(mult_temp2(j_int)), 32 ) );

                if (j_int = TAPS - 1) then
                    next_state <= s3;
                    j_c <= (others => '0');
                else
                    j_c <= std_logic_vector(signed(j) + to_signed(1, 8));
                end if;

            when s3 =>

                y_c(0) <= std_logic_vector( resize( signed(add_temp1) + signed(add_temp2), 32 ) );

                if (FOUT_full = '0') then
                    FOUT_wr_en <= '1';
                    FOUT_din <= y(TAPS - 1);
                    next_state <= s0;

                    add_temp1_c <= (others => '0');
                    add_temp2_c <= (others => '0');
                end if;

        end case;

    end process;

end architecture;