# Pipeline Modules

This directory contains the implementation modules for the QC pipeline.

Each module is responsible for exactly one pipeline stage and may be safely rerun if previous outputs already exist.

Modules are executed under SLURM and coordinated by `modules/pipeline.sh`, which is submitted by `run_pipeline.sh` after all preflight checks and environment setup have completed.

# Design Contract

All modules adhere to the following principles:
- Single responsibility per script
- Explicit input and output locations
- Fail‑fast preflight checks
- Restart‑safe behavior
- Deterministic execution under SLURM
- No reliance on implicit global system state

# Execution Order

Modules are executed in the order defined for validation in `utils/variables.sh`.

The current pipeline consists of the following modules:
```text
conda_env.sh
1_fastqc.sh
2_multiqc.sh
```

Execution order and SLURM resource allocation are explicitly defined in `modules/pipeline.sh`.

# Module Overview

## `pipeline.sh`

Internal SLURM orchestrator for the QC pipeline.

### Workflow
- Sources shared configuration and utilities
- Validates the presence of all required module scripts
- Submits FastQC and MultiQC jobs with explicit SLURM resources
- Enforces strict execution order using SLURM job dependencies
- Writes high‑level pipeline output to `logs/pipeline.<jobid>.log`
- Aborts immediately if any job submission fails

`pipeline.sh` is not intended to be executed directly by end users.

## `conda_env.sh`

Creates and verifies the conda environment required for MultiQC.

### Inputs
Both inputs are pipeline constants, defined in `utils/variables.sh`
- Conda environment YAML file
- Conda environment name

### Workflow
- Validates the presence of the environment YAML file
- Loads the system anaconda module
- Initializes conda in a non‑interactive shell
- Checks whether the required environment already exists
- Creates the environment from the YAML file if missing
- Writes progress and diagnostic output to `logs/conda_env.log`
- Touches a completion sentinel file (`.conda_env_ready`) on success

### Guarantees
- Idempotent (safe to rerun)
- Does not recreate environments unnecessarily
- Does not modify global system conda installations
- Safe to run inside or outside a tmux session

## `1_fastqc.sh`

Runs FastQC on all compressed FASTQ files in the user‑specified input directory.

### Inputs
- INPUT_DIR (from `config.sh`)
- SLURM resources (defined in `pipeline.sh`)
- FastQC system module

### Workflow
- Validates the input directory and presence of .fastq.gz files
- Loads the FastQC module within the SLURM job
- Iterates through all FASTQ files
- Runs FastQC using the CPUs allocated by SLURM
- Writes all output to a dedicated stage directory

### Outputs
```text
output/1_fastqc/
├── sample1_fastqc.zip
├── sample1_fastqc.html
├── sample2_fastqc.zip
└── sample2_fastqc.html
```

Logs for this stage are written to:
```text
logs/1_fastqc.<jobid>.log
```

### Guarantees
- Safe to rerun
- Uses only SLURM‑allocated resources
- No shared state between samples beyond the output directory
- Fails if input data are missing or invalid

## `2_multiqc.sh`

Aggregates FastQC results into a consolidated MultiQC report.

### Inputs
- FastQC output directory from 1_fastqc.sh
- Pre‑existing MultiQC conda environment
- SLURM resources (defined in pipeline.sh)

### Workflow
- Validates the presence of FastQC output files
- Loads the system anaconda module
- Initializes and activates the pinned MultiQC conda environment
- Unsets cluster‑wide Python environment variables (e.g. PYTHONPATH)
- Runs MultiQC on all FastQC ZIP files
- Produces a single HTML report and associated data directory
- Cleans up any temporary files on exit

### Outputs
```text
output/2_multiqc/
├── multiqc_report.html
└── multiqc_report_data/
```

Logs for this stage are written to:
```text
logs/2_multiqc.<jobid>.log
```

### Guarantees
- Executes only after successful FastQC completion
- Deterministic aggregation of all input samples
- No modification of upstream FastQC results
- Safe to rerun if outputs already exist

# Notes
- All SLURM resource requests are centralized in pipeline.sh
- The MultiQC conda environment name is fixed by the pipeline and not user‑configurable
- Temporary files and scratch directories are cleaned up automatically
- No module requires interactive user input