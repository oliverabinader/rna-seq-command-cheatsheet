#!/bin/bash

# Script: upload_fastq_aspera.sh
# Description:
# Upload FASTQ files (*.fastq.gz) to NCBI dbGaP using IBM Aspera (ascp)
# for secure, high-speed data transfer.

set -euo pipefail

#############################################
# Configuration
#############################################

# Aspera authentication token
# Set this before running:
# export ASPERA_SCP_PASS="<YOUR_ASPERA_TOKEN>"
if [[ -z "${ASPERA_SCP_PASS:-}" ]]; then
    echo "Error: ASPERA_SCP_PASS environment variable is not set."
    exit 1
fi

# Directory containing FASTQ files
FASTQ_DIR="/path/to/fastq_directory"

# Aspera SSH private key
ASPERA_KEY="/path/to/aspera_tokenauth_id_rsa"

# NCBI dbGaP Aspera submission endpoint
ASPERA_DEST="asp-dbgap@gap-submit.ncbi.nlm.nih.gov:protected"

# Transfer settings
TRANSFER_RATE="200m"


#############################################
# Move to FASTQ directory
#############################################

cd "$FASTQ_DIR"


#############################################
# Upload FASTQ files
#############################################

for F in ./*.fastq.gz
do
    if [[ -f "$F" ]]; then
        echo "Uploading: $F"

        ascp \
            -I "$ASPERA_KEY" \
            -Q \
            -l "$TRANSFER_RATE" \
            -k 1 \
            "$F" \
            "$ASPERA_DEST"

        echo "Completed: $F"
    else
        echo "No FASTQ files found."
    fi
done


echo "FASTQ upload completed successfully."
