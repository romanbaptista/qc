#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${INPUT_DIR:?INPUT_DIR not set (check config.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking input directory: ${INPUT_DIR}..."

# Check input directory
check_directory "${INPUT_DIR}" || fail "  Please provide an INPUT_DIR in config.sh that exists"

echo "  Input directory confirmed: ${INPUT_DIR}"
echo "  Checking for compressed FASTQ files..."

# Check for compressed FASTQ files
if ! find "${INPUT_DIR}" -type f -name "*.fastq.gz" | grep -q .; then
    fail "  ERROR: No .fastq.gz files found in '${INPUT_DIR}'"
fi

echo "  FASTQ files found"
echo "  ${SCRIPT_NAME} COMPLETE"