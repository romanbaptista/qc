#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --ntasks=1
set -euo pipefail

######################### PATHS ###########################

# Navigate to pipeline root path (exported from pipeline.sh)
cd "${PIPELINE_DIR}"
# Define utils directory path
UTILS_DIR="${PIPELINE_DIR}/utils"
# Define INPUT directory path
FASTQC_DIR="${PIPELINE_DIR}/output/1_fastqc"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/2_multiqc"
# Create output directory
mkdir -p "${OUTPUT_DIR}"

######################### SOURCE ##########################

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh
# Source pipeline variables
source "${UTILS_DIR}/variables.sh"
# Source configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 2_multiqc.sh ..."

echo
echo "  Checking for input directory containing fastqc output..."

# Check for input directory
if [[ -z "${FASTQC_DIR}" || ! -d "${FASTQC_DIR}" ]]; then
    echo "  ERROR: FASTQC_DIR is not set or does not exist: '${FASTQC_DIR}'"
    echo "  Exiting..."
    exit 1
fi

echo "  Input directory found: '${FASTQC_DIR}'"
echo
echo "  Checking for FASTQC output files..."

# Check for FASTQC output
shopt -s nullglob
FASTQC_FILES=("${FASTQC_DIR}"/*_fastqc.zip)

if [[ ${#FASTQC_FILES[@]} -eq 0 ]]; then
    echo "  ERROR: No FastQC ZIP files found in ${FASTQC_DIR}"
    echo "  Exiting..."
    exit 1
fi

echo "  FASTQC output found"
echo
echo "  Checking for conda environment..."

# Load module
module load apps/anaconda-4.7.12.tcl

# Enable conda in non-interactive shell
set +u
eval "$(conda shell.bash hook)"
set -u

# Check if env is present
if ! conda info --envs | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
    echo "  ERROR: Conda environment '${ENV_NAME}' not found."
    echo "  run_pipeline.sh should have created this environment"
    echo "  Exiting..."
    exit 1
fi

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING 2_multiqc.sh ..."
echo "  Input directory:        ${FASTQC_DIR}"
echo "  Conda environment:      ${ENV_NAME}"
echo "  CPUs allocated:         ${SLURM_CPUS_PER_TASK}"
echo "  Memory per CPU:         ${SLURM_MEM_PER_CPU}"

echo
echo "  Activating conda environment..."

# Activate conda environment
conda activate "${ENV_NAME}"

echo "  Conda environment activated"

# Remove PYTHONPATH from current shell to avoid cluster-wide Python settings
unset PYTHONPATH

# Define temporary directory path
export TEMP_DIR="${OUTPUT_DIR}/.tmp"
# Generate temporary directory path
mkdir -p "${TEMP_DIR}"

# Ensure temporary directory is cleaned up on exit (success or failure)
trap 'rm -rf "${TEMP_DIR}"' EXIT

echo
echo "  Running multiQC..."

# Run multiqc
multiqc \
    -m fastqc \
    -o "${OUTPUT_DIR}" \
    -n "multiqc_report" \
    -f \
    "${FASTQC_FILES[@]}"

echo "  multiQC complete"
echo
echo "  Deactivating conda environment..."

# Deactivate conda
conda deactivate

echo
echo "  Conda environment deactivated"

echo
echo "2_multiqc.sh COMPLETE"
echo