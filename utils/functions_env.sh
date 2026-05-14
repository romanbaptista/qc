#!/bin/bash

# check_env
# Checks whether a conda environment exists.
#
# Arguments:
#   $1 - Name of the conda environment to check
#
# Operation:
#   - Validates that the environment name argument is non-empty.
#   - Queries available conda environments using `conda info --envs`.
#   - Searches for an exact match to the provided environment name.
#   - Emits informational messages indicating whether the environment exists.
#
# Returns:
#   0 if the environment exists
#   1 if the environment does not exist
#
# Example:
#   check_env "env_qc"
check_env() {
    local env_name="$1"

    check_arg "${env_name}"

    if conda info --envs | awk '{print $1}' | grep -qx "${env_name}"; then
        echo "  Conda environment already exists: ${env_name}"
        return 0
    else
        echo "  Conda environment not found: ${env_name}"
        return 1
    fi
}

# create_env
# Creates a conda environment from a YAML definition file.
#
# Arguments:
#   $1 - Name of the conda environment to create
#   $2 - Path to the YAML file defining the environment
#
# Operation:
#   - Validates that both the environment name and YAML file path are non-empty.
#   - Executes `conda env create` using the provided name and YAML file.
#   - Emits informational messages describing the creation process.
#   - Creates a sentinel file (`.conda_env_ready`) in UTILS_DIR upon successful completion.
#
# Returns:
#   0 if the environment is created successfully
#   Non-zero if the conda environment creation fails
#
# Example:
#   create_env "env_qc" "/path/to/env_qc.yaml"
create_env() {
    local env_name="$1"
    local yaml_file="$2"

    check_arg "${env_name}"
    check_arg "${yaml_file}"

    echo "  Creating conda environment ${env_name} from ${yaml_file}..."
    conda env create -n "${env_name}" -f "${yaml_file}"
    echo "  Conda environment created: ${env_name}"
    touch "${UTILS_DIR}/.conda_env_ready"
}