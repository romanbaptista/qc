#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

GUARD_ARRAY=(
    LOG_DIR
    MODULES_DIR
    SCRIPT_ARRAY
    FASTQC_CPUS
    FASTQC_MEM_PER_CPU
    MULTIQC_CPUS
    MULTIQC_MEM_PER_CPU
    SBATCH_EXPORTS
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check run_pipeline.sh)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### LOGS ############################

LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

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
    --export="${SBATCH_EXPORTS}" \
    --cpus-per-task="${FASTQC_CPUS}" \
    --mem-per-cpu="${FASTQC_MEM_PER_CPU}" \
    --output="${LOG_DIR}/1_fastqc.%j.log" \
    "${MODULES_DIR}/1_fastqc.sh"
) || fail "  Failed to submit 1_fastqc.sh"

echo "  1_fastqc.sh SUBMITTED"
echo
echo "  SUBMITTING 2_multiqc.sh ..."

# Submit multiqc
MULTIQC=$(
    sbatch \
    --parsable \
    --export="${SBATCH_EXPORTS}" \
    --cpus-per-task="${MULTIQC_CPUS}" \
    --mem-per-cpu="${MULTIQC_MEM_PER_CPU}" \
    --dependency=afterok:"${FASTQC}" \
    --output="${LOG_DIR}/2_multiqc.%j.log" \
    "${MODULES_DIR}/2_multiqc.sh"
) || fail "  Failed to submit 2_multiqc.sh"

echo "  2_multiqc.sh SUBMITTED"

echo
echo "Pipeline SUBMITTED"
echo "${SCRIPT_NAME} COMPLETE"
echo