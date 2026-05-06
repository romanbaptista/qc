#!/bin/bash
set -euo pipefail

######################### PATHS ###########################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Define modules directory
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

# Define log directory
LOG_DIR="${PIPELINE_DIR}/logs"
# Create log directory
mkdir -p "${LOG_DIR}"

# Define log file for run_pipeline.sh
LOG_FILE="${LOG_DIR}/run_pipeline.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for run_pipeline.sh ..."

echo
echo "  Checking for user defined variables..."

CONFIG_VAR=(
    INPUT_DIR
    FASTQC_CPUS
    FASTQC_MEM_PER_CPU
    MULTIQC_CPUS
    MULTIQC_MEM_PER_CPU
)

# Iterate over user variables
for variable in "${CONFIG_VAR[@]}"; do
    
    # Check for variable in config.sh
    check_variable "${variable}" || {
        echo "  Set variable in config.sh: '${variable}' "
        echo "  Exiting..."
        exit 1
    }

done

echo "  All user defined variables set"
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

echo
echo "  Checking for pipeline script..."

# Check for pipeline.sh
check_file "${MODULES_DIR}/pipeline.sh" || {
    echo "  Please ensure that pipeline.sh exists"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for tmux..."

# Check for tmux
check_command tmux || {
    echo "  Please ensure tmux is available"
    echo "  OR, if you prefer to create the conda environment without tmux"
    echo "  Set TMUX_FOR_CONDA_SETUP to 'no' in config.sh and rerun pipeline"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for conda environment..."

# Load module
module load apps/anaconda-4.7.12.tcl

# Enable conda in non-interactive shell
set +u
eval "$(conda shell.bash hook)"
set -u


if ! conda info --envs | awk '{print $1}' | grep -qx "${ENV_NAME}"; then

    echo "  Conda environment not found: ${ENV_NAME}"
    echo "  Checking TMUX_FOR_CONDA_SETUP..."

    if [[ "${TMUX_FOR_CONDA_SETUP}" == "yes" ]]; then
        
        echo "  TMUX_FOR_CONDA_SETUP = 'yes'"
        echo "  Starting tmux session: ${TMUX_SESSION_NAME}..."

        rm -f "${PIPELINE_DIR}/.conda_env_ready"

        tmux new-session -d -s "${TMUX_SESSION_NAME}" \
            "export YAML_FILE='${YAML_FILE}'; \
             export ENV_NAME='${ENV_NAME}'; \
             bash '${MODULES_DIR}/conda_env.sh'; \
             tmux kill-session -t '${TMUX_SESSION_NAME}'"
        
        echo "  Tmux session created"
        echo "  conda_env.sh script submitted"
        echo "  Waiting for script to complete..."

        # Set up timeout counter
        MAX_WAIT=10800              # 3 hours
        WAITED=0

        # Check for completion sentinel
        while ! check_file "${PIPELINE_DIR}/.conda_env_ready"; do
            # Wait 10s
            sleep 10s
            # Add to counter
            WAITED=$((WAITED + 10))
            # Check counter
            if (( WAITED >= MAX_WAIT )); then
                echo "  ERROR: Conda environment setup timed out after ${MAX_WAIT}s"
                echo "  Exiting..."
                exit 1
            fi
        done

        echo "  Conda environment created"

    else
        echo "  TMUX_FOR_CONDA_SETUP = 'no'"
        echo "  Running conda_env.sh without tmux session..."

        export YAML_FILE ENV_NAME
        bash "${MODULES_DIR}/conda_env.sh"

        echo "  Conda environment created"
    fi

fi

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING run_pipeline.sh ..."

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
        --export=PIPELINE_DIR \
        --output="${LOG_DIR}/pipeline.%j.log" \
        "${MODULES_DIR}/pipeline.sh"
) || {
    echo "  ERROR: Failed to submit pipeline.sh"
    echo "  Exiting..."
    exit 1
}

echo
echo "SLURM job ID: ${PIPELINE_JOB_ID}"
echo "Pipeline submission COMPLETE"
echo