# DVS_Basys3 - Digital Vinyl System na FPGA Basys 3

Projekt cyfrowego systemu winylowego (Digital Vinyl System - DVS) zrealizowany na układzie FPGA Xilinx Artix-7 (Digilent Basys 3) w ramach przedmiotu Układy Elektroniczne Cyfrowe 2 (UEC2) na AGH.

System dekoduje analogowy sygnał timecode (Serato 1 kHz) z gramofonu DJ-skiego, odczytuje bezstratne próbki audio PCM z karty SD i generuje sygnał audio przez przetwornik cyfrowo-analogowy DAC R-2R ze sprzętowym kształtowaniem szumu (Noise Shaping).

---

## Architektura Systemu

Projekt obsługuje zarówno konfigurację **Single-Board** (jedna płytka Basys 3), jak i **Dual-Board** (dwie współpracujące płytki Basys 3 połączone magistralą UART 2 Mbps):

```text
┌────────────────────────────────────────────────────────┐
│                        PŁYTKA A                        │
│          (Dekoder Timecode + Odtwarzacz SD)            │
│                                                        │
│  [Gramofon RCA]  ---> JXADC (XADC 12-bit)              │
│  [Karta micro-SD] ---> Pmod JA (SPI Master 16.67 MHz)  │
│  [NCO Player]    ---> Próbkowanie 44.1 kHz * prędkość  │
│  [UART TX]       ---> Pmod JC1 (Pin K17 @ 2 Mbps)      │
│  [16x LED]       ---> Wskaźnik obrotu talerza          │
└───────────────────────────┬────────────────────────────┘
                            │ Sygnał Audio (2 Mbps) + GND
                            ▼
┌────────────────────────────────────────────────────────┐
│                        PŁYTKA B                        │
│             (Odbiornik DAC + Audio VU Meter)           │
│                                                        │
│  [UART RX]       <--- Pmod JC1 (Pin K17 @ 2 Mbps)      │
│  [Watchdog]      <--- Autowyciszenie przy braku danych │
│  [16x DAC R-2R]  ---> Pmod JA / JXADC (dac[7:0])       │
│  [12x LED VU]    ---> Dynamiczny wskaźnik poziomu      │
└────────────────────────────────────────────────────────┘
```

---

## Struktura Modułów RTL

* **`rtl/top_dvs_basys3.sv`** - Zintegrowany moduł nadrzędny dla pojedynczej płytki (dekodowanie timecode, odczyt z SD oraz wyjście DAC na jednej płytce).
* **`rtl/top_board_a_streamer.sv`** - Moduł nadrzędny Płytki A: akwizycja analogowa XADC, 4-krotny dekoder kwadraturowy, czytnik SD SPI, modulator prędkości NCO oraz nadajnik UART 2 Mbps.
* **`rtl/top_board_b_dac.sv`** - Moduł nadrzędny Płytki B: odbiornik UART 2 Mbps, filtr wyciszający watchdog, 16-krotnie nadpróbkowany przetwornik DAC R-2R z ditherem TPDF oraz wskaźnik VU-Meter.
* **`rtl/timecode_pos_tracker.sv`** - Filtr DC offsetu, bramka squelch, przerzutnik Schmitta, dekoder kwadraturowy 4x oraz estymator prędkości w formacie Q4.12.
* **`rtl/variable_speed_player.sv`** - Generator próbek oparty o akumulator fazy NCO sterowany zadaną prędkością.
* **`rtl/r2r_dac.sv`** - 16-krotny oversampling z pętlą kształtowania szumu kwantyzacji pierwszego rzędu ($1 - z^{-1}$) i ditherem TPDF.
* **`rtl/sd_card_controller.sv` & `rtl/sd_bram_bridge.sv`** - Kontroler SPI 16.67 MHz z podwójnym buforowaniem w pamięci BRAM.

---

## Połączenia Sprzętowe

### 1. Połączenia między Płytką A i Płytką B:
* **Audio Data:** Płytka A `Pmod JC1` (Pin 1 - `K17`) $\longleftrightarrow$ Płytka B `Pmod JC1` (Pin 1 - `K17`).
* **Masa (GND):** Płytka A `Pmod JC` (Pin 5 lub 11) $\longleftrightarrow$ Płytka B `Pmod JC` (Pin 5 lub 11).

### 2. Płytka A (Wejścia):
* **Pmod JXADC (Wejścia timecode z gramofonu):**
  * `XA1_P` (`J3`) / `XA1_N` (`K3`): Kanał lewy timecode (poprzez układ polaryzacji AC).
  * `XA2_P` (`L3`) / `XA2_N` (`M3`): Kanał prawy timecode.
* **Pmod JA Górny Rząd (Karta micro-SD):**
  * `JA1` (`J1`): CS, `JA2` (`L2`): MISO, `JA3` (`J2`): MOSI, `JA4` (`G2`): SCK.
* **Przyciski:** `BTNU` / `BTND` (wybór utworu), `BTNC` (reset).

### 3. Płytka B (Wyjście DAC):
* **Drabinka rezystorowa R-2R (8-bit):**
  * `dac[0..3]`: Pmod JA Dolny Rząd (`G3`, `H2`, `K2`, `H1`).
  * `dac[4..7]`: Pmod JXADC (`M2`, `M1`, `N2`, `N1`).

---

## Budowanie i Programowanie

### 1. Kompilacja bitstreamu (Zdalna / Lokalna):
```bash
# Budowanie Płytki A (Streamer):
./tools/remote_build.sh board_a

# Budowanie Płytki B (DAC Receiver):
./tools/remote_build.sh board_b

# Budowanie wersji zintegrowanej (Single-Board):
./tools/remote_build.sh integrated
```

### 2. Wgrywanie do pamięci nieulotnej Flash (QSPI):
Aby układ pamiętał konfigurację po odłączeniu zasilania, należy ustawić zworkę **`JP1`** na pozycję **`QSPI`** i wgrać bitstream do pamięci flash:

```bash
# Skanowanie podłączonych płytek:
./tools/program_fpga.sh list

# Wgrywanie do pamięci Flash konkretnej płytki:
./tools/program_fpga.sh board_a <SERIAL_PLYTKI_A> -f
./tools/program_fpga.sh board_b <SERIAL_PLYTKI_B> -f
```

---

## Układ Dopasowania Sygnału Analogowego (XADC)

Aby bezpiecznie doprowadzić sygnał liniowy RCA z gramofonu/przedwzmacniacza do wejść JXADC (zakres wejściowy XADC to 0V–1V), należy zastosować układ polaryzacji składowej stałej:

| Element | Połączenie od | Połączenie do |
| :--- | :--- | :--- |
| **Kondensator** ($10\,\mu\text{F}$) | Sygnał RCA (Środek) | JXADC Pin 1 / Pin 2 (`vauxp6` / `vauxp14`) |
| **Rezystor** ($10\,\text{k}\Omega$) | JXADC Pin 1 / Pin 2 | **3.3V** (JXADC Pin 6 lub 12) |
| **Rezystor** ($2.2\,\text{k}\Omega$) | JXADC Pin 1 / Pin 2 | **GND** (JXADC Pin 5 lub 11) |
| **Przewód masy** | Masa RCA (Ekran) | JXADC Pin 7 / Pin 8 (`vauxn6` / `vauxn14`) |

Układ ten polaryzuje sygnał napięciem spoczynkowym $\approx 0.6\,\text{V}$ i chroni przetwornik ADC przed ujemnymi napięciami.

---

## Konwersja Plików Audio na Kartę SD

Do konwersji utworów do formatu bezstratnego 8-bit unsigned PCM 44.1 kHz mono służy skrypt `tools/wav_to_sd.py` lub `ffmpeg`:

```bash
# Za pomocą dedykowanego skryptu z normalizacją:
python3 tools/wav_to_sd.py input.wav output.bin

# Za pomocą ffmpeg:
ffmpeg -i input.mp3 -ar 44100 -ac 1 -f u8 track.bin
```
