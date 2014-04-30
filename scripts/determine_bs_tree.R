library(getopt)

h <- function(x) {
    cat("Usage: Rscript --vanilla draw_unrooted_tree.R -i Newick_file_name -p phylip_file_name [-n Number_of_BS_samples] [-o Prefix_of_output_files (output)] [-h]\n\n")
    quit(save="no", status=x)
}

opt <- getopt(matrix(c(
    'help',   'h', 0, "logical",
    'prefix', 'o', 1, "character",
    'newick', 'i', 1, "character",
    'phylip', 'p', 1, "character",
    'num_bs', 'n', 1, "integer"
), ncol=4, byrow=TRUE));

if (! is.null(opt$help)) { h(0) }

file.prefix <- ifelse(is.null(opt$prefix), "output", opt$prefix)

if (! is.null(opt$newick)) {
    newick.file <- opt$newick
    if (! file.exists(newick.file)) { cat(sprintf("Newick file (%s) was not found!\n", newick.file)); h(1) }
} else {
    h(1)
}

if (! is.null(opt$phylip)) {
    phylip.file <- opt$phylip
    if (! file.exists(phylip.file)) { cat(sprintf("Phylip file (%s) was not found!\n", phylip.file)); h(1) }
} else {
    h(1)
}

num.bs_sample <- 100
if (! is.null(opt$num_bs)) {
    num.bs_sample <- opt$num_bs
    if (num.bs_sample < 10 || num.bs_sample > 10000) {printf("The number of BS samples value should be between 10 and 10000\n"); h(1)}
}

library(phangorn)

bs_image_file.name <- paste(file.prefix, ".bs.png", sep = "")
bs_tree_file.name  <- paste(file.prefix, ".bs.tree", sep = "")

phylip <- read.phyDat(phylip.file, format="phylip", type="DNA")
newick <- read.tree(newick.file)

fit <- pml(newick, phylip)
#fit <- optim.pml(fit, TRUE)

set.seed(1)
bs <- bootstrap.pml(fit, bs = num.bs_sample, optNni=TRUE, multicore=TRUE)
png(filename = bs_image_file.name, width = 1000, height = 1000)
options(warn=-1)
bs_tree <- plotBS(fit$tree, bs, cex = 1, edge.width = 2)
options(warn=0)
dev.off()
write.tree(bs_tree, file = bs_tree_file.name)
