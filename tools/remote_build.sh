#!/bin/bash
#
# Sync local working tree (including uncommitted changes) to remote AGH lab machine and compile Vivado bitstream.
# Usage: 
#   ./tools/remote_build.sh [board_a | board_b] [PORT]
#   ./tools/remote_build.sh [PORT] [board_a | board_b]
#

set -e

PORT="10035"
TARGET_MODULE="top_board_a_streamer"

for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        PORT="$arg"
    elif [[ "$arg" == "board_a" || "$arg" == "top_board_a_streamer" || "$arg" == "a" ]]; then
        TARGET_MODULE="top_board_a_streamer"
    elif [[ "$arg" == "board_b" || "$arg" == "top_board_b_dac" || "$arg" == "b" ]]; then
        TARGET_MODULE="top_board_b_dac"
    elif [[ "$arg" == "integrated" || "$arg" == "top_dvs_basys3" ]]; then
        TARGET_MODULE="top_dvs_basys3"
    fi
done

REMOTE_USER_HOST="kjelonek@149.156.107.197"
REMOTE_DIR="~/DVS_Basys3_build"

CM_DIR="${HOME}/.ssh/cm_sockets"
mkdir -p "${CM_DIR}"
CM_SOCKET="${CM_DIR}/cm-%r@%h:%p"

SSH_OPTS="-p ${PORT} -C -c aes128-ctr -o HostKeyAlgorithms=+ssh-rsa -o BatchMode=yes -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath=${CM_SOCKET} -o ControlPersist=60s"
if [ -f "${HOME}/.ssh/id_ed25519" ]; then
    SSH_OPTS="${SSH_OPTS} -i ${HOME}/.ssh/id_ed25519"
fi

SSH_CMD="ssh ${SSH_OPTS}"

echo "=================================================="
echo " Syncing workspace to remote lab machine..."
echo " Target: ${REMOTE_USER_HOST}:${REMOTE_DIR} (Port: ${PORT})"
echo " Building Top Module: ${TARGET_MODULE}"
echo "=================================================="

rsync -avz \
    -e "${SSH_CMD}" \
    --exclude='.git/' \
    --exclude='.DS_Store' \
    --exclude='pcb/production/' \
    --exclude='pcb/dvs-backups/' \
    --exclude='fpga/build/' \
    --exclude='results/' \
    ./ "${REMOTE_USER_HOST}:${REMOTE_DIR}/"

echo "=================================================="
echo " Running Vivado build on remote machine for ${TARGET_MODULE}..."
echo "=================================================="

${SSH_CMD} "${REMOTE_USER_HOST}" "bash -l -c '
    cd ${REMOTE_DIR}
    if type module >/dev/null 2>&1; then module load vivado 2>/dev/null || true; fi
    for vpath in /tools/Xilinx/Vivado/*/settings64.sh /opt/Xilinx/Vivado/*/settings64.sh /tools/Xilinx/*/settings64.sh; do
        if [ -f \"\$vpath\" ]; then source \"\$vpath\"; break; fi
    done
    source env.sh 2>/dev/null || true
    rm -rf fpga/build results
    mkdir -p results
    cd fpga
    TOP_MODULE=${TARGET_MODULE} vivado -mode batch -source scripts/generate_bitstream.tcl
    cd ..
    find fpga/build -name \"*.bit\" -exec cp {} results/top_dvs_basys3.bit \; 2>/dev/null || true
    find fpga/build -name \"*.bit\" -exec cp {} results/${TARGET_MODULE}.bit \; 2>/dev/null || true
    find fpga/build -name \"*.bin\" -exec cp {} results/${TARGET_MODULE}.bin \; 2>/dev/null || true
    find fpga/build -name \"*.bin\" -exec cp {} results/top_dvs_basys3.bin \; 2>/dev/null || true
    ./tools/warning_summary.sh 2>/dev/null || true
'"

echo "=================================================="
echo " Fetching build artifacts (bitstream & logs)..."
echo "=================================================="

mkdir -p results
rsync -avz \
    -e "${SSH_CMD}" \
    "${REMOTE_USER_HOST}:${REMOTE_DIR}/results/" ./results/

echo "=================================================="
echo " Remote build complete! Bitstream: results/${TARGET_MODULE}.bit"
echo "=================================================="
