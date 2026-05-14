#!/bin/bash
set -euo pipefail

######################### SETUP ##########################

# Define pipeline name
PIPELINE_NAME="fastq-qc"
# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### PATHS ###########################

# Define directory paths
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${PIPELINE_DIR}/modules"
PREFLIGHT_DIR="${PIPELINE_DIR}/preflight"
UTILS_DIR="${PIPELINE_DIR}/utils"
LOG_DIR="${PIPELINE_DIR}/logs"
OUTPUT_DIR="${PIPELINE_DIR}/output"
FASTQC_OUTDIR="${OUTPUT_DIR}/1_fastqc"
MULTIQC_OUTDIR="${OUTPUT_DIR}/2_multiqc"

# Define directories to create
DIR_ARRAY=(
    LOG_DIR
    OUTPUT_DIR
    FASTQC_OUTDIR
    MULTIQC_OUTDIR
)

# Create directories
for dir in "${DIR_ARRAY[@]}"; do
    mkdir -p "${!dir}"
done

######################### SOURCE ##########################

# Source scripts
source "${PIPELINE_DIR}/config.sh"
source "${UTILS_DIR}/functions_base.sh"
source "${UTILS_DIR}/arrays.sh"

######################### LOGS ############################

# Define log file for this script
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### EXPORTS #########################

# Iterate over items to export
for var in "${EXPORT_ARRAY[@]}";do
    export "${var}"
done

# Snapshot EXPORT_ARRAY
SBATCH_EXPORTS="$(IFS=,; echo "${EXPORT_ARRAY[*]}")"
export SBATCH_EXPORTS

######################### CHECKS ##########################

echo
echo "PREFLIGHT for ${PIPELINE_NAME} ..."

source "${PREFLIGHT_DIR}/preflight.sh"

echo
echo "Preflight COMPLETE"
echo "Moving to main execution"

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  User configuration:"
echo "      Input directory:                    ${INPUT_DIR}"
echo "      FASTQC CPUs allocated per task:     ${FASTQC_CPUS}"
echo "      FASTQC memory per CPU:              ${FASTQC_MEM_PER_CPU}"
echo "      MULTIQC conda environment:          ${ENV_NAME}"
echo "      MULTIQC CPUs allocated per task:    ${MULTIQC_CPUS}"
echo "      MULTIQC memory per CPU:             ${MULTIQC_MEM_PER_CPU}"

echo
echo "  Scripts to be executed:"

for script in "${SCRIPT_ARRAY[@]}"; do
    echo "      ${script}"
done

echo
echo "  Submitting pipeline to SLURM..."

PIPELINE_JOB_ID=$(
    sbatch \
        --parsable \
        --export="${SBATCH_EXPORTS}" \
        --output="${LOG_DIR}/pipeline.%j.log" \
        "${MODULES_DIR}/pipeline.sh"
) || fail "  ERROR: Failed to submit pipeline.sh"

echo
echo "Pipeline Job ID: ${PIPELINE_JOB_ID}"
echo "${SCRIPT_NAME} COMPLETE"
echo