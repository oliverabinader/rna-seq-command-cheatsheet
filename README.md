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

# For down-sampling 

First, get the lowest reads count between fastqs before down-sampling:
```bash
ls ./*.fastq.gz | parallel -j 20 'zcat {} | echo {} $((`wc -l`/4))' | awk '{print $2}' | sort | sed -n '1s/^/min=/p' 
```

Down-sample the fastqs such as in each condition/fastq file I have the same number of reads.
For that, create ds a "down-sampling" folder in fastq folder and down-sample all fastq files (Run this from inside the fastq folder):
```bash
mkdir ds/
ls *.fastq.gz | parallel -j 4 'seqtk sample -s1000 {} down_sample_value1 > ds/{}.fastq'
```

Check if down-sampling went well (Run this from inside ds folder).
```bash
for i in `ls *.fastq` ; do echo $(cat ${i} | wc -l)/4|bc; done 
```

Change the extension of down-sampled fastq files.
```bash
for f in *.fastq.gz.fastq; do mv -- "$f" "${f%.fastq.gz.fastq}.fastq"; done
```

---

# Download data from S3 bucket to an EC2 instance

Data folder location: s3://scrippsresearchngscore-jumpcodegenomicslab/ca_ns_0138_01_0120_0010_ordoukhanian_01_RS-SR0-01-HU0.fastqs.tar
Download the MD5 folder: s3://scrippsresearchngscore-jumpcodegenomicslab/md5/
```bash
aws s3 cp path_to_file_to_be_moved path_to_destination
```

Md5 file has an integrity value (md5 value). First, check that the tar file and the tar.md5 file have the same md5 value before proceeding to the analysis. 
By cating the tar.md5 file, you'll see its md5 value and by md5sum the tar file, you'll see its md5 value. 
You need to check that these 2 values are equal. If not, something went wrong with the download of the files.

---

# Some Bash commands

•	tmux:

To open a screen-like session in the server or the terminal:
```bash
tmux new -s session_name      
```

To see what are the available sessions:
```bash
Tmux ls
```
 
To view the session again
```bash
tmux attach -t session_name
```

To get out from the session
control+b then hit d

To kill session at any time
```bash
tmux kill-session -t session_name  
 ```

•	parallel:

How to gunzip many files in parallel?
```bash
ls *.fastq.gz | parallel -j 4 'gunzip {}'
```

•	htop:

Check if anyone else is running any processes.

•	ssh:
Connect to the server through ssh
```bash
ssh -i path_pem_file ubuntu@instance_ip
```

•	scp:

Moving from the server to local:
```bash
scp -i path_pem_file ubuntu@instance_ip:path_file_to_be_moved path_to_destination renaming_file_to_be_moved
```
Example: scp -i jumpcode-bifx.pem ubuntu@52.24.133.64:/path/to/protein-coding-genes.gtf ./

Moving from local to server:
```bash
scp -i path_pem_file path_file_to_be_moved ubuntu@instance_ip:path_to_destination
```
Example: scp -i sridhar-jumpcode.pem /path/to/protein-coding-genes.gtf ubuntu@13.52.190.191:/path/to/protein-coding-genes.gtf

Moving files between 2 instances:
```bash
scp -i path_pem_file ubuntu@instance_ip:file_to_be_moved path_to_destination
```
Example: scp -i sridhar-jumpcode.pem  ubuntu@13.52.50.144:/path/to/guide_count_metrics.txt ./
Example from 144 to 64 instance: (run this command on 64 instance)
scp -i sridhar-jumpcode.pem _(pem key of 144)_ ubuntu@13.52.50.144:/path/to/non_ALU_coverage.txt /path/to/non_clinical/
  
•	aws:

Moving things from AWS to any instance:

First open a tmux session, then run this command in it and then untar the folder, eg: tar -xvf stanPool_NE092-93_TimenTemp.tar (do that in a tmux session)
```bash
aws s3 cp path_to_file_to_be_moved path_to_destination --recursive
```
Example: aws s3 cp s3://jumpcodegenomics-public/refGenomes/hg38.protein-coding-ensembl.gtf . --recursive

Moving from any instance to AWS
```bash
aws s3 cp NE160/ s3://jumpcodegenomics-dropbox/bioinfx/project_archive/2023/QC_Experiments/NE160/ --recursive
```

•	bs:

To view a list of projects from wet lab:
```bash
bs project list (as an example, I can use the wet lab “MS076” folder)
```

To download all fastq files for instance 
```bash
bs download project -n project_name_from_wetlab -o /path/to/fastq_folder 
ls -l /path/to/fastq_folder
```

•	tar

To unzip tar.bza2 file:
```bash
tar -xvf trimmomatic-0.39-hdfd78af_2.tar.bz2
```

•	bcl

To perform demultiplexing:
```bash
/path/to/bcl-convert --bcl-input-directory 220708_A01255_0153_AHVHT5DSX2/ --sample-sheet SampleSheet.csv --output-directory /path/to/out --no-lane-splitting true
```

Installing BCL Convert:
```bash 
sudo apt-get install alien 
sudo alien --to-deb bcl-convert-4.0.3-2.el7.x86_64.rpm 
sudo dpkg -i bcl-convert_4.0.3-3_amd64.deb
```

•	dx

Parallel downloading of files from a remote data platform
```bash
dx ls | parallel -j 100 'dx download {}'
```
 
•	Split fasta sequence in different files

Install fasta-splitter: conda install -c bioconda fasta-splitter to split the 20kb bins into individual file

•	samtools

To get the total number of aligned reads:
```bash
samtools view bam | wc -l
```

To get the total number of aligned reads for a particular chromosome:
```bash
samtools view bam | grep "chromosome name" | wc -l 
```

To extract reads from bams that align say to chromosome 21:
```bash
ls *.bam | parallel -j 10 'in={} out=${in%.bam}_chr21.bam; samtools view -h $bam NC_000021.9 | samtools view -bS - > chr21/$out'
```

To get primary alignments from bam files:
```bash
ls *.bam | parallel -j 4 'bam={} file=${bam%.bam}.bam; samtools view -@20 -b -f 3 -F 2816 $bam > primary_alignments/$file'
```

•	multiqc

First, create a fastqc output folder:
```bash
mkdir fastqc_out
```
Run fastqc on fastqs
```bash
fastqc -o fastqc_out -t 6 *.gz
```
Run multiqc inside the fastq folder 
```bash
multiqc -o output_folder input_folder
```
Note: When you run multiqc on fastp files, the input folder is where the html files are and not filtered folder.

•	bedtools

To get genome coverage from the bam files: 
```bash
ls *.bam | parallel -j 20 'in={} out=${in%.bam}_genome_coverage_max.txt; bedtools genomecov -ibam $in  > max_cov_human/$out && echo "Completed genome coverage for file "$in'
```

To get gene counting for multiple BAM files:
```bash
mkdir counts/
ls *.bam | parallel -j 4 'bam={} out=${bam%.bam}.sample out1=${bam%.bam}.counts; echo $bam > counts/$out | \
bedtools coverage -a /path/to/protein-coding-ensembl.gtf -b $bam > counts/$out1 | cat counts/$out1 | cut -f 10 >> counts/$out' 
```

To get depth of coverage:
```bash
ls *.bam | parallel -j 3 'bam={} out=${bam%.bam}_cov-depth.txt; bedtools coverage -a /path/to/bed -b $bam -d > $out && echo "Completed estimating coverage depth for $bam"'
```

To get breadth of coverage:
```bash
ls *.bam | parallel -j 3 'bam={} out=${bam%.bam}_cov-breadth.txt; bedtools coverage -a /path/to/bed -b $bam > $out && echo "Completed estimating coverage breadth for $bam"'

•	fastp
```bash
ls *_R1_001.fastq.gz | parallel -j 5 'R1={} \
  R2=${R1%_R1_001.fastq.gz}_R2_001.fastq.gz \
  H=${R1%_R1_001.fastq.gz}_fastp.html \
  J=${R1%_R1_001.fastq.gz}_fastp.json; \
  fastp --in1 $R1 --in2 $R2 \
  --out1 filtered/$R1 --out2 filtered/$R2 \
  --verbose --detect_adapter_for_pe --length_required 99 \
  --html $H --json $J && echo "Completed quality filtering for $H"';
```
  
---

# Archive and Upload data to S3

This utility script is used to compress a project folder, generate a checksum, and upload the archived data to an AWS S3 bucket for long-term storage.

It ensures:
- Data reproducibility through MD5 checksum tracking
- Standardized project archiving structure
- Efficient transfer to cloud storage

## Usage

```bash
bash scripts/archive_to_s3.sh <folder_name>
```

## Output
- .tar archive of the folder
- .md5sum checksum file

You will need to upload to S3 under year-based directory structure.

Requirements:
- AWS CLI configured (aws configure)
- Write access to S3 bucket

---

# IGV plot

Filter reads from original BAM files aligning to mitochondrial genes
```bash
ls *.bam | parallel -j 10 'in={} out=${in%.bam}_mito.bam; samtools view -L GCF_000001405.39_GRCh38.p13_genomic.mito.bed -b $in -o $out && echo "Completed filtering mito reads for $in"' 
```

Index BAM files 
```bash
ls *_mito.bam | parallel -j 16 'samtools index {}'
```

Copy resulting BAM and BAI files to local PC

Go to IGV browser and upload the BAM files as tracks.
