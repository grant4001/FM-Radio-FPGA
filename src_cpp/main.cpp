

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <unistd.h>

#include "fm_radio.h"
#include "audio.h"

using namespace std;

int main(int argc, char **argv)
{
    static unsigned char IQ[SAMPLES*4];
    static int left_audio[AUDIO_SAMPLES];
    static int right_audio[AUDIO_SAMPLES];

    if ( argc < 2 )
    {
        printf("Missing input file.\n");
        return -1;
    }
    
    // initialize the audio output
    int audio_fd = audio_init( AUDIO_RATE );
    if ( audio_fd < 0 )
    {
        printf("Failed to initialize audio!\n");
        return -1;
    }

    /*
    FILE * usrp_file = fopen(argv[1], "rb");
    if ( usrp_file == NULL )
    {
        printf("Unable to open file.\n");
        return -1;
    }    
    */

    FILE * left = fopen(argv[1], "rb");
    if (left == NULL)
    {
        printf("Unable to open file.\n");
        return -1;
    }

    FILE * right = fopen(argv[2], "rb");
    if (right == NULL)
    {
        printf("Unable to open file.\n");
        return -1;
    }

    // IQ data, printed out for VHDL use
    //FILE * final_iq_file = fopen("audio_iq.txt", "w");
    
    while( !feof(left) && !feof(right) )
    {
        // fread( IQ, sizeof(char), SAMPLES * 4, usrp_file );

        // fm radio in mono 
        // fm_radio_stereo( IQ, left_audio, right_audio, left, right, final_iq_file);

        for (int ii = 0; ii < AUDIO_SAMPLES - 1 ; ii++) {
            fscanf(left, "%08X", &left_audio[ii]);
            fscanf(right, "%08X", &right_audio[ii]);
        } 

        // write to audio output
        audio_tx( audio_fd, AUDIO_RATE, left_audio, right_audio, AUDIO_SAMPLES );
    } 
    
    // fclose( usrp_file );
    fclose( left );
    fclose( right );
    close( audio_fd );

    return 0;
}

