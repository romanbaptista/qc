#!/bin/bash

################################# INPUT #################################

# INPUT_DIR:
# Absolute or relative path to the directory containing input sequencing data
# for the QC pipeline.
# This directory must exist and must contain one or more compressed FASTQ files
# (e.g. *.fastq.gz). This value is used by 1_fastqc.sh only; downstream steps
# operate on pipeline-generated outputs rather than this directory directly.
INPUT_DIR=""

######################### TMUX SETTINGS #################################

# TMUX_FOR_CONDA_SETUP:
# Whether run_pipeline.sh should use a tmux session when creating the MultiQC
# conda environment, if it does not already exist.
# This setting affects ONLY the environment creation step executed on the login
# node before any SLURM jobs are submitted. It has no effect on SLURM jobs or
# runtime behaviour. Set to "no" to perform environment creation directly in the
# current shell (default: "yes").
TMUX_FOR_CONDA_SETUP="yes"


# TMUX_SESSION_NAME:
# Name of the tmux session used to create the conda environment.
# Using a named session allows users to safely disconnect from the HPC
# while long-running steps (e.g., downloads) continue uninterrupted.
TMUX_SESSION_NAME="create_env"

######################### 1_FASTQC.SH ###################################

# FASTQC_CPUS:
# Number of CPU threads allocated per fastqc task.
# Increasing this value can improve conversion speed but will increase
# per-job CPU usage.
FASTQC_CPUS=20

# FASTQC_MEM_PER_CPU:
# Amount of memory allocated per CPU thread for fastqc.
# This value is typically passed to the scheduler as memory-per-CPU
# and should be adjusted based on dataset size and cluster policy.
FASTQC_MEM_PER_CPU=8G

######################### 2_MULTIQC.SH ##################################

# MULTIQC_CPUS:
# Number of CPU threads allocated per multiqc task.
# Increasing this value can improve conversion speed but will increase
# per-job CPU usage (>5 is unecessary).
MULTIQC_CPUS=2

# MULTIQC_MEM_PER_CPU:
# Amount of memory allocated per CPU thread for multiqc.
# This value is typically passed to the scheduler as memory-per-CPU
# and should be adjusted based on dataset size and cluster policy.
MULTIQC_MEM_PER_CPU=8G