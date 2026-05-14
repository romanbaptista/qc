#!/bin/bash
#SBATCH --job-name=multiqc
set -euo pipefail

######################### GUARDS ##########################

# Required variables inherited via EXPORT_ARRAY + SLURM
GUARD_ARRAY=(
    FASTQC_OUTDIR
    MULTIQC_OUTDIR
    ENV_NAME
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check EXPORT_ARRAY in run_pipeline.sh)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### PATHS ###########################

# Define input directory path
SCRIPT_INDIR="${FASTQC_OUTDIR}"

######################### SOURCE ##########################

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo "  Input directory:        ${SCRIPT_INDIR}"
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
    -o "${MULTIQC_OUTDIR}" \
    -n "multiqc_report" \
    -f \
    "${SCRIPT_INDIR}"

echo "  multiQC complete"
echo
echo "  Deactivating conda environment..."

# Deactivate conda
conda deactivate

echo
echo "  Conda environment deactivated"

echo
echo "${SCRIPT_NAME} COMPLETE"
echo