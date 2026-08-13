#!/usr/bin/env python3
"""
Serato Performance Vinyl 12" (NoiseMap 1000 Hz Timecode) Audio Generator
Turntable: Reloop RP-7000 MK2 (Line Level Output)
Speed: Standard 33 1/3 RPM

Generates high-fidelity 44.1 kHz, 16-bit stereo PCM WAV audio files
modeling the exact quadrature 1 kHz timecode signal.
"""

import math
import struct
import wave
import os

def generate_serato_timecode_wav(
    filename="serato_12in_33rpm_line_level.wav",
    duration_sec=10.0,
    sample_rate=44100,
    carrier_freq=1000.0,
    amplitude_ratio=0.80  # ~ -2dB Line level output from Reloop RP-7000 MK2
):
    output_dir = os.path.dirname(filename)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)

    num_samples = int(sample_rate * duration_sec)
    max_amplitude = int(32767 * amplitude_ratio)

    print(f"Generating Serato NoiseMap Timecode Signal: {filename}")
    print(f"Duration: {duration_sec}s | Sample Rate: {sample_rate}Hz | Carrier: {carrier_freq}Hz")

    # Serato 1000Hz 90-degree quadrature timecode
    with wave.open(filename, "w") as wav_file:
        wav_file.setnchannels(2)      # Stereo
        wav_file.setsampwidth(2)      # 16-bit
        wav_file.setframerate(sample_rate)

        frames = bytearray()
        for i in range(num_samples):
            t = i / sample_rate
            angle = 2.0 * math.pi * carrier_freq * t

            # Left Channel: Sine
            val_l = int(max_amplitude * math.sin(angle))
            # Right Channel: Cosine (90 deg phase shifted for Forward 33 1/3 RPM)
            val_r = int(max_amplitude * math.cos(angle))

            # Clamp to 16-bit signed range
            val_l = max(-32768, min(32767, val_l))
            val_r = max(-32768, min(32767, val_r))

            # Pack 16-bit Little-Endian Stereo samples (L, R)
            frames.extend(struct.pack("<hh", val_l, val_r))

        wav_file.writeframes(frames)

    print(f"Successfully generated {filename} ({os.path.getsize(filename)} bytes).")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_wav = os.path.join(script_dir, "serato_12in_33rpm_line_level.wav")
    generate_serato_timecode_wav(filename=target_wav, duration_sec=10.0)
