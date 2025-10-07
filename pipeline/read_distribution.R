# Load library
library(ggplot2)

# Read command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if correct number of arguments provided
if (length(args) != 2) {
  stop("Usage: Rscript read_distribution.R <input_file> <output_pdf_path>")
}

input_file <- args[1]
output_pdf <- args[2]

# Read the 4th column from the input file
data <- read.table(input_file, sep="\t", header=FALSE)[[4]]

# Plot histogram
plot_hist <- ggplot(data.frame(value = data), aes(x = value)) +
  geom_histogram(binwidth = 100) +
  geom_vline(xintercept = c(100, 1000, 2000, 3000, 4000, 5000, 10000))

# Save to PDF
pdf(output_pdf)
print(plot_hist)
dev.off()

# Print summary stats
print(summary(data))


