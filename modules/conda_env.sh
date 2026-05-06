#!/bin/bash
set -euo pipefail

######################### PATHS ###########################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source functions
source "${UTILS_DIR}/functions.sh"
# Source pipeline variables
source "${UTILS_DIR}/variables.sh"

######################### LOGS ############################

# Define log directory
LOG_DIR="${PIPELINE_DIR}/logs"
# Create log directory
mkdir -p "${LOG_DIR}"

# Define log file for conda_env.sh
LOG_FILE="${LOG_DIR}/conda_env.log"
# Send all echo to 'conda_env.log' file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for conda_env.sh ..."

echo
echo "  Checking for '${YAML_FILE}'"

# Check for yaml file
check_file "${YAML_FILE}" || {
    echo "  Please ensure that '${YAML_FILE}' has not been moved or deleted"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for conda..."

# Check for conda
check_command conda || {
    echo "  Please ensure conda is available"
    echo "  Exiting..."
    exit 1
}

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING conda_env.sh ..."

echo
echo "  Loading anaconda module"

# Load module
module load apps/anaconda-4.7.12.tcl

echo "  Module loaded"
echo
echo "  Checking for conda environment..."

# Enable conda in non-interactive shell
set +u
eval "$(conda shell.bash hook)"
set -u

# Check for conda environment
if conda info --envs | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
    echo "  Conda environment already exists: ${ENV_NAME}"
    exit 0
fi

echo "  Conda environment not found; creating using '${YAML_FILE}'..."

conda env create -n "${ENV_NAME}" -f "${YAML_FILE}"

echo "  Conda environment created: ${ENV_NAME}"

echo
echo "conda_env.sh COMPLETE"
echo

# Provide completion sentinel
touch "${PIPELINE_DIR}/.conda_env_ready"