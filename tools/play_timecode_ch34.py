#!/usr/bin/env python3
"""
Playback script for streaming Serato timecode test audio directly to
Channels 3 & 4 of the Behringer UMC204HD audio interface while leaving
Channels 1 & 2 (headphones) silent/unaffected.
"""

import subprocess
import sys
import os

def play_ch34(wav_path="dvs_signal_audio_tests/serato_12in_33rpm_line_level.wav"):
    if not os.path.exists(wav_path):
        print(f"Error: Audio file '{wav_path}' not found.")
        sys.exit(1)

    print(f"Streaming '{wav_path}' to UMC204HD Channels 3 & 4...")
    print("Channels 1 & 2 (headphones) remain available for music.")
    
    # Use SoX with CoreAudio driver mapping: remix 0 0 1 2 (silence on ch 1 & 2, audio on ch 3 & 4)
    cmd = [
        "sox",
        wav_path,
        "-t", "coreaudio", "UMC204HD 192k",
        "remix", "0", "0", "1", "2"
    ]
    
    try:
        subprocess.run(cmd, check=True)
        print("Playback finished.")
    except Exception as e:
        print(f"Error running playback: {e}")
        # Alternative fallback with ffplay
        print("Trying fallback via ffplay...")
        ff_cmd = [
            "ffplay", "-nodisp", "-autoexit",
            "-af", "pan=4c|c0=c0*0|c1=c1*0|c2=c0|c3=c1",
            wav_path
        ]
        subprocess.run(ff_cmd)

if __name__ == "__main__":
    wav_file = sys.argv[1] if len(sys.argv) > 1 else "dvs_signal_audio_tests/serato_12in_33rpm_line_level.wav"
    play_ch34(wav_file)
