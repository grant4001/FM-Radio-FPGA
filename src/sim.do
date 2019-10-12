setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vcom -work work "constants.vhd"
vcom -work work "radio_tb.vhd"
vcom -work work "fifo.vhd"
vcom -work work "radio_top.vhd"
vcom -work work "readIQ.vhd"
vcom -work work "fir_cmplx.vhd"
vcom -work work "fir.vhd"
vcom -work work "fir_dualout.vhd"
vcom -work work "demodulate.vhd"
vcom -work work "qarctan.vhd"
vcom -work work "divider.vhd"
vcom -work work "comparator.vhd"
vcom -work work "mult.vhd"
vcom -work work "add.vhd"
vcom -work work "sub.vhd"
vcom -work work "iir.vhd"
vcom -work work "gain_n.vhd"

vsim +notimingchecks -L work work.radio_tb -wlf radio_sim.wlf

add wave -noupdate -group radio_tb
add wave -noupdate -group radio_tb -radix hexadecimal /radio_tb/*

add wave -noupdate -group radio_tb/radio_top_inst
add wave -noupdate -group radio_tb/radio_top_inst -radix hexadecimal /radio_tb/radio_top_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/readIQ_inst
add wave -noupdate -group radio_tb/radio_top_inst/readIQ_inst -radix hexadecimal /radio_tb/radio_top_inst/readIQ_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/fir_cmplx_inst
add wave -noupdate -group radio_tb/radio_top_inst/fir_cmplx_inst -radix hexadecimal /radio_tb/radio_top_inst/fir_cmplx_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst
add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst -radix hexadecimal /radio_tb/radio_top_inst/demodulate_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/qarctan_inst
add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/qarctan_inst -radix hexadecimal /radio_tb/radio_top_inst/demodulate_inst/qarctan_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/qarctan_inst/divider_inst
add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/qarctan_inst/divider_inst -radix hexadecimal /radio_tb/radio_top_inst/demodulate_inst/qarctan_inst/divider_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/firLPR
add wave -noupdate -group radio_tb/radio_top_inst/firLPR -radix hexadecimal /radio_tb/radio_top_inst/firLPR/*

add wave -noupdate -group radio_tb/radio_top_inst/firBP_PILOT
add wave -noupdate -group radio_tb/radio_top_inst/firBP_PILOT -radix hexadecimal /radio_tb/radio_top_inst/firBP_PILOT/*

add wave -noupdate -group radio_tb/radio_top_inst/mult_inst
add wave -noupdate -group radio_tb/radio_top_inst/mult_inst -radix hexadecimal /radio_tb/radio_top_inst/mult_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/firHP
add wave -noupdate -group radio_tb/radio_top_inst/firHP -radix hexadecimal /radio_tb/radio_top_inst/firHP/*

add wave -noupdate -group radio_tb/radio_top_inst/firLMR
add wave -noupdate -group radio_tb/radio_top_inst/firLMR -radix hexadecimal /radio_tb/radio_top_inst/firLMR/*

add wave -noupdate -group radio_tb/radio_top_inst/mult_inst2
add wave -noupdate -group radio_tb/radio_top_inst/mult_inst2 -radix hexadecimal /radio_tb/radio_top_inst/mult_inst2/*

add wave -noupdate -group radio_tb/radio_top_inst/firAUDIO_LMR
add wave -noupdate -group radio_tb/radio_top_inst/firAUDIO_LMR -radix hexadecimal /radio_tb/radio_top_inst/firAUDIO_LMR/*

add wave -noupdate -group radio_tb/radio_top_inst/add_inst
add wave -noupdate -group radio_tb/radio_top_inst/add_inst -radix hexadecimal /radio_tb/radio_top_inst/add_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/sub_inst
add wave -noupdate -group radio_tb/radio_top_inst/sub_inst -radix hexadecimal /radio_tb/radio_top_inst/sub_inst/*

add wave -noupdate -group radio_tb/radio_top_inst/iir_add
add wave -noupdate -group radio_tb/radio_top_inst/iir_add -radix hexadecimal /radio_tb/radio_top_inst/iir_add/*

add wave -noupdate -group radio_tb/radio_top_inst/iir_sub
add wave -noupdate -group radio_tb/radio_top_inst/iir_sub -radix hexadecimal /radio_tb/radio_top_inst/iir_sub/*

add wave -noupdate -group radio_tb/radio_top_inst/gain_left
add wave -noupdate -group radio_tb/radio_top_inst/gain_left -radix hexadecimal /radio_tb/radio_top_inst/gain_left/*

add wave -noupdate -group radio_tb/radio_top_inst/gain_right
add wave -noupdate -group radio_tb/radio_top_inst/gain_right -radix hexadecimal /radio_tb/radio_top_inst/gain_right/*







add wave -noupdate -group radio_tb/radio_top_inst/readIQ_fifo
add wave -noupdate -group radio_tb/radio_top_inst/readIQ_fifo -radix hexadecimal /radio_tb/radio_top_inst/readIQ_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/I_fifo
add wave -noupdate -group radio_tb/radio_top_inst/I_fifo -radix hexadecimal /radio_tb/radio_top_inst/I_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/Q_fifo
add wave -noupdate -group radio_tb/radio_top_inst/Q_fifo -radix hexadecimal /radio_tb/radio_top_inst/Q_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firc_dmod_r_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firc_dmod_r_fifo -radix hexadecimal /radio_tb/radio_top_inst/firc_dmod_r_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firc_dmod_i_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firc_dmod_i_fifo -radix hexadecimal /radio_tb/radio_top_inst/firc_dmod_i_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/r_demod_arctan_fifo
add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/r_demod_arctan_fifo -radix hexadecimal /radio_tb/radio_top_inst/demodulate_inst/r_demod_arctan_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/im_demod_arctan_fifo
add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/im_demod_arctan_fifo -radix hexadecimal /radio_tb/radio_top_inst/demodulate_inst/im_demod_arctan_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/angle_fifo
add wave -noupdate -group radio_tb/radio_top_inst/demodulate_inst/angle_fifo -radix hexadecimal /radio_tb/radio_top_inst/demodulate_inst/angle_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/dmod_firLPR_fifo
add wave -noupdate -group radio_tb/radio_top_inst/dmod_firLPR_fifo -radix hexadecimal /radio_tb/radio_top_inst/dmod_firLPR_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/dmod_firBP_PILOT_fifo
add wave -noupdate -group radio_tb/radio_top_inst/dmod_firBP_PILOT_fifo -radix hexadecimal /radio_tb/radio_top_inst/dmod_firBP_PILOT_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firBP_PILOT_mult1_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firBP_PILOT_mult1_fifo -radix hexadecimal /radio_tb/radio_top_inst/firBP_PILOT_mult1_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/mult_firHP_fifo
add wave -noupdate -group radio_tb/radio_top_inst/mult_firHP_fifo -radix hexadecimal /radio_tb/radio_top_inst/mult_firHP_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firHP_mult_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firHP_mult_fifo -radix hexadecimal /radio_tb/radio_top_inst/firHP_mult_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/dmod_firLMR_fifo
add wave -noupdate -group radio_tb/radio_top_inst/dmod_firLMR_fifo -radix hexadecimal /radio_tb/radio_top_inst/dmod_firLMR_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firLMR_mult_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firLMR_mult_fifo -radix hexadecimal /radio_tb/radio_top_inst/firLMR_mult_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/mult_firAUDIO_LMR_fifo
add wave -noupdate -group radio_tb/radio_top_inst/mult_firAUDIO_LMR_fifo -radix hexadecimal /radio_tb/radio_top_inst/mult_firAUDIO_LMR_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firAUDIO_LMR_add_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firAUDIO_LMR_add_fifo -radix hexadecimal /radio_tb/radio_top_inst/firAUDIO_LMR_add_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firLPR_add_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firLPR_add_fifo -radix hexadecimal /radio_tb/radio_top_inst/firLPR_add_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firAUDIO_LMR_sub_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firAUDIO_LMR_sub_fifo -radix hexadecimal /radio_tb/radio_top_inst/firAUDIO_LMR_sub_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/firLPR_sub_fifo
add wave -noupdate -group radio_tb/radio_top_inst/firLPR_sub_fifo -radix hexadecimal /radio_tb/radio_top_inst/firLPR_sub_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/add_iir_fifo
add wave -noupdate -group radio_tb/radio_top_inst/add_iir_fifo -radix hexadecimal /radio_tb/radio_top_inst/add_iir_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/sub_iir_fifo
add wave -noupdate -group radio_tb/radio_top_inst/sub_iir_fifo -radix hexadecimal /radio_tb/radio_top_inst/sub_iir_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/iir_leftgain_fifo
add wave -noupdate -group radio_tb/radio_top_inst/iir_leftgain_fifo -radix hexadecimal /radio_tb/radio_top_inst/iir_leftgain_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/iir_rightgain_fifo
add wave -noupdate -group radio_tb/radio_top_inst/iir_rightgain_fifo -radix hexadecimal /radio_tb/radio_top_inst/iir_rightgain_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/test_left_fifo
add wave -noupdate -group radio_tb/radio_top_inst/test_left_fifo -radix hexadecimal /radio_tb/radio_top_inst/test_left_fifo/*

add wave -noupdate -group radio_tb/radio_top_inst/test_right_fifo
add wave -noupdate -group radio_tb/radio_top_inst/test_right_fifo -radix hexadecimal /radio_tb/radio_top_inst/test_right_fifo/*

run -all