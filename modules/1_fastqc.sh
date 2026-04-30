#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=8GB

# Exit on error
set -euo pipefail

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh

######################### DIRECTORIES ####################

# Navigate to pipeline root path
cd "${PIPELINE_DIR}"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/1_fastqc"
# Create output directory
mkdir -p "${OUTPUT_DIR}"
# Create log in output folder
LOGFILE="${OUTPUT_DIR}/fastqc_log.log"
# Redirect .out/.err logs to LOGFILE
exec >"${LOGFILE}" 2>&1

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKS #########################

if [[ -z "${INPUT_DIR}" || ! -d "${INPUT_DIR}" ]]; then
    echo "ERROR: INPUT_DIR is not set or does not exist: ${INPUT_DIR}"
    exit 1
fi

######################### MODULES ########################

# Load fastqc module
module load apps/fastqc-0.11.9.tcl

######################### SCRIPT #########################

echo
echo "RUNNING 1_fastqc.sh"
echo "  Input directory: ${INPUT_DIR}"
echo "  CPUs allocated: ${SLURM_CPUS_PER_TASK}"
echo

echo "  Iterating through fastq.gz files"

# Get num_threads from SLURM
NUM_THREADS="${SLURM_CPUS_PER_TASK}"

# Run fastqc
find "${INPUT_DIR}" -type f -name "*.fastq.gz" | while read -r FASTQ_FILE; do
    fastqc \
    -t "${NUM_THREADS}" \
    --noextract \
    --outdir "${OUTPUT_DIR}" \
    "${FASTQ_FILE}"
done

# # Run fastqc
# for FASTQ_FILE in "${INPUT_DIR}"/*fq.gz; do
#     fastqc \
#     -t $FASTQC_NUM_THREADS \
#     --noextract \
#     --outdir "${OUTPUT_DIR}" \
#     "${FASTQ_FILE}"
# done

echo
echo "1_fastqc.sh COMPLETE"
echo




