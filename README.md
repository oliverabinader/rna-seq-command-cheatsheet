# RNA-Seq Command Cheat Sheet

A collection of commonly used Linux, Bash, and NGS utility commands for bulk RNA-seq preprocessing, quality assessment, and gene annotation processing.

## Overview

This repository serves as a reference guide for frequently used command-line operations during RNA-seq data analysis. The commands included here support common preprocessing and quality control tasks performed before alignment and downstream analyses.

## Topics Covered

- FASTQ file inspection
- Sample and file counting
- Sequencing depth assessment
- Read length calculations
- FASTQ lane concatenation
- Gene annotation extraction
- Protein-coding gene filtering

## Requirements

The commands in this repository may require the following tools:

- Bash
- GNU Parallel
- awk
- grep
- sed
- bc
- gzip
- SeqFu

---

# Count FASTQ Files

Returns the total number of compressed FASTQ files in a sequencing experiment.

```bash
ls -l | awk '{print $9}' | grep ".gz" | wc -l
```

---

# Count Biological Samples

Assumes paired-end sequencing data where each sample contains an R1 and R2 FASTQ file.

```bash
ls -l | awk '{print $9}' | grep ".gz" | echo `wc -l`/2 | bc
```

---

# Calculate Read Counts per FASTQ File

Generates read counts for each FASTQ file using GNU Parallel.

```bash
ls *.fastq.gz | parallel -j 20 'zcat {} | echo {} $((`wc -l`/4))' | cut -d'/' -f2 | sort -n -t ':' > readsCount.txt
```

Alternative using SeqFu:

```bash
seqfu count *.fastq.gz | sort -n -t ':' > read_counts.txt
```

---

# Find Minimum Sequencing Depth

Identifies the lowest read count across all FASTQ files, which can be useful when planning downsampling analyses.

```bash
awk '{print $2}' readsCount.txt | sort | sed -n '1s/^/min=/p'
```

---

# Calculate Average Read Length

Computes the average read length for each FASTQ file.

```bash
for file in *.fastq.gz
do
    zcat "$file" | awk '
    {
        if(NR%4==2)
        {
            count++
            bases += length
        }
    }
    END
    {
        print bases/count
    }'
done | sort | uniq
```

---

# Extract Protein-Coding Gene Coordinates from an Ensembl GTF

Extracts:

- Ensembl Gene ID
- Gene Symbol
- Start Coordinate
- End Coordinate
- Gene Length

```bash
cat protein-coding-genes.gtf | awk '{print $10" "$14" "$4" "$5}' | awk '{$5 = ($4-$3); print}' > genes.txt
```

---

# Concatenate Sequencing Lanes

Combines multiple sequencing lanes into a single paired-end FASTQ set.

```bash
for name in *.fastq.gz
do
    printf '%s\n' "${name%_*_R[12]*}"
done | uniq | while read prefix
do
    zcat "$prefix"*R1*.fastq.gz > "${prefix}_R1_001.fastq"
    zcat "$prefix"*R2*.fastq.gz > "${prefix}_R2_001.fastq"
done
```

Compress concatenated files:

```bash
ls *fastq | parallel -j 4 'gzip {}'
```

---

# Count Protein-Coding Genes from a RefSeq GTF

Counts the number of protein-coding genes present in a RefSeq annotation file.

```bash
cat GCF_000001405.39_GRCh38.p13_genomic.gtf | \
grep -v "^#" | \
grep "protein_coding" | \
awk '{if ($3 =="gene") print $0}' | \
wc -l
```

---

for downsampling 
•	Down sample the fastqs such as in each condition/fastq file I have the same number of reads. For that, create ds a "down-sampling" folder in fastq folder and move all fastq files in ds folder. (Run this command from fastq folder)
Command: 
ls *.fastq.gz | parallel -j 4 'seqtk sample -s1000 {} down_sample_value1 > ds/{}.fastq'
•	Check if down-sampling went well. (Run this command from ds folder)
Command: 
for i in `ls *.fastq` ; do echo $(cat ${i} | wc -l)/4|bc; done 
