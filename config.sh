#!/bin/bash

################################# INPUT #################################

# INPUT_DIR:
# Absolute or relative path to the directory containing input sequencing data
# for the QC pipeline.
# This directory must exist and must contain one or more compressed FASTQ files
# (e.g. *.fastq.gz). This value is used by 1_fastqc.sh only; downstream steps
# operate exclusively on pipeline-generated outputs derived from this input.
INPUT_DIR=""

######################### TMUX SETTINGS #################################

# TMUX_SESSION_NAME:
# Name of the tmux session used by the pipeline to create the MultiQC
# conda environment when required.
# This session is automatically started during preflight and allows
# environment setup to continue independently of the user's login session.
TMUX_SESSION_NAME="create_env"

######################### 1_FASTQC.SH ###################################

# FASTQC_CPUS:
# Number of CPU threads allocated per FastQC task.
# Increasing this value may improve processing performance but will increase
# per-job CPU usage.
FASTQC_CPUS=20

# FASTQC_MEM_PER_CPU:
# Amount of memory allocated per CPU thread for fastqc.
# This value is typically passed to the scheduler as memory-per-CPU
# and should be adjusted based on dataset size and cluster policy.
FASTQC_MEM_PER_CPU=8G

######################### 2_MULTIQC.SH ##################################

# MULTIQC_CPUS:
# Number of CPU threads allocated per MultiQC task.
# Increasing this value may improve performance but will increase per-job
# CPU usage (>5 is unnecessary for typical workloads).
MULTIQC_CPUS=2

# MULTIQC_MEM_PER_CPU:
# Amount of memory allocated per CPU thread for multiqc.
# This value is typically passed to the scheduler as memory-per-CPU
# and should be adjusted based on dataset size and cluster policy.
MULTIQC_MEM_PER_CPU=8G