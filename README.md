# READme

The goal of this project is to evaluate the recovery of repetitive sequences from low coverage datasets by developing a reproducible k-mer based filtering pipeline, RepeatFocus. The pipeline is implemented using a Nextflow v24.04.4.5917[11] system to ensure scalability, portability, and reproducibility across computing environments.

# Overview
RepeatFocus operates in modular stages, beginning with the computation of k-mer frequencies across the input dataset. High-frequency k-mers are identified based on a statistical threshold and used to construct a reference database representing candidate repetitive elements. Long reads containing an overrepresentation of these repetitive k-mers are then selectively filtered to enrich the dataset for repetitive content. This filtered subset is passed to a long-read assembler to reconstruct contigs focused specifically on repetitive regions (Figure 1).
The resulting assemblies are evaluated using standard assembly quality metrics, with particular attention to contiguity, completeness, and the accurate recovery of known repetitive elements. 
*RepeatFocus* is a k-mer filtering–based pipeline designed to enrich repeat-containing reads prior to assembly. I aim to evaluate whether selectively assembling repeat-enriched reads improves the recovery of repetitive sequences, particularly in terms of contiguity and completeness, when working with low-coverage long-read datasets.

<img width="960" height="540" alt="figure" src="https://github.com/user-attachments/assets/7b8b14d4-bbb0-4c19-ac4f-36ebcf04e1ea" />

***Figure 1:*** This figure outlines the RepeatFocus pipeline for assembling repetitive regions from low-coverage long-read sequencing data. (1) Raw long reads are processed with Meryl to generate a k-mer frequency database. (2) A statistical threshold is calculated to identify high-frequency, potentially repetitive k-mers. (3) A filtered k-mer database is created containing only k-mers above this threshold. (4) Reads containing these, more than 50% repetitive k-mers are extracted from the original dataset. (5) The extracted reads are assembled using Hifiasm. (6) Assembly quality is assessed using metrics that evaluate continuity, correctness, and completeness, with a focus on the recovery of repetitive sequences.

# WorkFlow
1. Kmer Counting
2. Filtering
3. Read Extraction
4. Read Filtering
5. Genome Assembly
6. Assembly Metrics
7. Validation Metrics
