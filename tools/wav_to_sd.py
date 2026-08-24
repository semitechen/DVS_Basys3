import wave
import os
import struct
import array

INPUT_DIR = "tools/audio_in"           
OUTPUT_IMG = "results/sd_card.img"     
LUT_FILE = "rtl/track_lut.sv"      
SECTOR_SIZE = 512              

def process_audio():
    if not os.path.exists(INPUT_DIR):
        os.makedirs(INPUT_DIR)
        print(f"Utworzono folder '{INPUT_DIR}'.")
        print("Wrzuc tam pliki muzyczne (.wav) i uruchom skrypt ponownie.")
        return

    wav_files = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith('.wav')]
    if not wav_files:
        print(f"Brak plikow .wav w folderze '{INPUT_DIR}'.")
        return

    wav_files.sort() 
    
    lut_entries = []
    current_lba_sector = 0 

    print("Rozpoczynam konwersje audio (16-bit -> 8-bit unsigned)...")

    with open(OUTPUT_IMG, 'wb') as f_out:
        for track_idx, filename in enumerate(wav_files):
            filepath = os.path.join(INPUT_DIR, filename)
            
            with wave.open(filepath, 'rb') as wav:
                if wav.getsampwidth() != 2:
                    print(f"BLAD: Plik {filename} nie jest 16-bitowy! Skrypt wymaga 16-bitowych plikow.")
                    continue
                
                channels = wav.getnchannels()
                frames = wav.readframes(wav.getnframes())
                samples_16bit = array.array('h', frames)
                
                # Inżynierska poprawka: Konwersja Stereo do Mono w locie
                if channels == 2:
                    print(f"[{track_idx}] Konwersja Stereo -> Mono dla pliku {filename}")
                    mono_samples = samples_16bit[0::2] # Pobieramy co drugą próbkę (tylko lewy kanał)
                else:
                    mono_samples = samples_16bit
                
                # Obcięcie do 8 bitów i zmiana na wartości bez znaku (+128)
                samples_8bit = bytearray((s >> 8) + 128 for s in mono_samples)
                
                f_out.write(samples_8bit)
                
                bytes_written = len(samples_8bit)
                padding = (SECTOR_SIZE - (bytes_written % SECTOR_SIZE)) % SECTOR_SIZE
                if padding != 0:
                    # Poprawka sprzętowa: padding ciszą analogową (1.65V), nie zerami (0V)
                    f_out.write(b'\x80' * padding)
                
                lut_entries.append((track_idx, current_lba_sector, filename))
                
                sectors_used = (bytes_written + padding) // SECTOR_SIZE
                current_lba_sector += sectors_used
                
                print(f"[{track_idx}] {filename} -> Adres (LBA): {lut_entries[-1][1]}, Rozmiar: {sectors_used} sektorow.")

    print("\nGenerowanie modulu SystemVerilog (Track LUT)...")
    with open(LUT_FILE, 'w') as f_sv:
        f_sv.write("// AUTOMATYCZNIE WYGENEROWANY PLIK - NIE EDYTUJ RECZNIE\n")
        f_sv.write("// Skrypt wav_to_sd.py\n\n")
        f_sv.write("`timescale 1ns / 1ps\n\n")
        f_sv.write("module track_lut (\n")
        f_sv.write("    input  logic [7:0]  track_id,\n")
        f_sv.write("    output logic [31:0] start_lba\n")
        f_sv.write(");\n\n")
        f_sv.write("    always_comb begin\n")
        f_sv.write("        case (track_id)\n")
        
        for entry in lut_entries:
            f_sv.write(f"            8'd{entry[0]}: start_lba = 32'd{entry[1]}; // Plik: {entry[2]}\n")
            
        f_sv.write("            default: start_lba = 32'd0;\n")
        f_sv.write("        endcase\n")
        f_sv.write("    end\n")
        f_sv.write("endmodule\n")
        
    print(f"\nSukces! Gotowy obraz 8-bitowy do wgrania na karte: {OUTPUT_IMG}")
    print(f"Zaktualizowano modul z adresami: {LUT_FILE}")

if __name__ == "__main__":
    process_audio()