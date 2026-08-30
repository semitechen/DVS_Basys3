#!/usr/bin/env python3
"""
Module: mp3_to_bin.py
Project: DVS_Basys3 (Digital Vinyl System)
Description: Converts any audio file (MP3, WAV, FLAC, AAC, etc.) to a high-quality
             8-bit 44.1 kHz Mono raw binary file (.bin) optimized for R-2R DAC playback.

Features:
 - Resampling to 44.1 kHz Mono via FFmpeg.
 - Peak Normalization / Headroom Maximizer (utilizes full 8-bit 0..255 range).
 - Soft-Knee Limiter to prevent clipping on loud transients.
 - Psychoacoustic 2nd-Order Noise Shaping + TPDF Dither to push quantization noise
   above 16 kHz, maximizing perceived dynamic range and eliminating 8-bit grit.
 - 512-Byte Sector Alignment (for direct SD card block / BRAM playback).
"""

import os
import sys
import argparse
import subprocess
import numpy as np

def decode_audio_ffmpeg(input_path, target_sr=44100):
    cmd = [
        "ffmpeg",
        "-i", input_path,
        "-vn",                      # No video
        "-ac", "1",                 # Force Mono downmix
        "-ar", str(target_sr),      # 44.1 kHz sample rate
        "-f", "f32le",              # 32-bit float Little Endian
        "-acodec", "pcm_f32le",
        "pipe:1"
    ]
    
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    raw_data, _ = proc.communicate()
    
    if proc.returncode != 0 or len(raw_data) == 0:
        raise RuntimeError(f"FFmpeg failed to decode audio file: {input_path}")
        
    samples = np.frombuffer(raw_data, dtype=np.float32)
    return samples

def soft_limiter(samples, threshold=0.95):
    out = np.copy(samples)
    mask_pos = out > threshold
    mask_neg = out < -threshold
    out[mask_pos] = threshold + (1.0 - threshold) * np.tanh((out[mask_pos] - threshold) / (1.0 - threshold))
    out[mask_neg] = -threshold - (1.0 - threshold) * np.tanh((-out[mask_neg] - threshold) / (1.0 - threshold))
    return out

def apply_dither_and_noise_shaping(samples_float, mode="shaped"):
    N = len(samples_float)
    out_8bit = np.zeros(N, dtype=np.uint8)
    scaled = samples_float * 126.0 + 127.5
    
    if mode == "none":
        return np.clip(np.round(scaled), 0, 255).astype(np.uint8)
    elif mode == "tpdf":
        dither = np.random.uniform(-0.5, 0.5, N) + np.random.uniform(-0.5, 0.5, N)
        return np.clip(np.round(scaled + dither), 0, 255).astype(np.uint8)
    elif mode == "shaped":
        e1, e2 = 0.0, 0.0
        dither = np.random.uniform(-0.5, 0.5, N) + np.random.uniform(-0.5, 0.5, N)
        for i in range(N):
            target_val = scaled[i] + (1.62 * e1 - 0.81 * e2) + dither[i]
            q_val = np.clip(np.round(target_val), 0.0, 255.0)
            out_8bit[i] = int(q_val)
            err = q_val - target_val
            e2, e1 = e1, err
        return out_8bit

def convert_audio(input_file, output_file=None, mode="shaped", normalize=True, sector_align=True):
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)
        
    if output_file is None:
        base, _ = os.path.splitext(input_file)
        output_file = f"{base}.bin"
        
    print(f"==================================================")
    print(f" DVS Audio Converter: MP3/WAV -> 8-bit 44.1kHz BIN")
    print(f"==================================================")
    print(f" Input File      : {input_file}")
    print(f" Output File     : {output_file}")
    print(f" Noise Shaping   : {mode.upper()}")
    print(f" Normalization   : {'ENABLED (-0.5 dBFS peak)' if normalize else 'DISABLED'}")
    print(f" Sector Align    : {'512-byte blocks' if sector_align else 'None'}")
    print(f"--------------------------------------------------")
    
    samples = decode_audio_ffmpeg(input_file, target_sr=44100)
    duration_sec = len(samples) / 44100.0
    print(f"-> Decoded {len(samples)} samples ({duration_sec:.2f} seconds).")
    
    if normalize:
        peak = np.max(np.abs(samples))
        if peak > 1e-5:
            print(f"-> Normalizing peak from {peak:.3f} ({20*np.log10(peak):.1f} dBFS) to 0.95 (-0.5 dBFS)...")
            samples = (samples / peak) * 0.95
        samples = soft_limiter(samples, threshold=0.95)
        
    print(f"-> Quantizing to 8-bit unsigned PCM with '{mode}' dither...")
    out_bytes = apply_dither_and_noise_shaping(samples, mode=mode)
    
    raw_bytes = bytes(out_bytes)
    if sector_align:
        padding = (512 - (len(raw_bytes) % 512)) % 512
        if padding > 0:
            raw_bytes += b'\x80' * padding
            print(f"-> Padded {padding} bytes (mid-scale 0x80) for 512-byte SD sector alignment.")
            
    with open(output_file, "wb") as f:
        f.write(raw_bytes)
        
    print(f"-> Wrote {len(raw_bytes)} bytes ({len(raw_bytes)/512:.0f} sectors) to '{output_file}'.")
    print(f"==================================================")
    print(f" Conversion Complete! Ready for SD card / DAC.")
    print(f"==================================================")

def main():
    parser = argparse.ArgumentParser(description="Convert MP3/WAV to 8-bit 44.1kHz BIN for SD card/DAC.")
    parser.add_argument("input", help="Path to input audio file (.mp3, .wav, etc.)")
    parser.add_argument("-o", "--output", help="Path to output .bin file")
    parser.add_argument("-m", "--mode", choices=["shaped", "tpdf", "none"], default="shaped")
    parser.add_argument("--no-norm", action="store_true", help="Disable peak normalization")
    parser.add_argument("--no-align", action="store_true", help="Disable 512-byte padding")
    args = parser.parse_args()
    convert_audio(args.input, args.output, args.mode, not args.no_norm, not args.no_align)

if __name__ == "__main__":
    main()
