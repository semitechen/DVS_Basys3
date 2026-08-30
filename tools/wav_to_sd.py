import wave
import os
import array

INPUT_DIR = "tools/audio_in"           
OUTPUT_IMG = "results/sd_card.img"     
LUT_FILE = "rtl/track_lut.sv"      
SECTOR_SIZE = 512              

def process_audio():
    if not os.path.exists(INPUT_DIR):
        os.makedirs(INPUT_DIR)
        print(f"Utworzono folder '{INPUT_DIR}'.")
        return

    wav_files = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith('.wav')]
    if not wav_files:
        print(f"Brak plikow .wav w folderze '{INPUT_DIR}'.")
        return

    wav_files.sort() 
    lut_entries = []
    current_lba_sector = 0 

    print("Rozpoczynam konwersje audio z zaawansowanym DSP...")

    with open(OUTPUT_IMG, 'wb') as f_out:
        for track_idx, filename in enumerate(wav_files):
            filepath = os.path.join(INPUT_DIR, filename)
            
            with wave.open(filepath, 'rb') as wav:
                # 1. Walidacja parametrów (Ad 1)
                if wav.getsampwidth() != 2:
                    print(f"POMINIETO: {filename} (Wymagane 16-bit PCM)")
                    continue
                if wav.getframerate() != 44100:
                    print(f"POMINIETO: {filename} (Wymagane 44.1 kHz, wykryto {wav.getframerate()} Hz)")
                    continue
                
                channels = wav.getnchannels()
                frames = wav.readframes(wav.getnframes())
                samples_16bit = array.array('h', frames)
                
                # 2. Downmix Stereo do Mono (Ad 2)
                if channels == 2:
                    # Szybkie wyliczenie średniej z (L + R)
                    mono_samples = [(samples_16bit[i] + samples_16bit[i+1]) // 2 for i in range(0, len(samples_16bit), 2)]
                else:
                    mono_samples = samples_16bit

                # 3. Peak Normalization (Ad 3) - Ochrona przed clippingiem
                max_val = max(abs(s) for s in mono_samples) if mono_samples else 1
                # Zostawiamy margines 5% (-0.45 dBFS), żeby uniknąć uderzenia w wartości ekstremalne
                target_max = 31000 
                if max_val > 0:
                    scale_factor = target_max / max_val
                    mono_samples = [int(s * scale_factor) for s in mono_samples]

                # Konwersja na 8-bit unsigned (Przesunięcie i offset)
                samples_8bit = bytearray((s >> 8) + 128 for s in mono_samples)
                
                f_out.write(samples_8bit)
                
                bytes_written = len(samples_8bit)
                padding = (SECTOR_SIZE - (bytes_written % SECTOR_SIZE)) % SECTOR_SIZE
                if padding != 0:
                    f_out.write(b'\x80' * padding) # Cisza analogowa
                
                sectors_used = (bytes_written + padding) // SECTOR_SIZE
                lut_entries.append((track_idx, current_lba_sector, filename))
                current_lba_sector += sectors_used
                
                print(f"[{track_idx}] {filename} -> Sukces. Adres LBA: {lut_entries[-1][1]}")

    # Aktualizacja LUT (bez zmian)
    with open(LUT_FILE, 'w') as f_sv:
        f_sv.write("// AUTOMATYCZNIE WYGENEROWANY PLIK\n`timescale 1ns / 1ps\n\nmodule track_lut (\n    input  logic [7:0]  track_id,\n    output logic [31:0] start_lba\n);\n    always_comb begin\n        case (track_id)\n")
        for entry in lut_entries:
            f_sv.write(f"            8'd{entry[0]}: start_lba = 32'd{entry[1]};\n")
        f_sv.write("            default: start_lba = 32'd0;\n        endcase\n    end\nendmodule\n")

    print("\nGotowe. Nowy obraz wygenerowany.")

if __name__ == "__main__":
    process_audio()