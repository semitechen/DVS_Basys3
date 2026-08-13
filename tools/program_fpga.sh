#!/bin/bash
#
# Load bitstream to Basys3 FPGA.
# Uses openFPGALoader directly on macOS, or Vivado TCL on remote Linux.
# Run from project root directory.
#

set -e

BITSTREAM_FILE=$(find results -name "*.bit" | head -n 1)

if [ -z "${BITSTREAM_FILE}" ]; then
    echo "Error: No .bit bitstream file found in results/."
    exit 1
fi

echo "Found bitstream: ${BITSTREAM_FILE}"

if command -v openFPGALoader >/dev/null 2>&1; then
    echo "Programming Basys3 FPGA via openFPGALoader..."
    openFPGALoader -b basys3 "${BITSTREAM_FILE}"
elif command -v vivado >/dev/null 2>&1; then
    echo "Programming Basys3 FPGA via Vivado..."
    vivado -mode tcl -source fpga/scripts/program_fpga.tcl -tclargs "${BITSTREAM_FILE}"
else
    echo "Error: Neither openFPGALoader nor Vivado found in PATH."
    exit 1
fi

echo "FPGA programming completed successfully!"
