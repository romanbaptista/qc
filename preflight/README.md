# `preflight`
This directory contains the preflight validation layer for the `fastq-qc` pipeline.

Preflight scripts are responsible for all validation and environment checks required to safely execute the pipeline on an HPC system before any SLURM jobs are submitted.

No pipeline modules are executed unless all preflight checks succeed.

All preflight scripts are sourced and executed by `run_pipeline.sh` on the login node, ensuring that pipeline execution begins only after the environment, configuration, and inputs are fully validated.

# Design Contract
All preflight scripts adhere to the following principles:
- Fail‑fast validation before any pipeline execution
- No side effects beyond controlled, deterministic environment setup
- Clear, actionable error messages on failure
- Deterministic behavior with explicit ordering
- Validation only — no execution or data processing logic
- Centralized enforcement of pipeline invariants
- Strict use of canonical arrays (`PREFLIGHT_ARRAY`, `COMMAND_ARRAY`, `VARIABLE_ARRAY`)

Once preflight validation completes successfully, downstream scripts may assume:
- All required configuration variables are valid and non‑empty
- All required commands and tools are available and usable
- Input data is present and correctly structured
- Required directories exist and are writable
- The MultiQC conda environment is available and correctly configured
- Execution modules can safely run without any further validation

# Responsibilities of Preflight
The preflight layer ensures that:
- User configuration is complete and non‑empty
- Input directory structure is valid and contains FASTQ data
- Pipeline module scripts exist and are non‑empty
- Required external commands are available
- The MultiQC conda environment exists or is created deterministically
- Environment setup is reproducible and restart‑safe

This prevents late‑stage failures, wasted cluster resources, and partially executed pipelines caused by missing dependencies or invalid inputs.

# Preflight Script Overview
The set and execution order of all preflight scripts is centrally defined in:

```text
utils/arrays.sh  → PREFLIGHT_ARRAY
```

`preflight/preflight.sh` sources and executes each script listed in `PREFLIGHT_ARRAY`.

# Current preflight order
```text
preflight_input.sh
preflight_variables.sh
preflight_scripts.sh
preflight_commands.sh
preflight_env.sh
```

All scripts are executed sequentially and share a single shell environment.

## `preflight_input.sh`
Validates pipeline input data.

### Responsibilities
- Confirms `INPUT_DIR` is defined and non‑empty
- Verifies that `INPUT_DIR` exists
- Recursively confirms presence of `.fastq.gz` files

This script enforces the pipeline’s input contract, ensuring that valid FASTQ data is available before execution begins.

## `preflight_variables.sh`
Validates required user‑defined configuration variables.

### Responsibilities
- Confirms all variables listed in `VARIABLE_ARRAY` are defined and non‑empty

These variables originate from `config.sh` and are later exported as part of the execution ABI.

## `preflight_scripts.sh`
Validates pipeline module integrity.

### Responsibilities
- Confirms all scripts listed in `SCRIPT_ARRAY` exist under `modules/`
- Verifies that each script is non‑empty
- Confirms presence and integrity of `modules/pipeline.sh`

This ensures that execution modules are present and valid before any job submission.

## `preflight_commands.sh`
Validates required framework‑level external commands.

### Responsibilities
- Confirms availability of all commands listed in `COMMAND_ARRAY`
- Uses strict `PATH`‑based validation

Commands validated include:
- SLURM submission (`sbatch`)
- Shell environment (`bash`)
- Conda environment management (`conda`)
- Module system (`module`)
- QC tools (`fastqc`, `multiqc`)
- Core filesystem and text-processing utilities

This step guarantees that all required external dependencies are available before execution.

## `preflight_env.sh`
Validates and ensures the MultiQC conda environment.

### Responsibilities
- Checks whether the required conda environment exists
- Validates the associated YAML definition file
- Creates the environment deterministically if missing
- Executes environment creation in a tmux session to allow non-blocking execution
- Uses a sentinel file to synchronise environment creation
- Enforces a timeout to prevent indefinite hangs
- Confirms environment availability after creation

This script defines all environment‑level invariants required for downstream execution.

# Execution Model
All preflight scripts are:
- Executed on the login node
- Sourced into a single shell for shared context
- Run in a strictly defined order
- Terminated immediately on failure

The pipeline does not proceed unless all preflight scripts complete successfully.

# Invariants Guaranteed After Preflight
After successful preflight validation, downstream pipeline stages may assume:
- All configuration variables are defined and valid
- Input directory contains valid FASTQ data
- Required framework-level commands are available
- The MultiQC conda environment exists and is functional
- Module scripts exist and contain executable code
- Execution ABI (`EXPORT_ARRAY`) is complete and correctly defined

This contract ensures a clean and strict separation between validation and execution throughout the `fastq-qc` pipeline.

# Notes
- Preflight scripts are not intended to be run directly by end users
- Conda environment creation is deterministic and restart‑safe
- All validation logic is centralized in this directory
- Execution modules do not repeat validation checks
- Arrays (`PREFLIGHT_ARRAY`, `COMMAND_ARRAY`, `VARIABLE_ARRAY`) define the canonical validation surface
- Any modification to configuration, inputs, or pipeline structure requires rerunning preflight