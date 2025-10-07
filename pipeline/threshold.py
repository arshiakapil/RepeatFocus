import subprocess
import sys
import numpy as np
import math
from scipy.signal import find_peaks
def get_genome_length(fasta_file):
    result = subprocess.run(['seqkit', 'stats', fasta_file], capture_output=True, text=True)
    length = result.stdout.splitlines()[1].split()[4]
    return length 


def get_threshold(txt_file,genome_length):
    kmers = []
    counts = []
    total_coverage = 0
    num_kmers = 0
    # Open the file in read mode ('r')
    with open(txt_file, 'r') as f:
        for line in f:
            # Split the line into kmer and count
            kmers.append(line.split()[0])
            count = int(line.split()[1])
            counts.append(count)
            total_coverage += count
    
            num_kmers += 1
    kmer_counts = np.array(counts)
    
    weighted_mean = total_coverage / num_kmers
    weighted_variance_sum = 0
    for i in range(num_kmers):
        diff = counts[i] - weighted_mean
        weighted_variance_sum += counts[i] * diff**2
    weighted_variance = weighted_variance_sum / total_coverage
    mean_coverage = total_coverage / num_kmers
    weighted_std_dev = math.sqrt(weighted_variance)
    return  (2 *weighted_std_dev + mean_coverage)

if __name__ == "__main__":
    txt_file = sys.argv[1]
    fasta_file = sys.argv[2]
    genome_length = get_genome_length(fasta_file)
    threshold = get_threshold(txt_file, genome_length)

    print(threshold)