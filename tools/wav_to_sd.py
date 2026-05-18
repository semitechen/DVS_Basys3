import wave
import os
import struct


INPUT_DIR = "tools/audio_in"         # Folder na pliki 
OUTPUT_IMG = "results/sd_card.img"     # Gotowy plik do wgrania na karte
LUT_FILE = "rtl/track_lut.sv"      # Sprzetowa tablica adresow
SECTOR_SIZE = 512              # Rozmiar sektora karty SD

def process_audio():
    # Sprawdzenie czy istnieje folder wejsciowy
    if not os.path.exists(INPUT_DIR):
        os.makedirs(INPUT_DIR)
        print(f"Utworzono folder '{INPUT_DIR}'.")
        print("Wrzuć tam pliki muzyczne (.wav) i uruchom skrypt ponownie.")
        return

    # Pobranie listy plików
    wav_files = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith('.wav')]
    if not wav_files:
        print(f"Brak plików .wav w folderze '{INPUT_DIR}'.")
        return

    wav_files.sort() # Sortujemy alfabetycznie, żeby utwory miały stałe numery
    
    lut_entries = []
    current_lba_sector = 0 # Adres startowy na karcie (0 to sam początek)

    print("Rozpoczynam konwersję audio...")

    with open(OUTPUT_IMG, 'wb') as f_out:
        for track_idx, filename in enumerate(wav_files):
            filepath = os.path.join(INPUT_DIR, filename)
            
            with wave.open(filepath, 'rb') as wav:
                if wav.getsampwidth() != 2:
                    print(f"BŁĄD: Plik {filename} nie jest 16-bitowy! Zostaje pominętyi.")
                    continue
                
                # Zczytanie samych surowych próbek (bez nagłówka RIFF)
                frames = wav.readframes(wav.getnframes())
                
                f_out.write(frames)
                
                # Karty SD czytają pełne bloki 512-bajtowe. 
                # Dopelnienie koncowki pliku zerami, żeby kolejny utwór zaczął się równo od nowego sektora.
                bytes_written = len(frames)
                padding = (SECTOR_SIZE - (bytes_written % SECTOR_SIZE)) % SECTOR_SIZE
                if padding != 0:
                    f_out.write(b'\x00' * padding)
                
                # Zapisanie informacji do wygenerowania kodu SV
                lut_entries.append((track_idx, current_lba_sector, filename))
                
                # Zaktualizowanie licznika o ilość wykorzystanych sektorów
                sectors_used = (bytes_written + padding) // SECTOR_SIZE
                current_lba_sector += sectors_used
                
                print(f"[{track_idx}] {filename} -> Adres (LBA): {lut_entries[-1][1]}, Rozmiar: {sectors_used} sektorów.")

    # GENEROWANIE KODU SYSTEMVERILOG
    print("\nGenerowanie modułu SystemVerilog (Track LUT)...")
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
            # Wpisanie twardych adresow LBA dla konkretnych numerów utworów
            f_sv.write(f"            8'd{entry[0]}: start_lba = 32'd{entry[1]}; // Plik: {entry[2]}\n")
            
        f_sv.write("            default: start_lba = 32'd0;\n")
        f_sv.write("        endcase\n")
        f_sv.write("    end\n")
        f_sv.write("endmodule\n")
        
    print(f"\nSukces! Gotowy obraz do wgrania: {OUTPUT_IMG}")
    print(f"Moduł do wrzucenia w Vivado: {LUT_FILE}")

if __name__ == "__main__":
    process_audio()