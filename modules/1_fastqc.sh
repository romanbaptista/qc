#!/bin/bash
#SBATCH --job-name=fastqc
set -euo pipefail

######################### GUARDS ##########################

# Required variables inherited via EXPORT_ARRAY + SLURM
GUARD_ARRAY=(
    INPUT_DIR
    FASTQC_OUTDIR
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check EXPORT_ARRAY in run_pipeline.sh)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE ##########################

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Info:"
echo "      Input directory:    ${INPUT_DIR}"
echo "      CPUs allocated:     ${SLURM_CPUS_PER_TASK}"
echo "      Memory per CPU:     ${SLURM_MEM_PER_CPU}"

echo
echo "  Loading fastqc module..."

# Load fastqc module
module load apps/fastqc-0.11.9.tcl

echo "  fastqc loaded"
echo
echo "  Iterating through fastq.gz files..."

# Get num_threads from SLURM
NUM_THREADS="${SLURM_CPUS_PER_TASK}"

# Run fastqc
while read -r FASTQ_FILE; do
    fastqc \
        -t "${NUM_THREADS}" \
        --noextract \
        --outdir "${FASTQC_OUTDIR}" \
        "${FASTQ_FILE}"
done < <(find "${INPUT_DIR}" -type f -name "*.fastq.gz")

echo
echo "${SCRIPT_NAME} COMPLETE"
echo