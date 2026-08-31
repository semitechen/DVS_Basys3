#!/bin/bash
#
# Load bitstream to a specific Basys3 FPGA board (SRAM or Non-Volatile QSPI Flash).
#
# Usage:
#   ./tools/program_fpga.sh list                                      (Scan connected boards)
#   ./tools/program_fpga.sh [board_a | board_b] [0 | 1]               (Program to SRAM - volatile)
#   ./tools/program_fpga.sh [board_a | board_b] <SERIAL>              (Program to SRAM by serial)
#   ./tools/program_fpga.sh [board_a | board_b] <SERIAL|INDEX> -f     (Flash to Non-Volatile QSPI memory!)
#

set -e

OFL_BIN="/opt/homebrew/bin/openFPGALoader"
if ! command -v "${OFL_BIN}" &> /dev/null; then
    OFL_BIN="openFPGALoader"
fi

# List connected boards
if [[ "$1" == "list" || "$1" == "--list" || "$1" == "scan" || "$1" == "--scan" ]]; then
    echo "=================================================="
    echo " Scanning connected USB FPGA devices..."
    echo "=================================================="
    "${OFL_BIN}" --scan-usb
    exit 0
fi

TARGET=""
DEVICE_SELECT=""
FLASH_MODE=false

for arg in "$@"; do
    if [[ "$arg" == "-f" || "$arg" == "--flash" || "$arg" == "flash" ]]; then
        FLASH_MODE=true
    elif [ -z "$TARGET" ]; then
        TARGET="$arg"
    elif [ -z "$DEVICE_SELECT" ]; then
        DEVICE_SELECT="$arg"
    fi
done

BITSTREAM_FILE=""
if [[ "$TARGET" == "board_a" || "$TARGET" == "a" || "$TARGET" == "top_board_a_streamer" ]]; then
    BITSTREAM_FILE="results/top_board_a_streamer.bit"
elif [[ "$TARGET" == "board_b" || "$TARGET" == "b" || "$TARGET" == "top_board_b_dac" ]]; then
    BITSTREAM_FILE="results/top_board_b_dac.bit"
elif [[ "$TARGET" == "integrated" || "$TARGET" == "top_dvs_basys3" ]]; then
    BITSTREAM_FILE="results/top_dvs_basys3.bit"
elif [ -n "$TARGET" ] && [ -f "$TARGET" ]; then
    BITSTREAM_FILE="$TARGET"
elif [ -f "results/top_dvs_basys3.bit" ]; then
    BITSTREAM_FILE="results/top_dvs_basys3.bit"
else
    BITSTREAM_FILE=$(find results -name "*.bit" | head -n 1)
fi

if [ -z "${BITSTREAM_FILE}" ] || [ ! -f "${BITSTREAM_FILE}" ]; then
    echo "Error: Bitstream file not found: ${BITSTREAM_FILE}"
    exit 1
fi

OFL_EXTRA_ARGS=""
if [[ "$DEVICE_SELECT" =~ ^[0-9]+$ ]] && [ ${#DEVICE_SELECT} -le 2 ]; then
    OFL_EXTRA_ARGS="--cable-index ${DEVICE_SELECT}"
    echo "Target Board Index: ${DEVICE_SELECT}"
elif [ -n "$DEVICE_SELECT" ]; then
    OFL_EXTRA_ARGS="--ftdi-serial ${DEVICE_SELECT}"
    echo "Target Board Serial: ${DEVICE_SELECT}"
fi

if [ "$FLASH_MODE" = true ]; then
    OFL_EXTRA_ARGS="${OFL_EXTRA_ARGS} -f"
    echo "Target Memory: Non-Volatile QSPI Flash (Persistent across power cycles)"
else
    echo "Target Memory: Volatile SRAM (Resets on power down)"
fi

echo "=================================================="
echo " Programming Basys3 FPGA with: ${BITSTREAM_FILE}"
echo "=================================================="

if command -v "${OFL_BIN}" &> /dev/null; then
    "${OFL_BIN}" -b basys3 ${OFL_EXTRA_ARGS} "${BITSTREAM_FILE}"
elif command -v vivado &> /dev/null; then
    vivado -mode tcl -source fpga/scripts/program_fpga.tcl -tclargs "${BITSTREAM_FILE}"
else
    echo "Error: Neither openFPGALoader nor Vivado found in PATH."
    exit 1
fi

echo "FPGA programming completed successfully!"
