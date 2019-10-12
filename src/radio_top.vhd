library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;

entity radio_top is 
port (
    clk : in std_logic;
    rst : in std_logic;

    readIQ_din : in std_logic_vector (7 downto 0);
    readIQ_wr_en : in std_logic;
    readIQ_full : out std_logic;

    test_left_rd_en : in std_logic;
    test_left_dout : out std_logic_vector (31 downto 0);
    test_left_empty : out std_logic;

    test_right_rd_en : in std_logic;
    test_right_dout : out std_logic_vector (31 downto 0);
    test_right_empty : out std_logic
);
end entity;

architecture behavior of radio_top is

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

    component readIQ is
        port(
            signal clk : in std_logic;
            signal rst : in std_logic;
         
            signal FIN_rd_en: out std_logic;
            signal FIN_dout: in std_logic_vector(7 downto 0);
            signal FIN_empty: in std_logic;
         
            signal FOUT_i_wr_en: out std_logic;
            signal FOUT_i_full : in std_logic;
            signal FOUT_i_din : out std_logic_vector(31 downto 0);
        
            signal FOUT_q_wr_en: out std_logic;
            signal FOUT_q_full : in std_logic;
            signal FOUT_q_din : out std_logic_vector(31 downto 0)
        );
    end component;

    component fir_cmplx is
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
        
    end component fir_cmplx;

    component demodulate is
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
    end component;

    component fir is
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
    end component;

    component mult is
        port( 
            clk : in std_logic; 
            rst : in std_logic;
        
            mult_in1_dout : in std_logic_vector (31 downto 0);
            mult_in1_rd_en : out std_logic;
            mult_in1_empty : in std_logic;
        
            mult_in2_dout : in std_logic_vector (31 downto 0);
            mult_in2_rd_en : out std_logic;
            mult_in2_empty : in std_logic;
        
            FOUT_wr_en : out std_logic;
            FOUT_din : out std_logic_vector (31 downto 0);
            FOUT_full : in std_logic;

            square_flag : in std_logic
        );
    end component;

    component fir_dualout is
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
        
            FOUT2_wr_en : out std_logic;
            FOUT2_din : out std_logic_vector (31 downto 0);
            FOUT2_full : in std_logic;
        
            coeff_sel : in std_logic_vector (2 downto 0)
        );
        
        end component fir_dualout;

    component add is
        port( 
            clk : in std_logic; 
            rst : in std_logic;
        
            add_in1_dout : in std_logic_vector (31 downto 0);
            add_in1_rd_en : out std_logic;
            add_in1_empty : in std_logic;
        
            add_in2_dout : in std_logic_vector (31 downto 0);
            add_in2_rd_en : out std_logic;
            add_in2_empty : in std_logic;
        
            FOUT_wr_en : out std_logic;
            FOUT_din : out std_logic_vector (31 downto 0);
            FOUT_full : in std_logic
        );
        
    end component add;

    component sub is
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
        
    end component sub;

    component iir is
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
    end component iir;

    component gain_n is
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
    end component gain_n;

    signal readIQ_dout : std_logic_vector (7 downto 0) := (others => '0');
    signal readIQ_rd_en : std_logic := '0';
    signal readIQ_empty : std_logic := '0';

    signal I_din : std_logic_vector (31 downto 0) := (others => '0');
    signal I_wr_en : std_logic := '0';
    signal I_full : std_logic := '0';
    signal I_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal I_rd_en : std_logic := '0';
    signal I_empty : std_logic := '0';

    signal Q_din : std_logic_vector (31 downto 0) := (others => '0');
    signal Q_wr_en : std_logic := '0';
    signal Q_full : std_logic := '0';
    signal Q_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal Q_rd_en : std_logic := '0';
    signal Q_empty : std_logic := '0';

    signal firc_dmod_r_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firc_dmod_r_rd_en : std_logic := '0';
    signal firc_dmod_r_empty : std_logic := '0';
    signal firc_dmod_r_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firc_dmod_r_wr_en : std_logic := '0';
    signal firc_dmod_r_full : std_logic := '0';

    signal firc_dmod_i_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firc_dmod_i_rd_en : std_logic := '0';
    signal firc_dmod_i_empty : std_logic := '0';
    signal firc_dmod_i_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firc_dmod_i_wr_en : std_logic := '0';
    signal firc_dmod_i_full : std_logic := '0';

    signal dmod_firLPR_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal dmod_firLPR_rd_en : std_logic := '0';
    signal dmod_firLPR_empty : std_logic := '0';
    signal dmod_firLPR_din : std_logic_vector (31 downto 0) := (others => '0');
    signal dmod_firLPR_wr_en : std_logic := '0';
    signal dmod_firLPR_full : std_logic := '0';

    signal dmod_firBP_PILOT_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal dmod_firBP_PILOT_rd_en : std_logic := '0';
    signal dmod_firBP_PILOT_empty : std_logic := '0';
    signal dmod_firBP_PILOT_din : std_logic_vector (31 downto 0) := (others => '0');
    signal dmod_firBP_PILOT_wr_en : std_logic := '0';
    signal dmod_firBP_PILOT_full : std_logic := '0';

    signal firBP_PILOT_mult_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firBP_PILOT_mult_rd_en : std_logic := '0';
    signal firBP_PILOT_mult_empty : std_logic := '0';
    signal firBP_PILOT_mult_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firBP_PILOT_mult_wr_en : std_logic := '0';
    signal firBP_PILOT_mult_full : std_logic := '0';

    signal mult_firHP_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal mult_firHP_rd_en : std_logic := '0';
    signal mult_firHP_empty : std_logic := '0';
    signal mult_firHP_din : std_logic_vector (31 downto 0) := (others => '0');
    signal mult_firHP_wr_en : std_logic := '0';
    signal mult_firHP_full : std_logic := '0';

    signal firHP_mult_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firHP_mult_rd_en : std_logic := '0';
    signal firHP_mult_empty : std_logic := '0';
    signal firHP_mult_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firHP_mult_wr_en : std_logic := '0';
    signal firHP_mult_full : std_logic := '0';

    signal dmod_firLMR_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal dmod_firLMR_rd_en : std_logic := '0';
    signal dmod_firLMR_empty : std_logic := '0';
    signal dmod_firLMR_din : std_logic_vector (31 downto 0) := (others => '0');
    signal dmod_firLMR_wr_en : std_logic := '0';
    signal dmod_firLMR_full : std_logic := '0';

    signal firLMR_mult_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firLMR_mult_rd_en : std_logic := '0';
    signal firLMR_mult_empty : std_logic := '0';
    signal firLMR_mult_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firLMR_mult_wr_en : std_logic := '0';
    signal firLMR_mult_full : std_logic := '0';
    
    signal mult_firAUDIO_LMR_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal mult_firAUDIO_LMR_rd_en : std_logic := '0';
    signal mult_firAUDIO_LMR_empty : std_logic := '0';
    signal mult_firAUDIO_LMR_din : std_logic_vector (31 downto 0) := (others => '0');
    signal mult_firAUDIO_LMR_wr_en : std_logic := '0';
    signal mult_firAUDIO_LMR_full : std_logic := '0';

    signal firAUDIO_LMR_add_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firAUDIO_LMR_add_rd_en : std_logic := '0';
    signal firAUDIO_LMR_add_empty : std_logic := '0';
    signal firAUDIO_LMR_add_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firAUDIO_LMR_add_wr_en : std_logic := '0';
    signal firAUDIO_LMR_add_full : std_logic := '0';

    signal firAUDIO_LMR_sub_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firAUDIO_LMR_sub_rd_en : std_logic := '0';
    signal firAUDIO_LMR_sub_empty : std_logic := '0';
    signal firAUDIO_LMR_sub_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firAUDIO_LMR_sub_wr_en : std_logic := '0';
    signal firAUDIO_LMR_sub_full : std_logic := '0';

    signal firLPR_add_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firLPR_add_rd_en : std_logic := '0';
    signal firLPR_add_empty : std_logic := '0';
    signal firLPR_add_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firLPR_add_wr_en : std_logic := '0';
    signal firLPR_add_full : std_logic := '0';

    signal firLPR_sub_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal firLPR_sub_rd_en : std_logic := '0';
    signal firLPR_sub_empty : std_logic := '0';
    signal firLPR_sub_din : std_logic_vector (31 downto 0) := (others => '0');
    signal firLPR_sub_wr_en : std_logic := '0';
    signal firLPR_sub_full : std_logic := '0';

    signal add_iir_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal add_iir_rd_en : std_logic := '0';
    signal add_iir_empty : std_logic := '0';
    signal add_iir_din : std_logic_vector (31 downto 0) := (others => '0');
    signal add_iir_wr_en : std_logic := '0';
    signal add_iir_full : std_logic := '0';

    signal sub_iir_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal sub_iir_rd_en : std_logic := '0';
    signal sub_iir_empty : std_logic := '0';
    signal sub_iir_din : std_logic_vector (31 downto 0) := (others => '0');
    signal sub_iir_wr_en : std_logic := '0';
    signal sub_iir_full : std_logic := '0';

    signal iir_leftgain_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal iir_leftgain_rd_en : std_logic := '0';
    signal iir_leftgain_empty : std_logic := '0';
    signal iir_leftgain_din : std_logic_vector (31 downto 0) := (others => '0');
    signal iir_leftgain_wr_en : std_logic := '0';
    signal iir_leftgain_full : std_logic := '0';

    signal iir_rightgain_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal iir_rightgain_rd_en : std_logic := '0';
    signal iir_rightgain_empty : std_logic := '0';
    signal iir_rightgain_din : std_logic_vector (31 downto 0) := (others => '0');
    signal iir_rightgain_wr_en : std_logic := '0';
    signal iir_rightgain_full : std_logic := '0';

    signal gnd_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal gnd_rd_en : std_logic := '0';
    signal gnd_empty : std_logic := '0';

    signal test_left_din : std_logic_vector (31 downto 0) := (others => '0');
    signal test_left_wr_en : std_logic := '0';
    signal test_left_full : std_logic := '0';

    signal test_right_din : std_logic_vector (31 downto 0) := (others => '0');
    signal test_right_wr_en : std_logic := '0';
    signal test_right_full : std_logic := '0';

begin

    readIQ_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 8,
        FIFO_BUFFER_SIZE => 8
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => readIQ_rd_en,
        wr_en => readIQ_wr_en,
        din => readIQ_din,
        dout => readIQ_dout,
        full => readIQ_full,
        empty => readIQ_empty
    );

    readIQ_inst : readIQ 
    port map (
        clk => clk,
        rst => rst,
 
        FIN_dout => readIQ_dout,
        FIN_rd_en => readIQ_rd_en,
        FIN_empty => readIQ_empty,
 
        FOUT_i_wr_en => I_wr_en,
        FOUT_i_din => I_din,
        FOUT_i_full => I_full,
        
        FOUT_q_wr_en => Q_wr_en,
        FOUT_q_din => Q_din,
        FOUT_q_full => Q_full
    );

    I_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => I_rd_en,
        wr_en => I_wr_en,
        din => I_din,
        dout => I_dout,
        full => I_full,
        empty => I_empty
    );

    Q_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => Q_rd_en,
        wr_en => Q_wr_en,
        din => Q_din,
        dout => Q_dout,
        full => Q_full,
        empty => Q_empty
    );

    fir_cmplx_inst : fir_cmplx 
    generic map (
        TAPS => 20,
        DECIMATION => 1
    )
    port map (
        clk => clk,
        rst => rst,

        I_dout => I_dout,
        I_rd_en => I_rd_en,
        I_empty => I_empty,

        Q_dout => Q_dout,
        Q_rd_en => Q_rd_en,
        Q_empty => Q_empty,

        real_wr_en => firc_dmod_r_wr_en,
        real_din => firc_dmod_r_din,
        real_full => firc_dmod_r_full,

        imag_wr_en => firc_dmod_i_wr_en,
        imag_din => firc_dmod_i_din,
        imag_full => firc_dmod_i_full
    );

    firc_dmod_r_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firc_dmod_r_rd_en,
        wr_en => firc_dmod_r_wr_en,
        din => firc_dmod_r_din,
        dout => firc_dmod_r_dout,
        full => firc_dmod_r_full,
        empty => firc_dmod_r_empty
    );

    firc_dmod_i_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firc_dmod_i_rd_en,
        wr_en => firc_dmod_i_wr_en,
        din => firc_dmod_i_din,
        dout => firc_dmod_i_dout,
        full => firc_dmod_i_full,
        empty => firc_dmod_i_empty
    );

    demodulate_inst : demodulate 
    port map (
        clk => clk,
        rst => rst,

        I_dout => firc_dmod_r_dout,
        I_rd_en => firc_dmod_r_rd_en,
        I_empty => firc_dmod_r_empty,

        Q_dout => firc_dmod_i_dout,
        Q_rd_en => firc_dmod_i_rd_en,
        Q_empty => firc_dmod_i_empty,

        FOUT_LPR_wr_en => dmod_firLPR_wr_en,
        FOUT_LPR_din => dmod_firLPR_din,
        FOUT_LPR_full => dmod_firLPR_full,

        FOUT_BP_PILOT_wr_en => dmod_firBP_PILOT_wr_en,
        FOUT_BP_PILOT_din => dmod_firBP_PILOT_din,
        FOUT_BP_PILOT_full => dmod_firBP_PILOT_full,

        FOUT_LMR_wr_en => dmod_firLMR_wr_en,
        FOUT_LMR_din => dmod_firLMR_din,
        FOUT_LMR_full => dmod_firLMR_full
    );

    dmod_firLPR_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => dmod_firLPR_rd_en,
        wr_en => dmod_firLPR_wr_en,
        din => dmod_firLPR_din,
        dout => dmod_firLPR_dout,
        full => dmod_firLPR_full,
        empty => dmod_firLPR_empty
    );

    firLPR : fir_dualout 
    generic map (
        TAPS => AUDIO_LPR_COEFF_TAPS,
        DECIMATION => AUDIO_DECIM
    )
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => dmod_firLPR_dout,
        FIN_rd_en => dmod_firLPR_rd_en,
        FIN_empty => dmod_firLPR_empty,

        FOUT_wr_en => firLPR_add_wr_en,
        FOUT_din => firLPR_add_din,
        FOUT_full => firLPR_add_full,

        FOUT2_wr_en => firLPR_sub_wr_en,
        FOUT2_din => firLPR_sub_din,
        FOUT2_full => firLPR_sub_full,

        coeff_sel => "001"
    );

    dmod_firBP_PILOT_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => dmod_firBP_PILOT_rd_en,
        wr_en => dmod_firBP_PILOT_wr_en,
        din => dmod_firBP_PILOT_din,
        dout => dmod_firBP_PILOT_dout,
        full => dmod_firBP_PILOT_full,
        empty => dmod_firBP_PILOT_empty
    );

    firBP_PILOT : fir 
    generic map (
        TAPS => BP_PILOT_COEFF_TAPS,
        DECIMATION => 1
    )
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => dmod_firBP_PILOT_dout,
        FIN_rd_en => dmod_firBP_PILOT_rd_en,
        FIN_empty => dmod_firBP_PILOT_empty,

        FOUT_wr_en => firBP_PILOT_mult_wr_en,
        FOUT_din => firBP_PILOT_mult_din,
        FOUT_full => firBP_PILOT_mult_full,

        coeff_sel => "010"
    );

    firBP_PILOT_mult1_fifo : fifo
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firBP_PILOT_mult_rd_en,
        wr_en => firBP_PILOT_mult_wr_en,
        din => firBP_PILOT_mult_din,
        dout => firBP_PILOT_mult_dout,
        full => firBP_PILOT_mult_full,
        empty => firBP_PILOT_mult_empty
    );

    mult_inst : mult
    port map (
        clk => clk,
        rst => rst,

        mult_in1_dout => firBP_PILOT_mult_dout,
        mult_in1_rd_en => firBP_PILOT_mult_rd_en,
        mult_in1_empty => firBP_PILOT_mult_empty,

        mult_in2_dout => gnd_dout,
        mult_in2_rd_en => gnd_rd_en,
        mult_in2_empty => gnd_empty,

        FOUT_wr_en => mult_firHP_wr_en,
        FOUT_din => mult_firHP_din,
        FOUT_full => mult_firHP_full,

        square_flag => '1'
    );

    mult_firHP_fifo : fifo
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => mult_firHP_rd_en,
        wr_en => mult_firHP_wr_en,
        din => mult_firHP_din,
        dout => mult_firHP_dout,
        full => mult_firHP_full,
        empty => mult_firHP_empty
    );

    firHP : fir 
    generic map (
        TAPS => HP_COEFF_TAPS,
        DECIMATION => 1
    )
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => mult_firHP_dout,
        FIN_rd_en => mult_firHP_rd_en,
        FIN_empty => mult_firHP_empty,

        FOUT_wr_en => firHP_mult_wr_en,
        FOUT_din => firHP_mult_din,
        FOUT_full => firHP_mult_full,

        coeff_sel => "011"
    );

    firHP_mult_fifo : fifo
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firHP_mult_rd_en,
        wr_en => firHP_mult_wr_en,
        din => firHP_mult_din,
        dout => firHP_mult_dout,
        full => firHP_mult_full,
        empty => firHP_mult_empty
    );

    dmod_firLMR_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => dmod_firLMR_rd_en,
        wr_en => dmod_firLMR_wr_en,
        din => dmod_firLMR_din,
        dout => dmod_firLMR_dout,
        full => dmod_firLMR_full,
        empty => dmod_firLMR_empty
    );

    firLMR : fir 
    generic map (
        TAPS => BP_LMR_COEFF_TAPS,
        DECIMATION => 1
    )
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => dmod_firLMR_dout,
        FIN_rd_en => dmod_firLMR_rd_en,
        FIN_empty => dmod_firLMR_empty,

        FOUT_wr_en => firLMR_mult_wr_en,
        FOUT_din => firLMR_mult_din,
        FOUT_full => firLMR_mult_full,

        coeff_sel => "100"
    );

    firLMR_mult_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firLMR_mult_rd_en,
        wr_en => firLMR_mult_wr_en,
        din => firLMR_mult_din,
        dout => firLMR_mult_dout,
        full => firLMR_mult_full,
        empty => firLMR_mult_empty
    );

    mult_inst2 : mult
    port map (
        clk => clk,
        rst => rst,

        mult_in1_dout => firLMR_mult_dout,
        mult_in1_rd_en => firLMR_mult_rd_en,
        mult_in1_empty => firLMR_mult_empty,

        mult_in2_dout => firHP_mult_dout,
        mult_in2_rd_en => firHP_mult_rd_en,
        mult_in2_empty => firHP_mult_empty,

        FOUT_wr_en => mult_firAUDIO_LMR_wr_en,
        FOUT_din => mult_firAUDIO_LMR_din,
        FOUT_full => mult_firAUDIO_LMR_full,

        square_flag => '0'
    );

    mult_firAUDIO_LMR_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => mult_firAUDIO_LMR_rd_en,
        wr_en => mult_firAUDIO_LMR_wr_en,
        din => mult_firAUDIO_LMR_din,
        dout => mult_firAUDIO_LMR_dout,
        full => mult_firAUDIO_LMR_full,
        empty => mult_firAUDIO_LMR_empty
    );

    firAUDIO_LMR : fir_dualout 
    generic map (
        TAPS => AUDIO_LMR_COEFF_TAPS,
        DECIMATION => AUDIO_DECIM
    )
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => mult_firAUDIO_LMR_dout,
        FIN_rd_en => mult_firAUDIO_LMR_rd_en,
        FIN_empty => mult_firAUDIO_LMR_empty,

        FOUT_wr_en => firAUDIO_LMR_add_wr_en,
        FOUT_din => firAUDIO_LMR_add_din,
        FOUT_full => firAUDIO_LMR_add_full,

        FOUT2_wr_en => firAUDIO_LMR_sub_wr_en,
        FOUT2_din => firAUDIO_LMR_sub_din,
        FOUT2_full => firAUDIO_LMR_sub_full,

        coeff_sel => "101"
    );

    firAUDIO_LMR_add_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firAUDIO_LMR_add_rd_en,
        wr_en => firAUDIO_LMR_add_wr_en,
        din => firAUDIO_LMR_add_din,
        dout => firAUDIO_LMR_add_dout,
        full => firAUDIO_LMR_add_full,
        empty => firAUDIO_LMR_add_empty
    );

    firLPR_add_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firLPR_add_rd_en,
        wr_en => firLPR_add_wr_en,
        din => firLPR_add_din,
        dout => firLPR_add_dout,
        full => firLPR_add_full,
        empty => firLPR_add_empty
    );

    add_inst : add
    port map (
        clk => clk,
        rst => rst,

        add_in1_dout => firLPR_add_dout,
        add_in1_rd_en => firLPR_add_rd_en,
        add_in1_empty => firLPR_add_empty,

        add_in2_dout => firAUDIO_LMR_add_dout,
        add_in2_rd_en => firAUDIO_LMR_add_rd_en,
        add_in2_empty => firAUDIO_LMR_add_empty,

        FOUT_wr_en => add_iir_wr_en,
        FOUT_din => add_iir_din,
        FOUT_full => add_iir_full

    );

    firAUDIO_LMR_sub_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firAUDIO_LMR_sub_rd_en,
        wr_en => firAUDIO_LMR_sub_wr_en,
        din => firAUDIO_LMR_sub_din,
        dout => firAUDIO_LMR_sub_dout,
        full => firAUDIO_LMR_sub_full,
        empty => firAUDIO_LMR_sub_empty
    );

    firLPR_sub_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => firLPR_sub_rd_en,
        wr_en => firLPR_sub_wr_en,
        din => firLPR_sub_din,
        dout => firLPR_sub_dout,
        full => firLPR_sub_full,
        empty => firLPR_sub_empty
    );

    sub_inst : sub
    port map (
        clk => clk,
        rst => rst,

        sub_in1_dout => firLPR_sub_dout,
        sub_in1_rd_en => firLPR_sub_rd_en,
        sub_in1_empty => firLPR_sub_empty,

        sub_in2_dout => firAUDIO_LMR_sub_dout,
        sub_in2_rd_en => firAUDIO_LMR_sub_rd_en,
        sub_in2_empty => firAUDIO_LMR_sub_empty,

        FOUT_wr_en => sub_iir_wr_en,
        FOUT_din => sub_iir_din,
        FOUT_full => sub_iir_full
    );

    add_iir_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => add_iir_rd_en,
        wr_en => add_iir_wr_en,
        din => add_iir_din,
        dout => add_iir_dout,
        full => add_iir_full,
        empty => add_iir_empty
    );

    sub_iir_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => sub_iir_rd_en,
        wr_en => sub_iir_wr_en,
        din => sub_iir_din,
        dout => sub_iir_dout,
        full => sub_iir_full,
        empty => sub_iir_empty
    );

    iir_add : iir 
    generic map (
        TAPS => IIR_COEFF_TAPS,
        DECIMATION => 1
    )
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => add_iir_dout,
        FIN_rd_en => add_iir_rd_en,
        FIN_empty => add_iir_empty,

        FOUT_wr_en => iir_leftgain_wr_en,
        FOUT_din => iir_leftgain_din,
        FOUT_full => iir_leftgain_full
    );

    iir_sub : iir 
    generic map (
        TAPS => IIR_COEFF_TAPS,
        DECIMATION => 1
    )
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => sub_iir_dout,
        FIN_rd_en => sub_iir_rd_en,
        FIN_empty => sub_iir_empty,

        FOUT_wr_en => iir_rightgain_wr_en,
        FOUT_din => iir_rightgain_din,
        FOUT_full => iir_rightgain_full
    );

    iir_leftgain_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => iir_leftgain_rd_en,
        wr_en => iir_leftgain_wr_en,
        din => iir_leftgain_din,
        dout => iir_leftgain_dout,
        full => iir_leftgain_full,
        empty => iir_leftgain_empty
    );

    iir_rightgain_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => iir_rightgain_rd_en,
        wr_en => iir_rightgain_wr_en,
        din => iir_rightgain_din,
        dout => iir_rightgain_dout,
        full => iir_rightgain_full,
        empty => iir_rightgain_empty
    );

    gain_left : gain_n 
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => iir_leftgain_dout,
        FIN_rd_en => iir_leftgain_rd_en,
        FIN_empty => iir_leftgain_empty,

        FOUT_wr_en => test_left_wr_en,
        FOUT_din => test_left_din,
        FOUT_full => test_left_full
    );

    gain_right : gain_n 
    port map (
        clk => clk,
        rst => rst,

        FIN_dout => iir_rightgain_dout,
        FIN_rd_en => iir_rightgain_rd_en,
        FIN_empty => iir_rightgain_empty,

        FOUT_wr_en => test_right_wr_en,
        FOUT_din => test_right_din,
        FOUT_full => test_right_full
    );

    test_left_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => test_left_rd_en,
        wr_en => test_left_wr_en,
        din => test_left_din,
        dout => test_left_dout,
        full => test_left_full,
        empty => test_left_empty
    );

    test_right_fifo : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => GLOBAL_FIFO_WIDTH
    )
    port map (
        rd_clk => clk,
        wr_clk => clk,
        reset => rst,
        rd_en => test_right_rd_en,
        wr_en => test_right_wr_en,
        din => test_right_din,
        dout => test_right_dout,
        full => test_right_full,
        empty => test_right_empty
    );

end architecture behavior;