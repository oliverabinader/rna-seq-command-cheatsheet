#!/bin/bash

set -euo pipefail

########################################################
# Archive folder and upload to S3
########################################################

# Usage:
# bash scripts/archive_to_s3.sh <folder>

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>archive_log.out 2>&1

########################################################
# CONFIGURATION
########################################################

S3_BUCKET="s3://your-bucket-name/project_archive/"
DESTINATION="${S3_BUCKET}$(date +%Y)/"

FOLDER=$1

if [ -z "$FOLDER" ]; then
    echo "Error: No folder provided"
    exit 1
fi

########################################################
# TAR FOLDER
########################################################

echo "Archiving folder: $FOLDER"

TAR_FILE="${FOLDER%/}.tar"
MD5_FILE="${FOLDER%/}.md5sum"

tar cvf "$TAR_FILE" "$FOLDER"

########################################################
# CHECKSUM
########################################################

md5sum "$TAR_FILE" >> "$MD5_FILE"

########################################################
# UPLOAD TO S3
########################################################

echo "Uploading to S3..."

aws s3 cp "$TAR_FILE" "$DESTINATION"
aws s3 cp "$MD5_FILE" "$DESTINATION"

########################################################
# CLEANUP
########################################################

rm "$TAR_FILE"

echo "Archiving complete!"
