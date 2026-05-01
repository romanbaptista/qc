#!/bin/bash

######################### DIRECTORIES ####################

# Define FASTQ.gz input directory
INPUT_DIR=""

######################### 1_FASTQC.SH ####################

# Define number of threads to use in FASTQC
FASTQC_CPUS=20
# Define memory per thread
FASTQC_MEM_PER_CPU=8G

######################### 2_MULTIQC.SH ####################

# Define number of threads to use in MULTIQC (>5 is unecessary)
MULTIQC_CPUS=2
# Define memory per thread
MULTIQC_MEM_PER_CPU=8G
