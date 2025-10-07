set -e

REFERENCE="$3"
REPEAT_ANNOTATION="$2"
CONTIGS_FILE="$1"


BAM_ALIGNMENT_FILE="alignment.bam"
ALIGNMENT_BED_FILE="alignment.bed"
COVERAGE_DEPTH_BED="coverage_depth.bed"
COVERAGE_BREADTH_BED="coverage_breadth.bed"
RECOVERED_REPEAT_REGIONS="combined.bed"

echo "Running Alignment"
minimap2 -t 10 -x asm5 -a "$REFERENCE" "$CONTIGS_FILE" |  samtools view -hSb -@ 10 - | samtools sort -@ 10 - -o "$BAM_ALIGNMENT_FILE"


#Create a bed file from a bam file
echo "Creating a bed file"
bedtools bamtobed -i "$BAM_ALIGNMENT_FILE" > "$ALIGNMENT_BED_FILE"

# #Calculate Depth for Coverage for file
echo "Calculating Coverage"
bedtools coverage -a "$REPEAT_ANNOTATION" -b "$ALIGNMENT_BED_FILE" -d > "$COVERAGE_DEPTH_BED"

echo "Calculating Breadth Coverage"
bedtools coverage -a "$REPEAT_ANNOTATION" -b "$ALIGNMENT_BED_FILE" > "$COVERAGE_BREADTH_BED"
# #Find the regions that are the same
echo "Extracted Aligned Repeat Regions"
bedtools intersect -a "$REPEAT_ANNOTATION" -b "$ALIGNMENT_BED_FILE" -wo > "$RECOVERED_REPEAT_REGIONS"
