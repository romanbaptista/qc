#!/bin/bash

######################### VARIABLES #######################

# SCRIPT_ARRAY:
# List of module script filenames that constitute this QC pipeline.
# This array is used for presence validation and reporting only.
# It does NOT define SLURM submission order or resource allocation.
# Submission order and per-step resources are explicitly controlled
# in modules/pipeline.sh.
SCRIPT_ARRAY=(
    "1_fastqc.sh"
    "2_multiqc.sh"
)

# ENV_NAME:
# Name of the conda environment required by 2_multiqc.sh.
# This environment is created automatically from env_qc.yaml, if it does not
# already exist. The value here MUST match the environment name defined in the
# YAML file unless the environment is created manually by the user.
ENV_NAME="env_qc"

# YAML_FILE:
# Absolute path to the conda environment YAML file used to create the MultiQC
# environment. This path is resolved relative to the location of variables.sh
# to ensure correctness regardless of the current working directory or calling
# script. This value is consumed by run_pipeline.sh during environment setup.
YAML_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/utils/env_qc.yaml"