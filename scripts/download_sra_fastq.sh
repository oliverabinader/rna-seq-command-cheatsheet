#!/bin/bash
 
# File containing the list of SRR accessions
SRR_LIST="SRR_Acc_List.txt"
 
# Directory to store the FASTQ files
FASTQ_DIR="./fastq"
 
# Iterate over each SRR accession in the list
while IFS= read -r sra_acc; do
  echo "Processing $sra_acc"
  
  # Run fastq-dump with the specified parameters
  fastq-dump --outdir $FASTQ_DIR --skip-technical --readids --read-filter pass --dumpbase --split-3 --clip $sra_acc
  
  echo "$sra_acc processing complete."
done < "$SRR_LIST"
 
echo "All accessions processed."
