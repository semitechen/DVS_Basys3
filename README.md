# DVS_Basys3

Digital Vinyl System implementation on the Basys3 FPGA board.

## XADC Analog Connections

To safely connect an RCA line-level signal (2V p-p, centered at 0V) to the Basys3 JXADC header, the following conditioning circuit is required for each channel (Left/Right):

| Component | Connection From | Connection To |
| :--- | :--- | :--- |
| **Capacitor** ($10\mu\text{F}$) | RCA Signal (Center) | JXADC Pin 1 / Pin 2 (`vauxp6` / `vauxp14`) |
| **Resistor** ($10\text{k}\Omega$) | JXADC Pin 1 / Pin 2 | **3.3V** (JXADC Pin 6 or 12) |
| **Resistor** ($2.2\text{k}\Omega$) | JXADC Pin 1 / Pin 2 | **GND** (JXADC Pin 5 or 11) |
| **Direct Wire** | RCA Ground (Outer) | JXADC Pin 7 / Pin 8 (`vauxn6` / `vauxn14`) |

**Technical Note:** The Artix-7 XADC input range is 0V-1V. The circuit above biases the signal to ~0.6V and provides high-pass coupling to protect the FPGA from negative voltages.
