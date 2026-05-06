#!/bin/bash
set -euo pipefail

######################### PATHS ###########################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# Export pipeline root path
export PIPELINE_DIR
# Define MODULES directory path
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source pipeline variables
source "${UTILS_DIR}/variables.sh"
# Source functions
source "${UTILS_DIR}/functions.sh"

######################### LOGS ############################

# Create LOG directory
LOG_DIR="${PIPELINE_DIR}/logs"
mkdir -p "${LOG_DIR}"

# Define log file for pipeline.sh
LOG_FILE="${LOG_DIR}/pipeline.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for pipeline.sh ..."

echo
echo "  Checking for module scripts..."

# Iterate over scripts
for script in "${SCRIPT_ARRAY[@]}"; do
    
    # Check if script exists
    check_file "${MODULES_DIR}/${script}" || {
        echo "  Please ensure pipeline script is present in 'modules/': '${script}'"
        echo "  Exiting..."
        exit 1
    }

    # Check that script is not pipeline.sh
    if [[ "${script}" == "pipeline.sh" ]]; then
        echo "  ERROR: pipeline.sh must not be listed in array.sh"
        echo "  Exiting..."
        exit 1
    fi

done

echo "  All scripts found"
echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING pipeline.sh ..."

echo
echo "  Scripts to be executed:"

for script in "${SCRIPT_ARRAY[@]}"; do
    echo "      ${script}"
done

echo
echo "  Pipeline starting..."

echo "  SUBMITTING 1_fastqc.sh ..."

# Submit fastqc
FASTQC=$(
    sbatch \
    --parsable \
    --cpus-per-task="${FASTQC_CPUS}" \
    --mem-per-cpu="${FASTQC_MEM_PER_CPU}" \
    --output="${LOG_DIR}/1_fastqc.%j.log" \
    "${MODULES_DIR}/1_fastqc.sh"
) || {
    echo "  Failed to submit 1_fastqc.sh"
    echo "  Exiting..."
    exit 1
}

echo "  1_fastqc.sh SUBMITTED"
echo
echo "  SUBMITTING 2_multiqc.sh ..."

# Submit multiqc
MULTIQC=$(
    sbatch \
    --parsable \
    --cpus-per-task="${MULTIQC_CPUS}" \
    --mem-per-cpu="${MULTIQC_MEM_PER_CPU}" \
    --dependency=afterok:"${FASTQC}" \
    --output="${LOG_DIR}/2_multiqc.%j.log" \
    "${MODULES_DIR}/2_multiqc.sh"
) || {
    echo "  Failed to submit 2_multiqc.sh"
    echo "  Exiting..."
    exit 1
}

echo "  2_multiqc.sh SUBMITTED"

echo
echo "Pipeline SUBMITTED"
echo