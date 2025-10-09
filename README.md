# README

  The goal of this project is to evaluate the recovery of repetitive sequences from low coverage datasets by developing a reproducible k-mer based filtering pipeline, RepeatFocus. The pipeline is implemented using a Nextflow v24.04.4.5917[11] system to ensure scalability, portability, and reproducibility across computing environments.

# Overview 
*RepeatFocus* is a k-mer filtering–based pipeline designed to enrich repeat-containing reads prior to assembly. I aim to evaluate whether selectively assembling repeat-enriched reads improves the recovery of repetitive sequences, particularly in terms of contiguity and completeness, when working with low-coverage long-read datasets.

<img width="960" height="540" alt="figure" src="https://github.com/user-attachments/assets/7b8b14d4-bbb0-4c19-ac4f-36ebcf04e1ea" />

> ***Figure 1:*** This figure outlines the RepeatFocus pipeline for assembling repetitive regions from low-coverage long-read sequencing data. (1) Raw long reads are processed with Meryl to generate a k-mer frequency database. (2) A statistical threshold is calculated to identify high-frequency, potentially repetitive k-mers. (3) A filtered k-mer database is created containing only k-mers above this threshold. (4) Reads containing these, more than 50% repetitive k-mers are extracted from the original dataset. (5) The extracted reads are assembled using Hifiasm. (6) Assembly quality is assessed using metrics that evaluate continuity, correctness, and completeness, with a focus on the recovery of repetitive sequences.

# WorkFlow
1. PreProcessing and Optimization: Create a kmer spectra to identify repetitive kmers which are used to filter the reads based on repetitivness used for assembly.
2. Assembly: Filtered reads are assembled using a long read assembler Hifiasm.
3. Evaluation: Assembly and Validation metrics are calculated to assess the accuracy of the assembly and the recovery of repetitive content.

# Prerequisites and Setup
This workflow requires the installation of several software packages. We have created a configuration file(yml) that can be activated using conda. Since Nextflow has been selected as the workflow management system, its installation is required prior to running the RepeatFocus pipeline. 
```
conda env create -f environment.yml
```
If required, these are the necessary packages that can be installed directly on your computer:

```
 conda install -c conda-forge r-base
 conda install bioconda::meryl
 conda install bioconda::hifiasm
```

# Running
Run nextflow on the command line with the -with-conda and -with-report features to ensure smooth running of the pipeline and to create assembly metrics in the <usage file\> specified by you.
```
nextflow run long_read.nf -with-conda -with-report <input directory> <usage file>
```
# Validation
To evaluate whether the RepeatFocus pipeline effectively recovers repetitive sequences from low-coverage datasets, a series of validation metrics were calculated. These metrics were designed to assess both the presence and completeness of repetitive elements in the assembled contigs across varying coverage depths(Follow wiki page to understand how to retrieve subsampled data). Validation metrics include:
* Breadth of coverage
* Depth of Coverage
* Total recovered size of repeats
* Composition of recovered repeats in comparison to reference

The human genome was selected for validation due to its extensive study over the past two decades and the availability of detailed annotations, particularly for repetitive regions. The CHM13 assembly was chosen as it expands upon the GRCh38 reference by completing previously unresolved regions of the genome. However, if you choose to use your own data for validation, the pipeline will still work.

To run the validation pipeline you will need 3 inputs, a reference genome, a repeat annotation file, and the contigs generated from the RepeatFocus assembly pipeline.
```
validation.sh <contigs file> <reference genome> <repeat annotation file>
```
