#!/bin/bash

# check_command
# Verifies that a command is available in PATH.
# Arguments:
#   $1 - command name
# Returns:
#   0 if found
#   1 if not found (prints error to stderr)
# Example:
# check_command tmux || {
#     echo "Some extra info"
#     exit 1
# }

check_command() {
    
    local cmd="$1"

    if command -v "${cmd}" >/dev/null 2>&1; then
        echo "  SUCCESS: Command found: '${cmd}'"
        return 0
    else
        echo "  ERROR: Command not found: '${cmd}'" >&2
        return 1
    fi

}

# check_directory
# Verifies that a directory exists.
# Arguments:
#   $1 - directory path
# Returns:
#   0 if directory exists
#   1 if not found (prints error to stderr)
# Example:
# check_dir "${DIRECTORY}" || {
#     echo "Some extra info"
#     exit 1
# }

check_directory() {
    local path="$1"

    if [[ -d "${path}" ]]; then
        echo "  SUCCESS: Directory found: '${path}'"
        return 0
    else
        echo "  ERROR: Directory not found: '${path}'" >&2
        return 1
    fi
}

# check_file
# Verifies that a file exists.
# Arguments:
#   $1 - file path
# Returns:
#   0 if file exists
#   1 if not found (prints error to stderr)
# Example:
# check_file "${DIRECTORY}/${FILE}" || {
#     echo "Some extra info"
#     exit 1
# }

check_file() {
    local path="$1"

    if [[ -f "${path}" ]]; then
        echo "  SUCCESS: File found: '${path}'"
        return 0
    else
        echo "  ERROR: File not found: '${path}'" >&2
        return 1
    fi
}

# check_variable
# Verifies that a named variable is set and not empty.
# Arguments:
#   $1 - variable name (string; e.g. "BIOPROJECT")
# Operation:
#   Uses indirect expansion to retrieve the value of the variable
#   whose name is provided as the argument.
# Returns:
#   0 if the variable exists and is non-empty
#   1 if the variable is unset or empty (prints error to stderr)
# Example:
# check_variable "BIOPROJECT" || {
#     echo "Some extra info"
#     exit 1
# }

check_variable() {
    local name="$1"
    local value="${!name}"

    if [[ -n "${value}" ]]; then
        echo "  SUCCESS: Variable is set: '${name}'"
        return 0
    else
        echo "  ERROR: Variable not set or is empty: '${name}'" >&2
        return 1
    fi
}


# Verifies that a file exists and is executable.
# If the file exists but is not executable, execution permission is added.
# Arguments:
#   $1 - full path to the file to check
# Returns:
#   0 if the file exists and is executable (or was made executable)
#   1 if the file does not exist or cannot be made executable
# Example:
# check_executable "${DIRECTORY}/${FILE}" || {
#     echo "Some extra info"
#     exit 1
# }

check_executable() {
    local path="$1"

    check_file "${path}" || {
        echo "  Please ensure that file exists: '${path}'"
        return 1
    }

    if [[ -x "${path}" ]]; then
        echo "  SUCCESS: File is executable: '${path}'"
        return 0
    else
        chmod +x "${path}" || {
            echo "  ERROR: Failed to make file executable: '${path}'" >&2
            return 1
        }
        echo "  SUCCESS: Executable permission added: '${path}'"
        return 0
    fi
}