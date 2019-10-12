library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity qarctan is
port( 
    clk : in std_logic; 
    rst : in std_logic;

    y_dout : in std_logic_vector (31 downto 0);
    y_rd_en : out std_logic;
    y_empty : in std_logic;

    x_dout : in std_logic_vector (31 downto 0);
    x_rd_en : out std_logic;
    x_empty : in std_logic;

    FOUT_wr_en : out std_logic;
    FOUT_din : out std_logic_vector (31 downto 0);
    FOUT_full : in std_logic;

    done : out std_logic
);

end entity qarctan;

architecture behavior of qarctan is

    type state_type is (s0, s1, s2, s3, s4);
    signal state, next_state : state_type := s0;

    signal div_start, div_start_c : std_logic := '0';
    signal dividend : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
    signal divisor : std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (others => '0');
    signal quotient : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
    signal remainder : std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (others => '0');
    signal overflow : std_logic := '0';

    signal dividend_temp, dividend_temp_c : std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (others => '0');
    signal divisor_temp, divisor_temp_c : std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (others => '0');
    signal neg_count, neg_count_c : std_logic_vector (3 downto 0) := (others => '0');
    signal neg_flag, neg_flag_c : std_logic := '0';

    signal my_y, my_y_c : std_logic_vector (31 downto 0) := (others => '0');
    signal my_x, my_x_c : std_logic_vector (31 downto 0) := (others => '0');

    component divider is
	port(
        start : in std_logic;
        dividend : in std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        divisor : in std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        
        quotient : out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
        remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
        overflow : out std_logic
    );
    end component divider;

begin

    divider_inst : divider 
    port map (
        start => div_start,
        dividend => dividend,
        divisor => divisor,

        quotient => quotient,
        remainder => remainder,
        overflow => overflow
    );

    reg_proc : process (clk, rst)
    begin
        if rst = '1' then
            state <= s0;
            my_y <= (others => '0');
            my_x <= (others => '0');
            div_start <= '0';
            neg_count <= (others => '0');
            neg_flag <= '0';
            dividend_temp <= (others => '0');
            divisor_temp <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;
            my_y <= my_y_c;
            my_x <= my_x_c;
            div_start <= div_start_c;
            neg_count <= neg_count_c;
            neg_flag <= neg_flag_c;
            dividend_temp <= dividend_temp_c;
            divisor_temp <= divisor_temp_c;
        end if;
    end process;

    comb_proc : process (y_empty, y_dout, x_empty, x_dout, FOUT_full, state, my_y, my_x, div_start,
        neg_count, neg_flag, dividend_temp, divisor_temp)

        variable angle_right_t : signed (31 downto 0) := (others => '0');
        variable angle_left_t : signed (31 downto 0) := (others => '0');
        variable quotient_final : std_logic_vector (31 downto 0) := (others => '0');
    begin 

        next_state <= state;

        y_rd_en <= '0';
        x_rd_en <= '0';
        FOUT_wr_en <= '0';
        FOUT_din <= (others => '0');

        dividend <= (others => '0');
        divisor <= (others => '0');
        dividend_temp_c <= dividend_temp;
        divisor_temp_c <= divisor_temp;
        neg_count_c <= neg_count;
        neg_flag_c <= neg_flag;

        my_y_c <= my_y;
        my_x_c <= my_x;
        div_start_c <= div_start;

        done <= '0';
            
        case (state) is 
            when s0 => 

                if (y_empty = '0' and x_empty = '0') then

                    y_rd_en <= '1';
                    x_rd_en <= '1';
                    my_y_c <= y_dout;
                    my_x_c <= x_dout;
                    
                    if (to_integer(signed(x_dout)) >= 0) then
                        dividend_temp_c <= std_logic_vector( resize( signed( QUANTIZE( signed(x_dout) - (abs(signed(y_dout)) + to_signed(1, 32)) ) ), DIVIDEND_WIDTH) );
                        divisor_temp_c <= std_logic_vector( resize( signed(x_dout) + (abs(signed(y_dout)) + to_signed(1, 32)), DIVISOR_WIDTH ) );
                    else
                        dividend_temp_c <= std_logic_vector( resize( signed( QUANTIZE( signed(x_dout) + (abs(signed(y_dout)) + to_signed(1, 32)) ) ), DIVIDEND_WIDTH) );
                        divisor_temp_c <= std_logic_vector( resize( ( abs(signed(y_dout)) + to_signed(1, 32) - signed(x_dout) ), DIVISOR_WIDTH ) );
                    end if;

                    next_state <= s1;

                end if;

            when s1 =>
                
                if ( dividend_temp(DIVIDEND_WIDTH - 1) = '1' ) then
                    neg_count_c <= std_logic_vector( signed(neg_count) + to_signed(1, 4) );
                    dividend_temp_c <= std_logic_vector( resize( not(signed(dividend_temp)) + to_signed(1, DIVIDEND_WIDTH), DIVIDEND_WIDTH) );
                end if;

                if ( divisor_temp(DIVISOR_WIDTH - 1) = '1' ) then
                    neg_count_c <= std_logic_vector( signed(neg_count) + to_signed(1, 4) );
                    divisor_temp_c <= std_logic_vector( resize( not(signed(divisor_temp)) + to_signed(1, DIVISOR_WIDTH), DIVISOR_WIDTH) );
                end if;

                next_state <= s2;

            when s2 =>
                if (to_integer(signed(neg_count)) = 1) then
                    neg_flag_c <= '1';
                end if;

                dividend <= dividend_temp;
                divisor <= divisor_temp;

                div_start_c <= '1';
                next_state <= s3;
            
            when s3 =>
                div_start_c <= '0';
                next_state <= s4;

            when s4 =>
                if (neg_flag = '1') then
                    quotient_final := std_logic_vector( resize( not( signed(quotient) ) + to_signed(1, DIVIDEND_WIDTH), 32 ) ); 
                else
                    quotient_final := std_logic_vector( resize( signed(quotient), 32 ) );
                end if;

                angle_right_t := resize( to_signed(QUANT_PI_OVER_4, 32) - signed( DEQUANTIZE( to_signed(QUANT_PI_OVER_4, 32) * signed(quotient_final) ) ), 32 ) ;
                angle_left_t := resize( to_signed(QUANT_3PI_OVER_4, 32) - signed( DEQUANTIZE( to_signed(QUANT_PI_OVER_4, 32) * signed(quotient_final) ) ), 32 ) ;

                if (FOUT_full = '0') then

                    FOUT_wr_en <= '1';

                    if (to_integer(signed(my_x)) >= 0) then
                        FOUT_din <= std_logic_vector( if_cond( to_integer( signed(my_y) ) < 0, 
                            resize( not( angle_right_t ) + to_signed(1, 32), 32 ) ,
                            angle_right_t ) );
                    else 
                        FOUT_din <= std_logic_vector( if_cond( to_integer( signed(my_y) ) < 0, 
                            resize( not( angle_left_t ) + to_signed(1, 32), 32 ) ,
                            angle_left_t ) );
                    end if;

                    next_state <= s0;
                    done <= '1';
                    neg_flag_c <= '0';
                    neg_count_c <= (others => '0');
                    dividend_temp_c <= (others => '0');
                    divisor_temp_c <= (others => '0');
                end if;

        end case;

    end process;

end architecture;