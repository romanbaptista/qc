# `utils`
This directory contains shared utility functions used by the `fastq-qc` pipeline.

The scripts in `utils/` provide reusable, strictly validated helper functions that support:
- Preflight validation
- Conda environment setup and verification
- Defensive error handling
- Deterministic pipeline behavior under strict Bash execution
- Canonical definition of pipeline structure and execution ABI

Utility scripts are sourced by `run_pipeline.sh` and preflight scripts.

Execution modules do not depend on utility functions and instead operate solely on the defined execution ABI.

# Design Contract
All utility scripts adhere to the following principles:
- Pure helper logic only (no pipeline orchestration)
- Safe operation under `set -euo pipefail`
- Explicit, readable control flow
- Clear and actionable error messages
- No reliance on implicit environment state
- No modification of global system settings
- Portable across HPC environments
- Canonical definition of pipeline structure via arrays

Utility functions are stateless and rely entirely on arguments and inherited environment variables.

# Utility Script Overview
```text
arrays.sh
functions_base.sh
functions_env.sh
```

Each utility script serves a narrow, well‑defined purpose and is designed to be reused across multiple pipeline stages.

## `arrays.sh`
Defines the canonical structure and execution contract of the pipeline.

### Responsibilities
Defines ordered lists of:
- Preflight scripts (`PREFLIGHT_ARRAY`)
- Execution modules (`SCRIPT_ARRAY`)
- Execution ABI (`EXPORT_ARRAY`)
- Required external commands (`COMMAND_ARRAY`)
- Required user configuration variables (`VARIABLE_ARRAY`)

### Guarantees
- Provides a single source of truth for pipeline structure
- Ensures consistent validation and execution ordering
- Defines the complete set of pipeline‑owned variables propagated across SLURM boundaries
- Enforces strict separation between pipeline configuration, validation, and execution

### Design Notes
- `EXPORT_ARRAY` defines the execution ABI and must not be modified downstream
- `SBATCH_EXPORTS` is derived from this array and used for controlled propagation across SLURM boundaries
- Variables used exclusively within preflight (e.g. environment setup constants) are intentionally excluded

## `functions_base.sh`
Provides core validation and helper functions used throughout the pipeline.

### Responsibilities
- Validates files, directories, variables, and commands
- Enforces non-empty configuration values
- Provides consistent error handling and messaging
- Guards against common Bash failure modes

### Functions

| Function | Purpose |
|---------|---------|
| `check_file` | Confirms that a regular file exists |
| `check_file_data` | Confirms that a file exists and is non-empty |
| `check_directory` | Confirms that a directory exists |
| `check_variable` | Confirms that a named variable is set and non-empty |
| `check_command` | Confirms that a command is available in `PATH` |
| `check_executable` | Confirms that a file exists and is executable |
| `check_arg` | Confirms that required function arguments are provided |
| `fail` | Prints an error message and terminates execution |
| `make_executable` | Adds executable permissions to a file |
| `write_env` | Generates environment files for tool configuration |
| `get_directory` | Resolves the directory of a given path |
| `get_parent_directory` | Resolves the parent directory of a path |

These functions are used extensively by preflight scripts to enforce pipeline invariants before SLURM job submission.

## `functions_env.sh`
Provides conda environment‑specific helper functions for validation and creation.

### Responsibilities
- Checks for the existence of the required conda environment
- Creates the environment deterministically from a YAML definition
- Signals completion of environment setup via a sentinel file
- Supports reproducible and restart-safe environment initialization

### Functions

| Function | Purpose |
|---------|---------|
| `check_env` | Verifies that a conda environment exists |
| `create_env` | Creates a conda environment from a YAML definition |

### Design Notes
- Environment creation is triggered only during preflight
- The environment name and YAML file are owned by the preflight layer
- A sentinel file (`.conda_env_ready`) is used to coordinate asynchronous environment creation within `tmux`
- All environment creation is deterministic and repeatable

# Usage
Utility scripts are not intended to be executed directly; they must be sourced where required.

- `arrays.sh` is sourced by `run_pipeline.sh` and `preflight.sh`
- `functions_base.sh` is sourced by `run_pipeline.sh`, preflight scripts and environment setup logic
- functions_env.sh is sourced by `preflight_env.sh` and tmux-based environment setup session

Execution modules do not source utility scripts and instead rely only on variables defined in the execution ABI.

# Error Handling
All utility functions are designed to:
- Fail immediately on invalid input
- Emit concise, context-aware error messages
- Prevent execution from progressing in an unsafe state

This ensures that failures occur early, during validation, rather than during compute job execution.

# Notes
- Utility functions intentionally duplicate no validation logic found elsewhere
- All path resolution is handled at the pipeline entrypoint (`run_pipeline.sh`)
- Functions make no assumptions about SLURM execution context
- Environment setup is deterministic and restart-safe
- Arrays define the canonical pipeline structure and must remain immutable
- Any addition of new pipeline modules or validation steps must be reflected in `arrays.sh`