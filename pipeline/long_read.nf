nextflow.enable.dsl=2
params.input_dir = "/scratch1/Masters/Arshia/akpk/data/30x_coverage"
params.fastqFiles = params.fastqFiles ?: "${params.input_dir}/*.{fastq,fastq.gz}"
params.plot_script = '/scratch1/Masters/Arshia/akpk/pipeline/histogram_copy.R'
params.plot_read_distribution = '/scratch1/Masters/Arshia/akpk/pipeline/read_distribution.R'
params.threshold_script = "/scratch1/Masters/Arshia/akpk/pipeline/threshold_long_reads_mstd.py"
params.output = "${params.input_dir}/output_dir"
params.overlap_calculator = "${params.input_dir}/overlap_calculator.py"
params.kmer_size = params.kmer_size ?: 21  

process kmerCounting {
    conda './environment.yml'
    publishDir params.output, mode:'copy'
    input:
    file fastqFiles
    
    output:
    path "kmer_db.meryl", type: "directory", emit: kmer_db
    path "histogram.txt", emit: hist_txt
    path "stats.txt", emit: stats_txt

    script:
    """
    meryl count k=${params.kmer_size} threads=15 output kmer_db.meryl ${fastqFiles}
    meryl histogram threads=15 kmer_db.meryl > histogram.txt
    meryl statistics threads=15 kmer_db.meryl > stats.txt
    """
}


process plotKmers {
    conda './environment.yml'  
    publishDir params.output, mode:'copy'
    input:
    path hist_txt
    output:
    path "histogram.png", emit: histogram

    script:
    """
    Rscript ${params.plot_script} ${hist_txt} histogram.png
    """
}


process getthreshold{
    conda './environment.yml'  
    publishDir params.output, mode:'copy'
    input:
    path "histogram.txt"
    output:
    path "threshold.txt", emit: threshold
    
    script:
    """ 
    mean=\$(awk '{ sum += \$1 * \$2; total += \$2 } END { print sum / total }' histogram.txt)
    std_dev=\$(awk -v mean=\$mean '{sum+=\$2*(\$1-mean)*(\$1-mean); total+=\$2} END {print sqrt(sum / total)}' histogram.txt)
    awk -v mean="\$mean" -v std_dev="\$std_dev" 'BEGIN {total=(mean + 2 * std_dev)} END{print total}' > threshold.txt
    """
}


process filterReadsNew {
    conda './environment.yml'
    publishDir params.output, mode: 'copy'

    input:
        path "threshold.txt"
        file fastqFiles
        path "kmer_db.meryl"

    output:

        path "above_threshold.meryl", type: "directory", emit: above_threshold
        path "merged.fastq.gz", emit: merged
        path "filtered_reads.meryl", type: "directory", emit: filtered_output
        path "merged.tsv", emit: filtered_distribution


    """
    # Read the threshold value
    thr_val=\$(cat threshold.txt)
    int_thr_val=\${thr_val%.*} 
    #echo \$int_thr_val > thr.txt

    # Generate meryl database based on threshold with multi-threading
    meryl greater-than \$int_thr_val output above_threshold.meryl kmer_db.meryl threads=15
    # Initialize counter
    count=0

    # Loop through fastq files and process them
    for file in ${fastqFiles}; do
        ((count+=1))
        val=\$count
        echo "Processing \$file" | tee /dev/stderr

        # Perform meryl lookup for each file with multi-threading
        meryl-lookup -include -sequence "\$file" -mers above_threshold.meryl -threads 15 > "filtered_\${val}.fastq"
        meryl-lookup -existence -sequence "\$file" -mers above_threshold.meryl -threads 15 > "filtered_\${val}.tsv"
        cat "filtered_\${val}.fastq" >> merged.fastq
        cat "filtered_\${val}.tsv" >> merged.tsv
    done
    meryl count k=${params.kmer_size} threads=15 output filtered_reads.meryl merged.fastq
    bgzip -@ 10 merged.fastq
    """
}

process plot_existence {
    conda './environment.yml'
    publishDir params.output, mode:'copy'
    input:
    path filtered_distribution

    output:
    path "read_distribution.pdf", emit: read_distribution


    script:
    """
    Rscript ${params.plot_read_distribution} ${filtered_distribution} read_distribution.pdf
    """
}

process extract_repetitive_reads {
    conda './environment.yml'
    publishDir params.output, mode:'copy'
    input:
    path filtered_distribution
    file fastqFiles

    output:
    path "to_keep_repeats.lst", emit: to_keep_repeats
    path "filtered.fq", emit: reads_to_run


    script:
    """
    cat ${filtered_distribution} | awk '\$4/\$2 >= 0.5{print \$1}' > to_keep_repeats.lst
    samtools fqidx ${fastqFiles} -r to_keep_repeats.lst > filtered.fq
    """
}



process runGenomeAssembly {
    conda './environment.yml'
    publishDir params.output, mode:'copy'
    input:
    path reads_to_run
    output:
    path "repeat_sequences.asm.bp.p_ctg.gfa", emit: repeat_assembly


    script:
    """
    #!/bin/bash  
    hifiasm -o repeat_sequences.asm -t 15 "${reads_to_run}"

    """
}

process convertToFasta {
    conda './environment.yml'
    publishDir params.output, mode:'copy'
    input:
    path repeat_assembly


    output:
    path "repeat_sequences.asm.bp.p_ctg.fa", emit: repeat_fasta

    script:
    """
    #gfatools gfa2fa repeat_sequences.asm.bp.p_ctg.gfa > repeat_sequences.asm.bp.p_ctg.fa
    gfatools gfa2fa ${repeat_assembly} > repeat_sequences.asm.bp.p_ctg.fa
    """

}

process k3_k1_ratio {
    conda './environment.yml'
    publishDir params.output, mode:'copy' 
    input:
    path repeat_fasta
    path stats_txt

    output:
    path "contigs_kmer_db.meryl", type: "directory", emit: contigs_kmer_db
    path "stats_contigs.txt", emit: stats_contigs
    path "k4_k1_ratio_distinct.txt"
    path "k4_k1_ratio_unique.txt"


    script:
    """
    meryl count k=${params.kmer_size} threads=15 output contigs_kmer_db.meryl ${repeat_fasta}
    meryl statistics threads=15 contigs_kmer_db.meryl > stats_contigs.txt
    k4=\$(grep "distinct" stats_contigs.txt | head -n 1 | awk '{print \$2}')
    k4_unique=\$(grep "unique" stats_contigs.txt | head -n 1 | awk '{print \$2}')
    k1=\$(grep "distinct" stats.txt | head -n 1 | awk '{print \$2}')
    k1_unique=\$(grep "unique" stats.txt | head -n 1 | awk '{print \$2}')
    ratio=\$(echo "scale=6; \$k4 / \$k1" | bc)
    echo "\$ratio" > k4_k1_ratio_distinct.txt
    ratio_unique=\$(echo "scale=6; \$k4_unique / \$k1_unique" | bc)
    echo "\$ratio_unique" > k4_k1_ratio_unique.txt
    """
}

process k3_k2_ratio {
    conda './environment.yml'
    publishDir params.output, mode:'copy' 
    input:
    path above_threshold
    path stats_contigs
    path filtered_output
    path reads_to_run

    output:
    path "stats_k2.txt"
    path "stats_k3.txt"
    path "k4_k2_ratio.txt"
    path "k4_k3_ratio.txt"
    path "k4_k2_ratio_unique.txt"
    path "k4_k3_ratio_unique.txt"
    path "reads_to_run.meryl", type: "directory", emit: extracted_reads_db
    path "stats_reads_to_run.txt"

    script:
    """
    meryl statistics threads=15 ${filtered_output} > stats_k2.txt
    meryl statistics threads=15 ${above_threshold} > stats_k3.txt
    meryl count k=${params.kmer_size} threads=15 output  reads_to_run.meryl ${reads_to_run}
    meryl statistics threads=15 reads_to_run.meryl > stats_reads_to_run.txt
    k3=\$(grep "distinct" stats_k3.txt | head -n 1 | awk '{print \$2}')
    k3_unique=\$(grep "unique" stats_k3.txt | head -n 1 | awk '{print \$2}')
    k4=\$(grep "distinct" ${stats_contigs} | head -n 1 | awk '{print \$2}')
    k4_unique=\$(grep "unique" ${stats_contigs} | head -n 1 | awk '{print \$2}')
    k2=\$(grep "distinct" stats_k2.txt | head -n 1 | awk '{print \$2}')
    k2_unique=\$(grep "unique" stats_k2.txt | head -n 1 | awk '{print \$2}')
    ratio=\$(echo "scale=6; \$k4 / \$k3" | bc)
    echo "\$ratio" > k4_k3_ratio.txt
    ratio_reads=\$(echo "scale=6; \$k4 / \$k2" | bc)
    echo \$ratio_reads > k4_k2_ratio.txt
    ratio_unique=\$(echo "scale=6; \$k4_unique / \$k3_unique" | bc)
    echo "\$ratio_unique" > k4_k3_ratio_unique.txt
    ratio_unique_reads=\$(echo "scale=6; \$k4_unique / \$k2_unique" | bc)
    echo "\$ratio_unique_reads" > k4_k2_ratio_unique.txt
    """
}

process quast {
    conda './environment.yml' // './environment.yml'
    publishDir params.output, mode:'copy' 
    input:
    path repeat_fasta

    output:
    path "quast_output", type: "directory", emit: quast_output

    script:
    """
    quast ${repeat_fasta} -o quast_output
    """
}




workflow {
    def pro = Channel.fromPath(params.fastqFiles)
    .collect() // Allows for multiple files to be passed as input all at once
    kmerCounting(pro)//Counts kmers and creates a database
    plotKmers(kmerCounting.out.hist_txt)//Creates a plot of the kmers
    getthreshold(kmerCounting.out.hist_txt)//Calculates the threshold
    filterReadsNew(getthreshold.out.threshold, pro, kmerCounting.out.kmer_db )//Filters the reads
    plot_existence(filterReadsNew.out.filtered_distribution)//Creates a plot of the read distribution
    extract_repetitive_reads(filterReadsNew.out.filtered_distribution, pro)//Extracts the repetitive reads
    runGenomeAssembly(extract_repetitive_reads.out.reads_to_run)//Runs the genome assembly
    convertToFasta(runGenomeAssembly.out.repeat_assembly)//Converts the assembly to a fasta file
    k3_k1_ratio(convertToFasta.out.repeat_fasta, kmerCounting.out.stats_txt)//Calculates the k3/k1 ratio
    k3_k2_ratio(filterReadsNew.out.above_threshold, k3_k1_ratio.out.stats_contigs, filterReadsNew.out.filtered_output, extract_repetitive_reads.out.reads_to_run)//Calculates the k3/k2 ratio
    quast(convertToFasta.out.repeat_fasta)//Runs quast

}


