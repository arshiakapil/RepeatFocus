args <- commandArgs(trailingOnly = TRUE)
file_path <- args[1] 
output_file <- args[2]
library(ggplot2)
mydata <- read.delim(file_path, header = FALSE, sep = "\t")
p <-ggplot(mydata, aes(x = V1, y = V2)) +
  geom_line() +
  xlim(1, 250)
ggsave(output_file, plot = p, device="png")
cat("Plot saved as", output_file, "\n")

