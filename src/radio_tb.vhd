library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use IEEE.math_real.all;
use IEEE.math_complex.all;
use work.constants.all;

entity radio_tb is
generic (
    constant CLOCK_PER : time := 10 ns;
    constant INPUT_FILE_NAME : string (12 downto 1) := "audio_iq.txt";

    constant LEFT_TEST_FILE_NAME : string (19 downto 1) := "left_audio_test.txt";
    constant LEFT_COMPARE_FILE_NAME : string (22 downto 1) := "left_audio_compare.txt";

    constant RIGHT_TEST_FILE_NAME : string (20 downto 1) := "right_audio_test.txt";
    constant RIGHT_COMPARE_FILE_NAME : string (23 downto 1) := "right_audio_compare.txt"
);
end entity radio_tb;

architecture behavior of radio_tb is

    component radio_top is 
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
    end component;

    signal clock : std_logic := '1';
    signal reset : std_logic := '0';
    signal hold_clock : std_logic := '0';
    signal in_write_done : std_logic := '0';
    signal out_read_done : std_logic := '0';
    signal errors_left : integer := 0;
    signal errors_right : integer := 0;

    signal readIQ_wr_en : std_logic := '0';
    signal readIQ_full : std_logic := '0';
    signal readIQ_din : std_logic_vector (7 downto 0) := (others => '0');
    signal readIQ_rd_en : std_logic := '0';
    signal readIQ_empty : std_logic := '0';
    signal readIQ_dout : std_logic_vector (7 downto 0) := (others => '0');

    signal test_left_rd_en : std_logic := '0';
    signal test_left_empty : std_logic := '0';
    signal test_left_dout : std_logic_vector (31 downto 0) := (others => '0');

    signal test_right_rd_en : std_logic := '0';
    signal test_right_empty : std_logic := '0';
    signal test_right_dout : std_logic_vector (31 downto 0) := (others => '0');

    begin

    radio_top_inst : radio_top
    port map (
        clk => clock,
        rst => reset,

        readIQ_din => readIQ_din,
        readIQ_wr_en =>  readIQ_wr_en,
        readIQ_full => readIQ_full,

        test_left_rd_en => test_left_rd_en,
        test_left_dout => test_left_dout,
        test_left_empty => test_left_empty,

        test_right_rd_en => test_right_rd_en,
        test_right_dout => test_right_dout,
        test_right_empty => test_right_empty
    );

    clock_process : process
    begin
        clock <= '1';
        wait for  (CLOCK_PER / 2);
        clock <= '0';
        wait for  (CLOCK_PER / 2);
        if ( hold_clock = '1' ) then
            wait;
        end if;
    end process clock_process;

    reset_process : process
    begin
        reset <= '0';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '1';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '0';
        wait;
    end process reset_process;

    file_read_process : process 

        file input_file : text;
        variable ln1, ln2 : line;
        variable my_byte : std_logic_vector (7 downto 0) := (others => '0');

    begin

        wait until (reset = '1');
        wait until (reset = '0');

        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Reading input file ") );
        write( ln1, INPUT_FILE_NAME );
        write( ln1, string'("...") );
        writeline( output, ln1 );

        file_open(input_file, INPUT_FILE_NAME, read_mode);
        readIQ_wr_en <= '0';

        while (not ENDFILE(input_file)) loop

            if (readIQ_full = '0') then
                readIQ_wr_en <= '1';
                readline(input_file, ln2);
                hread(ln2, my_byte);
                readIQ_din <= my_byte;
            else
                readIQ_wr_en <= '0';
            end if; 

            wait until (clock = '1');
            wait until (clock = '0');
            
        end loop;

        wait until (clock = '1');
        wait until (clock = '0');

        readIQ_wr_en <= '0';
        in_write_done <= '1';

        wait;
    end process file_read_process; 

    file_write_process : process 

        file test_left_file : text;
        file compare_left_file : text;
        file test_right_file : text;
        file compare_right_file : text;
        variable ln1, ln2, ln3, ln4, ln5, ln6, ln7 : line;
        variable i : integer := 0;
        variable compare_left_data : std_logic_vector (31 downto 0);
        variable compare_right_data : std_logic_vector (31 downto 0);
        
    begin

        wait until  (reset = '1');
        wait until  (reset = '0');
        wait until  (clock = '1');
        wait until  (clock = '0');

        file_open(test_left_file, LEFT_TEST_FILE_NAME, write_mode);
        file_open(compare_left_file, LEFT_COMPARE_FILE_NAME, read_mode);
        file_open(test_right_file, RIGHT_TEST_FILE_NAME, write_mode);
        file_open(compare_right_file, RIGHT_COMPARE_FILE_NAME, read_mode);

        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Comparing files. ") );

        test_left_rd_en <= '0';
        test_right_rd_en <= '0';

        while ( (not ENDFILE(compare_left_file)) and (not ENDFILE(compare_right_file)) ) loop

			wait until ( clock = '1');
            wait until ( clock = '0');

            if ( test_left_empty = '0' and test_right_empty = '0' ) then

                test_left_rd_en <= '1';
                test_right_rd_en <= '1';

                hwrite( ln2, test_left_dout );
                writeline( test_left_file, ln2 );
                readline( compare_left_file, ln3 );
                hread( ln3, compare_left_data );

                hwrite( ln4, test_right_dout );
                writeline( test_right_file, ln4 );
                readline( compare_right_file, ln5 );
                hread( ln5, compare_right_data );

                if ( to_01(unsigned(test_left_dout)) /= to_01(unsigned(compare_left_data)) ) then
                    errors_left <= errors_left + 1;
                    write( ln6, string'("@ ") );
                    write( ln6, NOW );
                    write( ln6, string'(": ") );
                    write( ln6, LEFT_TEST_FILE_NAME );
                    write( ln6, string'("(") );
                    write( ln6, i + 1 );
                    write( ln6, string'("): ERROR: ") );
                    hwrite( ln6, test_left_dout );
                    write( ln6, string'(" != ") );
                    hwrite( ln6, compare_left_data);
                    write( ln6, string'(" at address 0x") );
                    hwrite( ln6, std_logic_vector(to_unsigned(i, 32)) );
                     write( ln6, string'(".") );
                    writeline( output, ln6 );
                end if;
            
                if ( to_01(unsigned(test_right_dout)) /= to_01(unsigned(compare_right_data)) ) then
                    errors_right <= errors_right + 1;
                    write( ln7, string'("@ ") );
                    write( ln7, NOW );
                    write( ln7, string'(": ") );
                    write( ln7, RIGHT_TEST_FILE_NAME );
                    write( ln7, string'("(") );
                     write( ln7, i + 1 );
                    write( ln7, string'("): ERROR: ") );
                    hwrite( ln7, test_right_dout );
                    write( ln7, string'(" != ") );
                    hwrite( ln7, compare_right_data);
                    write( ln7, string'(" at address 0x") );
                    hwrite( ln7, std_logic_vector(to_unsigned(i, 32)) );
                    write( ln7, string'(".") );
                    writeline( output, ln7 );
                end if;

                i := i + 1;

            else

                test_left_rd_en <= '0';
                test_right_rd_en <= '0';

            end if;
        end loop;

        wait until  (clock = '1');
        wait until  (clock = '0');

        test_left_rd_en <= '0';
        test_right_rd_en <= '0';
        file_close( test_left_file );
        file_close( test_right_file );
        out_read_done <= '1';

        wait;
    end process file_write_process;

    tb_proc : process
        variable err_left : integer := 0;
        variable err_right : integer := 0;
        variable warnings : integer := 0;
        variable start_time : time;
        variable end_time : time;
        variable ln1, ln2, ln3, ln4, ln5 : line;
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');
        wait until  (clock = '0');
        wait until  (clock = '1');

        start_time := NOW;
        write( ln1, string'("@ ") );
        write( ln1, start_time );
        write( ln1, string'(": Beginning simulation...") );
        writeline( output, ln1 );

        wait until  (clock = '0');
        wait until  (clock = '1');
        wait until (out_read_done = '1');

        end_time := NOW;
        write( ln2, string'("@ ") );
        write( ln2, end_time );
        write( ln2, string'(": Simulation completed.") );
        writeline( output, ln2 );

        err_left := errors_left;
        err_right := errors_right;

        write( ln3, string'("Total simulation cycle count: ") );
        write( ln3, (end_time - start_time) / CLOCK_PER );
        writeline( output, ln3 );

        write( ln4, string'("Total left error count: ") );
        write( ln4, err_left );
        writeline( output, ln4 );

        write( ln5, string'("Total right error count: ") );
        write( ln5, err_right );
        writeline( output, ln5 );

        hold_clock <= '1';
        wait;

    end process tb_proc;

end architecture behavior;