This project uses VHDL and ModelSim to generate an audio file from an input file of radio data (containing real and imaginary components of the signal). The resulting audio file can be played on your machine by building the C++ source code (audio player) and running the executable.

Quick build:

$ g++ -Wno-narrowing src_cpp/fm_radio.cpp src_cpp/audio.cpp src_cpp/main.cpp -o fm_radio

$ ./fm_radio test/left_audio_test.txt test/right_audio_test.txt
