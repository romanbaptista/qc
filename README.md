# QC Pipeline

# Overview

This repository contains the qc pipeline — a modular, SLURM‑compatible workflow for:

> Running quality control on compressed FASTQ sequencing data using FastQC and MultiQC in a reproducible, HPC‑friendly manner.

The pipeline is designed specifically for HPC environments and handles:
- Validation of user input FASTQ directories
- Automated FastQC execution across all samples
- Aggregation of QC metrics with MultiQC
- Robust conda environment setup for MultiQC
- Safe sequential job execution using SLURM dependencies
- Centralised, reproducible logging

All pipeline outputs are written to a dedicated output/ directory, enabling seamless integration with downstream workflows (trimming, alignment, variant calling, etc.).

# Repository Structure

```text
qc/
├── README.md                       # Top-level overview (this file)
├── config.sh                       # User configuration (input paths, resources)
├── run_pipeline.sh                 # Entry point (tmux + orchestration)
├── utils/                          # Shared utilities
│   ├── variables.sh                # Pipeline metadata and constants
│   └── functions.sh                # Reusable helper functions
│   └── env_qc.yaml                 # YAML file for generating conda environment
├── modules/                        # Pipeline modules (executed under SLURM)
│   ├── pipeline.sh                 # SLURM pipeline orchestrator
│   ├── conda_env.sh                # Conda environment setup for MultiQC
│   ├── 1_fastqc.sh                 # FastQC execution
│   └── 2_multiqc.sh                # MultiQC aggregation
└── output/                         # Pipeline-generated data (created at runtime)
```

# Workflow

At a high level, the QC pipeline proceeds as follows:

### Environment setup
- Verifies the presence of the required MultiQC conda environment
- Automatically creates the environment if missing, using a pinned YAML file
- Optionally performs environment creation inside a tmux session to allow safe user disconnects

### FastQC
- Submits a SLURM job to run FastQC on all `.fastq.gz` files in the user‑supplied input directory
- Uses configurable CPU and memory resources per job
- Writes per‑job and per‑sample logs for traceability

### MultiQC
- Submits a dependent SLURM job that runs only after FastQC completes successfully
- Aggregates all FastQC results into a single MultiQC report
- Produces an HTML report and associated data directory

All pipeline steps are coordinated through SLURM job dependencies to ensure deterministic, sequential execution without manual intervention.

# Configuration

All user‑tunable parameters are defined in `config.sh`.

| Variable | Description |
|--------|-------------|
| `INPUT_DIR` | Directory containing input `.fastq.gz` files to be processed by the QC pipeline |
| `TMUX_FOR_CONDA_SETUP` | Whether to use a tmux session for conda environment creation during pipeline setup |
| `TMUX_SESSION_NAME` | Name of the tmux session used for conda environment creation |
| `FASTQC_CPUS` | CPUs allocated per FastQC SLURM job |
| `FASTQC_MEM_PER_CPU` | Memory allocated per CPU for FastQC |
| `MULTIQC_CPUS` | CPUs allocated for the MultiQC SLURM job |
| `MULTIQC_MEM_PER_CPU` | Memory allocated per CPU for MultiQC |

At minimum, the user must define the input directory containing FASTQ files:

```bash
INPUT_DIR="/path/to/fastq_files"
```

All other parameters have sensible defaults and can be adjusted based on cluster policy or dataset size.

# Usage

Navigate to the folder containing the pipeline and run:

```bash
bash run_pipeline.sh
```

This will:
- Perform all preflight checks
- Verify or create the required conda environment
- Submit the QC pipeline to SLURM
- Exit cleanly after submission

If tmux is enabled for environment setup, users may safely detach and re‑attach without interrupting long‑running steps.

# Outputs

All pipeline outputs are written under `output/`, grouped by stage.

Example structure after a complete run:

```text
output/
├── 1_fastqc/
│   ├── sample1_fastqc.zip
│   ├── sample1_fastqc.html
│   ├── sample2_fastqc.zip
│   └── sample2_fastqc.html
└── 2_multiqc/
    ├── multiqc_report.html
    └── multiqc_report_data/
```

Logs are written centrally under `logs/` and include:
- `run_pipeline.log`
- `pipeline.<jobid>.log`
- `1_fastqc.<jobid>.log`
- `2_multiqc.<jobid>.log`

This structure allows failures or performance issues to be diagnosed at each stage without inspecting unrelated output.

# Further Documentation

For a detailed explanation of each pipeline module, implementation details, and SLURM submission logic, see `modules/README.md`

# Citation

If you use this pipeline in published work, please cite:

> Baptista, R. _qc: A SLURM‑compatible pipeline for FastQC and MultiQC‑based sequencing quality control_.
> GitHub repository: https://github.com/romanbaptista/qc

Optionally include the specific commit hash or release tag used for analysis.