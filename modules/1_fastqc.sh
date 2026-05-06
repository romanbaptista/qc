#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --ntasks=1
set -euo pipefail

######################### PATHS ###########################

# Navigate to pipeline root path (exported from pipeline.sh)
cd "${PIPELINE_DIR}"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/1_fastqc"
# Create output directory
mkdir -p "${OUTPUT_DIR}"

######################### SOURCE ##########################

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh
# Source configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 1_fastqc.sh ..."

echo
echo "  Checking for input directory..."

# Check for input directory
if [[ -z "${INPUT_DIR}" || ! -d "${INPUT_DIR}" ]]; then
    echo "  ERROR: INPUT_DIR is not set or does not exist: '${INPUT_DIR}'"
    echo "  Exiting..."
    exit 1
fi

echo "  Input directory found: '${INPUT_DIR}'"
echo
echo "  Checking for FASTQ files in input directory..."

# Check for FASTQ files
if ! find "${INPUT_DIR}" -type f -name "*.fastq.gz" | grep -q .; then
    echo "  ERROR: No .fastq.gz files found in '${INPUT_DIR}'"
    echo "  Exiting..."
    exit 1
fi

echo "  FASTQ files found"

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING 1_fastqc.sh ..."

echo
echo "  User configuration:"
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
        --outdir "${OUTPUT_DIR}" \
        "${FASTQ_FILE}"
done < <(find "${INPUT_DIR}" -type f -name "*.fastq.gz")

echo
echo "1_fastqc.sh COMPLETE"
echo