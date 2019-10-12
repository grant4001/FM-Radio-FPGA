library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

package constants is

    --Helper functions

    function QUANTIZE( val : signed )
    return std_logic_vector;

    function DEQUANTIZE( val : signed )
    return std_logic_vector;

    function if_cond( test : boolean; true_cond : signed; false_cond : signed )
    return signed;

    --Global variables

    type array_1d is array (natural range <>) of std_logic_vector (31 downto 0);
    constant BITS : integer := 10;
    constant GLOBAL_FIFO_WIDTH : integer := 8;

    constant DIVIDEND_WIDTH : natural := 36;
    constant DIVISOR_WIDTH : natural := 30;
    
    constant QUANT_PI_OVER_4 : integer := 804;
    constant QUANT_3PI_OVER_4 : integer := 2412;
    constant QUANT_FM_DEMOD_GAIN : integer := 759;

    constant VOLUME_LEVEL : integer := 1024;

    -- Deemphasis IIR Filter Coefficients: 

    constant IIR_COEFF_TAPS : integer := 2;

    constant IIR_Y_COEFF_1 : integer := 0;
    constant IIR_Y_COEFF_2 : integer := -666;
    constant IIR_X_COEFF_1 : integer := 178;
    constant IIR_X_COEFF_2 : integer := 178;

    constant IIR_Y_COEFFS : array_1d := (std_logic_vector(to_signed(IIR_Y_COEFF_1, 32)), 
                                        std_logic_vector(to_signed(IIR_Y_COEFF_2, 32)) );
    constant IIR_X_COEFFS : array_1d := (std_logic_vector(to_signed(IIR_X_COEFF_1, 32)), 
                                        std_logic_vector(to_signed(IIR_X_COEFF_2, 32)) );
    -- Channel low-pass complex filter coefficients @ 0kHz to 80kHz

    constant CHANNEL_COEFF_TAPS : integer := 20;
    constant CHANNEL_COEFFS_REAL : array_1d := 
        (x"00000001", x"00000008", x"fffffff3", x"00000009", x"0000000b", x"ffffffd3", x"00000045", x"ffffffd3", 
        x"ffffffb1", x"00000257", x"00000257", x"ffffffb1", x"ffffffd3", x"00000045", x"ffffffd3", x"0000000b", 
        x"00000009", x"fffffff3", x"00000008", x"00000001");

    -- L+R low-pass filter coefficients @ 15kHz

    constant AUDIO_DECIM : integer := 8;
    constant AUDIO_LPR_COEFF_TAPS : integer := 32;
    constant AUDIO_LPR_COEFFS : array_1d := 
        (x"fffffffd", x"fffffffa", x"fffffff4", x"ffffffed", x"ffffffe5", x"ffffffdf", x"ffffffe2", x"fffffff3", 
        x"00000015", x"0000004e", x"0000009b", x"000000f9", x"0000015d", x"000001be", x"0000020e", x"00000243", 
        x"00000243", x"0000020e", x"000001be", x"0000015d", x"000000f9", x"0000009b", x"0000004e", x"00000015", 
        x"fffffff3", x"ffffffe2", x"ffffffdf", x"ffffffe5", x"ffffffed", x"fffffff4", x"fffffffa", x"fffffffd");

    -- L-R low-pass filter coefficients @ 15kHz, gain = 60

    constant AUDIO_LMR_COEFF_TAPS : integer := 32;
    constant AUDIO_LMR_COEFFS : array_1d :=
        (x"fffffffd", x"fffffffa", x"fffffff4", x"ffffffed", x"ffffffe5", x"ffffffdf", x"ffffffe2", x"fffffff3", 
        x"00000015", x"0000004e", x"0000009b", x"000000f9", x"0000015d", x"000001be", x"0000020e", x"00000243", 
        x"00000243", x"0000020e", x"000001be", x"0000015d", x"000000f9", x"0000009b", x"0000004e", x"00000015", 
        x"fffffff3", x"ffffffe2", x"ffffffdf", x"ffffffe5", x"ffffffed", x"fffffff4", x"fffffffa", x"fffffffd");

    -- Pilot tone band-pass filter @ 19kHz

    constant BP_PILOT_COEFF_TAPS : integer := 32;
    constant BP_PILOT_COEFFS : array_1d := 
        (x"0000000e", x"0000001f", x"00000034", x"00000048", x"0000004e", x"00000036", x"fffffff8", x"ffffff98", 
        x"ffffff2d", x"fffffeda", x"fffffec3", x"fffffefe", x"ffffff8a", x"0000004a", x"0000010f", x"000001a1", 
        x"000001a1", x"0000010f", x"0000004a", x"ffffff8a", x"fffffefe", x"fffffec3", x"fffffeda", x"ffffff2d", 
        x"ffffff98", x"fffffff8", x"00000036", x"0000004e", x"00000048", x"00000034", x"0000001f", x"0000000e");

    -- L-R band-pass filter @ 23kHz to 53kHz

    constant BP_LMR_COEFF_TAPS : integer := 32;
    constant BP_LMR_COEFFS : array_1d :=
        (x"00000000", x"00000000", x"fffffffc", x"fffffff9", x"fffffffe", x"00000008", x"0000000c", x"00000002", 
        x"00000003", x"0000001e", x"00000030", x"fffffffc", x"ffffff8c", x"ffffff58", x"ffffffc3", x"0000008a", 
        x"0000008a", x"ffffffc3", x"ffffff58", x"ffffff8c", x"fffffffc", x"00000030", x"0000001e", x"00000003", 
        x"00000002", x"0000000c", x"00000008", x"fffffffe", x"fffffff9", x"fffffffc", x"00000000", x"00000000");
    
    -- High pass filter @ 0Hz removes noise after pilot tone is squared

    constant HP_COEFF_TAPS : integer := 32;
    constant HP_COEFFS : array_1d :=
        (x"ffffffff", x"00000000", x"00000000", x"00000002", x"00000004", x"00000008", x"0000000b", x"0000000c", 
        x"00000008", x"ffffffff", x"ffffffee", x"ffffffd7", x"ffffffbb", x"ffffff9f", x"ffffff87", x"ffffff76", 
        x"ffffff76", x"ffffff87", x"ffffff9f", x"ffffffbb", x"ffffffd7", x"ffffffee", x"ffffffff", x"00000008", 
        x"0000000c", x"0000000b", x"00000008", x"00000004", x"00000002", x"00000000", x"00000000", x"ffffffff");
        
end package constants;

package body constants is

    function QUANTIZE( val : signed)
    return std_logic_vector is
    begin
        --return std_logic_vector( resize( ( resize(signed(val), 32) * resize( ( to_signed(1, 32) sll BITS ), 32 ) ), 32) );
        return std_logic_vector( resize( ( resize(signed(val), 32) sll BITS ), 32 ) );
    end function;

    function DEQUANTIZE( val : signed )
    return std_logic_vector is
    begin
        return std_logic_vector( resize( ( resize(signed(val), 32) / resize( ( to_signed(1, 32) sll BITS ), 32 ) ), 32) );
    end function;

    function if_cond( test : boolean; true_cond : signed; false_cond : signed )
	return signed is 
	begin
		if (test) then
			return true_cond;
		else
			return false_cond;
		end if;
    end function if_cond;

end package body constants;