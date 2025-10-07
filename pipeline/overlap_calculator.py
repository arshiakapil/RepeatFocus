import pandas as pd
import sys

filtered_file = sys.argv[1]
contig_kmers_file = sys.argv[2]
output_file = "kmer_overlap_metrics.txt"  # Auto-generated output file name
filtered_kmers = pd.read_csv(filtered_file, sep='\\t', header=None, names=['kmer', 'freq'])
contig_kmers = pd.read_csv(contig_kmers_file, sep='\\t', header=None, names=['kmer', 'freq'])
merged = pd.merge(filtered_kmers, contig_kmers, on='kmer', how='inner', suffixes=('_original', '_filtered'))

# Calculate overlap metrics
total_kmers_filtered = filtered_kmers['kmer'].nunique()
total_kmers_contig = contig_kmers['kmer'].nunique()
overlap_kmers = merged['kmer'].nunique()
overlap_fraction = overlap_kmers / total_kmers_filtered

# Write results
with open(output_file, 'w') as f:
    f.write(f'Total k-mers in filtered genome: {total_kmers_filtered}\\n')
    f.write(f'Total k-mers in contig genome: {total_kmers_contig}\\n')
    f.write(f'Overlap k-mers: {overlap_kmers}\\n')
    f.write(f'Overlap fraction: {overlap_fraction:.4f}\\n')