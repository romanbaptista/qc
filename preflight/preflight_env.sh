#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${UTILS_DIR:?UTILS_DIR not set (check PATHS section in run_pipeline.sh)}"

######################### SETUP ###########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

# Define environment name
ENV_NAME="env_qc"
# Define YAML file path
YAML_FILE="${UTILS_DIR}/env_qc.yaml"

# Define tmux code
TMUX_INJECT="set -euo pipefail; \
    export UTILS_DIR='${UTILS_DIR}'; \
    export YAML_FILE='${YAML_FILE}'; \
    export ENV_NAME='${ENV_NAME}'; \
    source '${UTILS_DIR}/functions_base.sh'; \
    source '${UTILS_DIR}/functions_env.sh'; \
    create_env '${ENV_NAME}' '${YAML_FILE}'; \
    tmux kill-session -t '${TMUX_SESSION_NAME}'"


######################## SOURCE ###########################

# Source environment functions
source "${UTILS_DIR}/functions_env.sh"

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for conda environment: ${ENV_NAME}..."

# Load module
module load apps/anaconda-4.7.12.tcl

# Enable conda in non-interactive shell
set +u
eval "$(conda shell.bash hook)"
set -u

# If environment not present
if ! check_env "${ENV_NAME}"; then
    
    # Checks
    check_variable ENV_NAME || fail "  Please ensure an environment name (ENV_NAME) is provided"
    check_file "${YAML_FILE}" || fail "  Please ensure that YAML file exists: ${YAML_FILE}"
    check_file_data "${YAML_FILE}" || fail "  Please ensure that YAML file contains data: ${YAML_FILE}"

    echo "  Conda environment not found: ${ENV_NAME}"
    echo "  Creating tmux session: ${TMUX_SESSION_NAME}..."

    # Start tmux session
    tmux new-session -d -s "${TMUX_SESSION_NAME}" \
        ${TMUX_INJECT}
    
    echo "  tmux session created: ${TMUX_SESSION_NAME}"
    echo "  To attach to the session use; 'tmux attach -t ${TMUX_SESSION_NAME}'"
    echo "  To detach again, without stopping jobs; Press Ctrl+b then d"
    echo "  To kill session, use; 'tmux kill-session -t ${TMUX_SESSION_NAME}'"
    echo "  User may disconnect from the cluster if required, while environment creation continues"
    
    # Set up timeout counter (3 hours by default)
    MAX_WAIT=10800
    WAITED=0

    # Check for sentinel file
    while ! check_file "${UTILS_DIR}/.conda_env_ready"; do

        TIME_TO_WAIT=10
        sleep ${TIME_TO_WAIT}s
        WAITED=$((WAITED + ${TIME_TO_WAIT}))

        # Check counter
        if (( WAITED >= MAX_WAIT )); then
            fail "  ERROR: Conda environment setup timed out after ${MAX_WAIT}s"
        fi
    done

    # Remove sentinel file
    rm -f "${UTILS_DIR}/.conda_env_ready"

    # Confirm creation
    check_env "${ENV_NAME}" || fail "  Conda environment creation may have failed"
fi

echo "  Conda environment found: ${ENV_NAME}"
echo "  ${SCRIPT_NAME} COMPLETE"
