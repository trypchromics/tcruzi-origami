args <- commandArgs(trailingOnly = TRUE)

# Read input data file: GFF and multiblast result.
gffFile <- read.table(args[1], sep = "\t")
blastnResult <- read.table(args[2], sep = "\t")
min_length_percent <- as.numeric(args[3])
experiment <- args[4]

# Compute the length.
length <- gffFile[,5] - gffFile[,4]

# Minimum computation.
minLength <- min(length)

# Selecting only those lines that have at least percent_below_min the size of the minimum entity
# annotated at GFF file.
blastnResult
blastnResult_filteredByLength_index <- (blastnResult[,7] >= (min_length_percent * minLength))

blastnResult_filtered <- blastnResult[blastnResult_filteredByLength_index,]

output_filename <- paste("output/", experiment, "/3-", experiment, "-blastFiltering.tsv", sep = "")
write.table(blastnResult_filtered, output_filename, sep = "\t", col.names = FALSE, row.names = FALSE, quote = FALSE)
