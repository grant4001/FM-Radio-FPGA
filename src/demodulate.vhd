library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity demodulate is
port( 
    clk : in std_logic; 
    rst : in std_logic;

    I_dout : in std_logic_vector (31 downto 0);
    I_rd_en : out std_logic;
    I_empty : in std_logic;

    Q_dout : in std_logic_vector (31 downto 0);
    Q_rd_en : out std_logic;
    Q_empty : in std_logic;

    FOUT_LPR_wr_en : out std_logic;
    FOUT_LPR_din : out std_logic_vector (31 downto 0);
    FOUT_LPR_full : in std_logic;

    FOUT_LMR_wr_en : out std_logic;
    FOUT_LMR_din : out std_logic_vector (31 downto 0);
    FOUT_LMR_full : in std_logic;

    FOUT_BP_PILOT_wr_en : out std_logic;
    FOUT_BP_PILOT_din : out std_logic_vector (31 downto 0);
    FOUT_BP_PILOT_full : in std_logic
);

end entity demodulate;

architecture behavior of demodulate is

    type state_type is (s0, s1, s2, s3, s4);
    signal state, next_state : state_type := s0;

    signal real_prev, real_prev_c : std_logic_vector (31 downto 0) := (others => '0');
    signal imag_prev, imag_prev_c : std_logic_vector (31 downto 0) := (others => '0');

    signal r_temp, r_temp_c : std_logic_vector (31 downto 0) := (others => '0');
    signal im_temp, im_temp_c : std_logic_vector (31 downto 0) := (others => '0');

    signal Q_saved, Q_saved_c : std_logic_vector (31 downto 0) := (others => '0');

    signal div_done : std_logic := '0';

    -- FIFO Initializations

    signal r_rd_en : std_logic := '0';
    signal r_wr_en : std_logic := '0';
    signal r_din : std_logic_vector (31 downto 0) := (others => '0');
    signal r_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal r_empty : std_logic := '0';
    signal r_full : std_logic := '0';

    signal im_rd_en : std_logic := '0';
    signal im_wr_en : std_logic := '0';
    signal im_din : std_logic_vector (31 downto 0) := (others => '0');
    signal im_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal im_empty : std_logic := '0';
    signal im_full : std_logic := '0';

    signal angle_rd_en : std_logic := '0';
    signal angle_wr_en : std_logic := '0';
    signal angle_din : std_logic_vector (31 downto 0) := (others => '0');
    signal angle_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal angle_empty : std_logic := '0';
    signal angle_full : std_logic := '0';

    component fifo is
        generic
        (
            constant FIFO_DATA_WIDTH : integer := 16;
            constant FIFO_BUFFER_SIZE : integer := 16
        );
        port
        (
            signal rd_clk : in std_logic;
            signal wr_clk : in std_logic;
            signal reset : in std_logic;
            signal rd_en : in std_logic;
            signal wr_en : in std_logic;
            signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal full : out std_logic;
            signal empty : out std_logic
        );
    end component fifo;

    component qarctan is
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
    end component;

begin

    -- COMPONENT INSTANTATIONS --

    r_demod_arctan_fifo : fifo 
    generic map
    (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => 32
    )
    port map 
    (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => r_rd_en,
        wr_en => r_wr_en,
        din => r_din,
        dout => r_dout,
        full => r_full,
        empty => r_empty
    );

    im_demod_arctan_fifo : fifo 
    generic map
    (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => 32
    )
    port map 
    (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => im_rd_en,
        wr_en => im_wr_en,
        din => im_din,
        dout => im_dout,
        full => im_full,
        empty => im_empty
    );

    qarctan_inst : qarctan 
    port map (
        clk => clk,
        rst => rst,

        y_dout => im_dout,
        y_rd_en => im_rd_en,
        y_empty => im_empty,

        x_dout => r_dout,
        x_rd_en => r_rd_en,
        x_empty => r_empty,

        FOUT_wr_en => angle_wr_en,
        FOUT_din => angle_din,
        FOUT_full => angle_full,

        done => div_done
    );

    angle_fifo : fifo
    generic map
    (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => 32
    )
    port map 
    (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => angle_rd_en,
        wr_en => angle_wr_en,
        din => angle_din,
        dout => angle_dout,
        full => angle_full,
        empty => angle_empty
    );

    -- PROCESSES --

    reg_proc : process (clk, rst)
    begin
        if rst = '1' then
            state <= s0;
            real_prev <= (others => '0');
            imag_prev <= (others => '0');
            r_temp <= (others => '0');
            im_temp <= (others => '0');
            Q_saved <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;
            real_prev <= real_prev_c;
            imag_prev <= imag_prev_c;
            r_temp <= r_temp_c;
            im_temp <= im_temp_c;
            Q_saved <= Q_saved_c;
        end if;
    end process;

    comb_proc : process (I_empty, I_dout, Q_empty, Q_dout, FOUT_LPR_full, FOUT_LMR_full, FOUT_BP_PILOT_full,
        state, real_prev, imag_prev,
        r_temp, im_temp, Q_saved, div_done,
        r_full, im_full, angle_empty, angle_dout) 

    begin 

        next_state <= state;
        real_prev_c <= real_prev;
        imag_prev_c <= imag_prev;
        r_temp_c <= r_temp;
        im_temp_c <= im_temp;
        Q_saved_c <= Q_saved;

        I_rd_en <= '0';
        Q_rd_en <= '0';
        FOUT_LPR_wr_en <= '0';
        FOUT_LPR_din <= (others => '0');
        FOUT_LMR_wr_en <= '0';
        FOUT_LMR_din <= (others => '0');
        FOUT_BP_PILOT_wr_en <= '0';
        FOUT_BP_PILOT_din <= (others => '0');

        r_wr_en <= '0';
        im_wr_en <= '0';
        r_din <= (others => '0');
        im_din <= (others => '0');
        angle_rd_en <= '0';
            
        case (state) is 

            when s0 => 

                if (I_empty = '0' and Q_empty = '0') then

                    I_rd_en <= '1';
                    Q_rd_en <= '1';
                    
                    r_temp_c <= DEQUANTIZE( signed(real_prev) * signed(I_dout) );
                    im_temp_c <= DEQUANTIZE( signed(real_prev) * signed(Q_dout) );

                    real_prev_c <= I_dout;
                    Q_saved_c <= Q_dout;

                    next_state <= s1;

                end if;

            when s1 =>
                
                r_temp_c <= std_logic_vector( resize( signed(r_temp) - resize( signed( DEQUANTIZE( ( not(signed(imag_prev)) + to_signed(1, 32) ) * signed(Q_saved) ) ), 32 ), 32 ) );
                im_temp_c <= std_logic_vector( resize( signed(im_temp) + resize( signed( DEQUANTIZE( ( not(signed(imag_prev)) + to_signed(1, 32) ) * signed(real_prev) ) ), 32 ), 32 ) );
                     
                imag_prev_c <= Q_saved;
                next_state <= s2;

            when s2 =>
                
                if (r_full = '0' and im_full = '0') then
                    r_wr_en <= '1';
                    im_wr_en <= '1';

                    r_din <= r_temp;
                    im_din <= im_temp;
                    r_temp_c <= (others => '0');
                    im_temp_c <= (others => '0');

                    next_state <= s3;
                end if;

            when s3 =>

                if (div_done = '1') then
                    next_state <= s4;
                end if;

            when s4 =>
                
                if (angle_empty = '0' and FOUT_LPR_full = '0' and FOUT_BP_PILOT_full = '0' and FOUT_LMR_full = '0' ) then
                    angle_rd_en <= '1';
                    
                    FOUT_LPR_wr_en <= '1';
                    FOUT_BP_PILOT_wr_en <= '1';
                    FOUT_LMR_wr_en <= '1';

                    FOUT_LPR_din <= DEQUANTIZE( to_signed(QUANT_FM_DEMOD_GAIN, 32) * signed(angle_dout) );
                    FOUT_BP_PILOT_din <= DEQUANTIZE( to_signed(QUANT_FM_DEMOD_GAIN, 32) * signed(angle_dout) );
                    FOUT_LMR_din <= DEQUANTIZE( to_signed(QUANT_FM_DEMOD_GAIN, 32) * signed(angle_dout) );
                    
                    next_state <= s0;
                end if;

        end case;

    end process;

end architecture;