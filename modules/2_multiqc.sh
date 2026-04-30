#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=8GB

# Exit on error
set -euo pipefail

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh

######################### DIRECTORIES ####################

# Navigate to pipeline root path
cd "${PIPELINE_DIR}"
# Define INPUT directory
INPUT_DIR="${PIPELINE_DIR}/output/1_fastqc"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/2_multiqc"
# Create output directory
mkdir -p "${OUTPUT_DIR}"
# Create log in output folder
LOGFILE="${OUTPUT_DIR}/multiqc_log.log"
# Redirect .out/.err logs to LOGFILE
exec >"${LOGFILE}" 2>&1

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKs #########################

# Check for FASTQC output
shopt -s nullglob
FASTQC_FILES=("${INPUT_DIR}"/*_fastqc.zip)

if [[ ${#FASTQC_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No FastQC ZIP files found in ${INPUT_DIR}"
    exit 1
fi

######################### MODULES ########################

# Load conda
module load apps/anaconda-4.7.12.tcl

######################### SCRIPT #########################

echo
echo "RUNNING 2_multiqc.sh"
echo "  Input directory:    ${INPUT_DIR}"
echo "  CPUs allocated:     ${SLURM_CPUS_PER_TASK}"
echo

echo "  Checking for conda environment"

# Enable conda for non-interactive shells
eval "$(conda shell.bash hook)"
# Define environment name
CONDA_ENV="env_qc"

# Create environment if it doesn't exist
if ! conda info --envs | awk '{print $1}' | grep -qx "${CONDA_ENV}"; then
    echo
    echo "  Conda environment '${CONDA_ENV}' not found. Creating from YAML"
    conda env create -f env_qc.yaml
    echo "  Conda environment created"
fi

echo
echo "  Activating conda environment"
echo

# Activate conda environment
conda activate "${CONDA_ENV}"

# Remove PYTHONPATH from current shell to avoid cluster-wide Python settings
unset PYTHONPATH

echo "  Running multiQC"
echo

# Run multiqc
multiqc \
    -m fastqc \
    -n "${OUTPUT_DIR}/multiqc_report" \
    -f \
    "${FASTQC_FILES[@]}"

echo "  multiQC complete"
echo
echo "  Deactivating conda environment"
echo

# Deactivate conda
conda deactivate

echo "2_multiqc.sh COMPLETE"
echo