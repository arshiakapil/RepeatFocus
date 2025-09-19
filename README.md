# READme

*RepeatFocus* is a k-mer filtering–based pipeline designed to enrich repeat-containing reads prior to assembly. I aim to evaluate whether selectively assembling repeat-enriched reads improves the recovery of repetitive sequences, particularly in terms of contiguity and completeness, when working with low-coverage long-read datasets.
# Overview
<img width="960" height="540" alt="figure" src="https://github.com/user-attachments/assets/7b8b14d4-bbb0-4c19-ac4f-36ebcf04e1ea" />

***Figure 1:*** This figure outlines the RepeatFocus pipeline for assembling repetitive regions from low-coverage long-read sequencing data. (1) Raw long reads are processed with Meryl to generate a k-mer frequency database. (2) A statistical threshold is calculated to identify high-frequency, potentially repetitive k-mers. (3) A filtered k-mer database is created containing only k-mers above this threshold. (4) Reads containing these, more than 50% repetitive k-mers are extracted from the original dataset. (5) The extracted reads are assembled using Hifiasm. (6) Assembly quality is assessed using metrics that evaluate continuity, correctness, and completeness, with a focus on the recovery of repetitive sequences.
