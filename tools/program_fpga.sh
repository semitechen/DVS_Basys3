#!/bin/bash
#
# Load a bitstream to a Xilinx FPGA using openFPGALoader or Vivado
# Run from the project root directory.

BITSTREAM_FILE=$(find results -name "*.bit" | head -n 1)

if [ -z "$BITSTREAM_FILE" ]; then
    echo "Error: No .bit file found in results/"
    exit 1
fi

echo "Found bitstream: $BITSTREAM_FILE"

if command -v /opt/homebrew/bin/openFPGALoader &> /dev/null; then
    echo "Programming Basys3 FPGA via openFPGALoader..."
    /opt/homebrew/bin/openFPGALoader -b basys3 "$BITSTREAM_FILE"
elif command -v openFPGALoader &> /dev/null; then
    echo "Programming Basys3 FPGA via openFPGALoader..."
    openFPGALoader -b basys3 "$BITSTREAM_FILE"
elif command -v vivado &> /dev/null; then
    echo "Programming Basys3 FPGA via Vivado..."
    vivado -mode tcl -source fpga/scripts/program_fpga.tcl -tclargs "$BITSTREAM_FILE"
else
    echo "Error: Neither openFPGALoader nor Vivado found in PATH."
    exit 1
fi

echo "FPGA programming completed successfully!"
