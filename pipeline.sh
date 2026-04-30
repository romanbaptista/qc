#!/bin/bash

# Exit on error
set -euo pipefail

######################### DIRECTORIES ####################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Export pipeline root path
export PIPELINE_DIR
# Define MODULES directory path
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output"
# Create OUTPUT directory
mkdir -p "${OUTPUT_DIR}"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### CONDA ##########################

# Load anaconda on login node
module load apps/anaconda-4.7.12.tcl

# Enable conda in non-interactive shell
set +u
eval "$(conda shell.bash hook)"
set -u

# Define environment name
CONDA_ENV="env_qc"
# Define environment .yaml file path
YAML_FILE="${PIPELINE_DIR}/env_qc.yaml"

# Create environment if it doesn't exist
if ! conda info --envs | awk '{print $1}' | grep -qx "${CONDA_ENV}"; then
    echo
    echo "  Conda environment '${CONDA_ENV}' not found"
    echo "  Creating environment from ${YAML_FILE}"
    echo "  This may take 30 minutes+ the first time"
    conda env create -f "${YAML_FILE}"
    echo "  Conda environment created"
fi

######################### PIPELINE #######################

echo
echo "RUNNING qc pipeline..."
echo "User configuration from config.sh:"
echo "  Input directory:        ${INPUT_DIR}"
echo "  FASTQC threads:         ${FASTQC_CPUS}"
echo

echo "  Checking for env_qc conda environment"

echo "  env_qc found"

echo "  SUBMITTING 1_fastqc.sh"

# Submit fastqc
FASTQC=$(
    sbatch \
    --cpus-per-task="${FASTQC_CPUS}" \
    --parsable \
    "${MODULES_DIR}/1_fastqc.sh"
)

echo "  1_fastqc.sh SUBMITTED"
echo
echo "  SUBMITTING 2_multiqc.sh"

# Submit multiqc
MULTIQC=$(
    sbatch \
    --parsable \
    --cpus-per-task="${MULTIQC_CPUS}" \
    --dependency=afterok:"${FASTQC}" \
    "${MODULES_DIR}/2_multiqc.sh"
) || {
    echo "  Failed to submit 2_multiqc.sh. Exiting..."
    exit 1
}

echo "  2_multiqc.sh SUBMITTED"
echo
echo "  Pipeline submitted successfully"
echo