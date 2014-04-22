hapmap2gds <- function (hapmap.fn, outfn.gds, nblock = 1024, compress.annotation = "ZIP.fast", option = NULL, verbose = TRUE) {
    stopifnot(is.character(hapmap.fn))
    stopifnot(is.character(outfn.gds))
    if (is.null(option)) 
        option <- snpgdsOption()
    scan.snp.sampid <- function(fn) {
        opfile <- file(fn, open = "r")
        samp.id <- NULL
        while (length(s <- readLines(opfile, n = 1)) > 0) {
            if (substr(s, 1, 3) == "rs#") {
                samp.id <- scan(text = s, what = character(0), quiet = TRUE)[-c(1:11)]
                break
            }
        }
        if (is.null(samp.id)) {
            close(opfile)
            stop("Error HapMap format: invalid sample id!")
        }
        close(opfile)
        return(samp.id)
    }
    scan.snp.marker <- function(fn) {
        if (verbose) 
            cat(sprintf("\tfile: %s\n", fn))
        Cnt <- count.fields(fn, comment.char = "")
        if (any(Cnt != Cnt[1])) 
            stop(sprintf("The file (%s) has different numbers of columns.", fn))
        line.cnt <- length(Cnt)
        col.cnt <- max(Cnt)
        if (verbose) 
            cat(sprintf("\tcontent: %d rows x %d columns\n", line.cnt, col.cnt))
        opfile <- file(fn, open = "r")
        while (length(s <- readLines(opfile, n = 1)) > 0) {
            if (substr(s, 1, 3) == "rs#") 
                break
        }
        chr <- character(line.cnt)
        position <- integer(line.cnt)
        snpidx <- integer(line.cnt)
        snp.rs <- character(line.cnt)
        snp.allele <- character(line.cnt)
        snp.cnt <- 0
        var.cnt <- 0
        while (length(s <- readLines(opfile, n = nblock)) > 0) {
            for (i in 1:length(s)) {
                var.cnt <- var.cnt + 1
                ss <- scan(text = s[i], what = character(0), quiet = TRUE)
                snp.cnt <- snp.cnt + 1
                chr[snp.cnt] <- ss[3]
                position[snp.cnt] <- as.integer(ss[4])
                snpidx[snp.cnt] <- var.cnt
                snp.rs[snp.cnt] <- ss[1]
                snp.allele[snp.cnt] <- ss[2]
            }
#           cat(".")
        }
        close(opfile)
#       cat("\n")
        chr <- chr[1:snp.cnt]
        flag <- match(chr, names(option$chromosome.code))
        chr[!is.na(flag)] <- unlist(option$chromosome.code)[flag[!is.na(flag)]]
        chr <- suppressWarnings(as.integer(chr))
        chr[is.na(chr)] <- -1
        snp.allele <- gsub(".", "/", snp.allele[1:snp.cnt], fixed = TRUE)
        list(chr = chr, position = position[1:snp.cnt], snpidx = snpidx[1:snp.cnt], snp.rs = snp.rs[1:snp.cnt], snp.allele = snp.allele)
    }
    determine.geno.code <- function(snp.allele, genotypes) {
        a <- unlist(strsplit(snp.allele, "/", fixed=TRUE))

        geno.str <- c(paste(a[1], a[1], sep = ""), paste(a[2], a[2], sep = ""), paste(a[1], a[2], sep = ""), paste(a[2], a[1], sep = ""), paste("N", "N", sep = ""))
        geno.code <- c(2, 0, 1, 1, 3)

        x <- match(genotypes, geno.str)
        x <- geno.code[x]
        x[is.na(x)] <- 3

        return(x)
    }
    scan.snp.geno <- function(fn, gGeno, start) {
        opfile <- file(fn, open = "r")
        while (length(s <- readLines(opfile, n = 1)) > 0) {
            if (substr(s, 1, 3) == "rs#") 
                break
        }
        snp.cnt <- start
        while (length(s <- readLines(opfile, n = nblock)) > 0) {
            gx <- NULL
            for (i in 1:length(s)) {
                ss <- scan(text = s[i], what = character(0), quiet = TRUE)
                x <- determine.geno.code(ss[2], ss[-c(1:11)])
                gx <- cbind(gx, x)
            }
            if (!is.null(gx)) {
              write.gdsn(gGeno, gx, start = c(1, snp.cnt), count = c(-1, ncol(gx)))
              snp.cnt <- snp.cnt + ncol(gx)
            }
#           cat(".")
        }
        close(opfile)
#       cat("\n")
        snp.cnt - start
    }
    if (verbose) {
        cat("Start HapMap2GDS ...\n")
        cat("\tScanning ...\n")
    }
    sample.id <- NULL
    for (fn in hapmap.fn) {
        s <- scan.snp.sampid(fn)
        if (!is.null(sample.id)) {
            if (length(sample.id) != length(s)) 
                stop("All SNP files should have the same sample id.")
            if (any(sample.id != s)) 
                stop("All SNP files should have the same sample id.")
        }
        else sample.id <- s
    }
    all.chr <- integer()
    all.position <- integer()
    all.snpidx <- integer()
    all.snp.rs <- character()
    all.snp.allele <- character()
    for (fn in hapmap.fn) {
        v <- scan.snp.marker(fn)
        all.chr <- c(all.chr, v$chr)
        all.position <- c(all.position, v$position)
        all.snpidx <- c(all.snpidx, v$snpidx)
        all.snp.rs <- c(all.snp.rs, v$snp.rs)
        all.snp.allele <- c(all.snp.allele, v$snp.allele)
    }
    nSamp <- length(sample.id)
    nSNP <- length(all.chr)
    if (verbose) {
        cat(date(), "\tstore sample id, snp id, position, and chromosome.\n")
        cat(sprintf("\tstart writing: %d samples, %d SNPs ...\n", nSamp, nSNP))
    }
    gfile <- createfn.gds(outfn.gds)
    add.gdsn(gfile, "sample.id", sample.id, compress = compress.annotation, closezip = TRUE)
    add.gdsn(gfile, "snp.id", as.integer(all.snpidx), compress = compress.annotation, closezip = TRUE)
    add.gdsn(gfile, "snp.rs.id", all.snp.rs, compress = compress.annotation, closezip = TRUE)
    add.gdsn(gfile, "snp.position", all.position, compress = compress.annotation, closezip = TRUE)
    v.chr <- add.gdsn(gfile, "snp.chromosome", all.chr, storage = "int32", compress = compress.annotation, closezip = TRUE)
    add.gdsn(gfile, "snp.allele", all.snp.allele, compress = compress.annotation, closezip = TRUE)
    put.attr.gdsn(v.chr, "autosome.start", option$autosome.start)
    put.attr.gdsn(v.chr, "autosome.end", option$autosome.end)
    for (i in 1:length(option$chromosome.code)) {
        put.attr.gdsn(v.chr, names(option$chromosome.code)[i], option$chromosome.code[[i]])
    }
    sync.gds(gfile)

    gGeno <- add.gdsn(gfile, "genotype", storage = "bit2", valdim = c(nSamp, nSNP))
    put.attr.gdsn(gGeno, "sample.order")
    sync.gds(gfile)
    snp.start <- 1
    for (fn in hapmap.fn) {
        if (verbose) 
            cat(sprintf("\tfile: %s\n", fn))
        s <- scan.snp.geno(fn, gGeno, start = snp.start)
        snp.start <- snp.start + s
        sync.gds(gfile)
    }
    closefn.gds(gfile)
    if (verbose) 
        cat(date(), "\tDone.\n")
    return(invisible(NULL))
}

gds2fasta <- function (gdsobj, pos.fn, snp.id = NULL, verbose = FALSE) {
    stopifnot(class(gdsobj) == "gds.class")
    stopifnot(is.character(pos.fn))

    if (verbose) 
        cat("Extract SNP data as FASTA format from GDS:\n")
    total.snp.ids <- read.gdsn(index.gdsn(gdsobj, "snp.id"))
    snp.ids <- total.snp.ids
    if (!is.null(snp.id)) {
        n.tmp <- length(snp.id)
        snp.id <- snp.ids %in% snp.id
        n.snp <- sum(snp.id)
        if (n.snp != n.tmp) 
            stop("Some of snp.id do not exist!")
        if (n.snp <= 0) 
            stop("No SNP in the working dataset.")
        snp.ids <- snp.ids[snp.id]
    }
    snp.idx <- match(snp.ids, total.snp.ids)

    rep.genotype <- read.gdsn(index.gdsn(gdsobj, "genotype"))[,snp.idx]
    rep.allele <- do.call(rbind, strsplit(read.gdsn(index.gdsn(gdsobj, "snp.allele"))[snp.idx], "/", fixed = TRUE))
    sample.id <- read.gdsn(index.gdsn(gdsobj, "sample.id"))

    id_file.name <- paste(pos.fn, ".id.txt", sep = "")
    cat(paste(read.gdsn(index.gdsn(gdsobj, "snp.rs.id"))[snp.idx], collapse = "\n"), "\n", file = id_file.name)

    seq.len <- length(snp.idx)
    file.name <- paste(pos.fn, ".fasta", sep = "")
    cat("", file = file.name) # Make a new empty file

    for (i in 1:length(sample.id)) {
        seq <- character(seq.len)
        for (j in 1:seq.len) {
            if        (rep.genotype[i,j] == 0) {
                seq[j] <- rep.allele[j,2]
            } else if (rep.genotype[i,j] == 2) {
                seq[j] <- rep.allele[j,1]
            } else {
                if        ((rep.allele[j,1] == "A" && rep.allele[j,2] == "G") || (rep.allele[j,1] == "G" && rep.allele[j,2] == "A")) {
                    seq[j] <- "R"
                } else if ((rep.allele[j,1] == "C" && rep.allele[j,2] == "T") || (rep.allele[j,1] == "T" && rep.allele[j,2] == "C")) {
                    seq[j] <- "Y"
                } else {
                    seq[j] <- "N"
                }
            }
        }
        cat(">", sample.id[i], "\n", file = file.name, sep = "", append = TRUE)
        cat(seq, "\n", file = file.name, sep = "", append = TRUE)
    }

#   if (verbose) 
#       cat("\tOutput a FASTA file DONE.\n")

    return(invisible(NULL))
}

library(getopt)

#LD Linkage Disequilibrium
#MAF Minor Allele Frequency
h <- function(x) {
    cat("Usage: Rscript --vanilla generate_snp_sequence.R -v VCF_file|-H HapMap_file|-d GDS_file [-l LD_threshold (0.5)] [-m MAF_threshold (0.05)] [-M Missing_rate (0.05)] [-o Prefix_of_output_files (output)] [-a The_number_of_the_last_autosome (22)] [-h]\n\n")
    quit(save="no", status=x)
}

opt <- getopt(matrix(c(
    'help',    'h', 0, "logical",
    'ld',      'l', 1, "double",
    'maf',     'm', 1, "double",
    'miss',    'M', 1, "double",
    'asome',   'a', 1, "integer",
    'prefix',  'o', 1, "character",
    'vcf',     'v', 1, "character",
    'hapmap',  'H', 1, "character",
    'gds',     'd', 1, "character"
), ncol=4, byrow=TRUE));

if (! is.null(opt$help)) { h(0) }

file.prefix <- ifelse(is.null(opt$prefix), "output", opt$prefix)
ld.threshold <- ifelse(is.null(opt$ld), 0.5, opt$ld)
maf.threshold <- ifelse(is.null(opt$maf), 0.05, opt$maf)
miss.rate <- ifelse(is.null(opt$miss), 0.05, opt$miss)
last.autosome <- ifelse(is.null(opt$asome), 22, opt$asome)

library(gdsfmt)
library(SNPRelate)

option = snpgdsOption(autosome.end=last.autosome)

#library(compiler)
#enableJIT(3)

if (! is.null(opt$gds)) {
    gds.file <- opt$gds
    if (! file.exists(gds.file)) { cat(sprintf("GDS file (%s) was not found!\n", gds.file)); h(1) }
} else if (! is.null(opt$vcf)) {
    vcf.file <- opt$vcf
    if (! file.exists(vcf.file)) { cat(sprintf("VCF file (%s) was not found!\n", vcf.file)); h(1) }
    gds.file <- sprintf("%s.gds", file.prefix)
    snpgdsVCF2GDS(vcf.file, gds.file, method="biallelic.only", compress.annotation="ZIP.fast")
} else if (! is.null(opt$hapmap)) {
    hapmap.file <- opt$hapmap
    if (! file.exists(hapmap.file)) { cat(sprintf("HapMap file (%s) was not found!\n", hapmap.file)); h(1) }
    gds.file <- sprintf("%s.gds", file.prefix)
    hapmap2gds(hapmap.file, gds.file, compress.annotation="ZIP.fast")
} else {
    h(1)
}

genofile <- openfn.gds(gds.file)
snpset <- snpgdsLDpruning(genofile, ld.threshold=ld.threshold, maf=maf.threshold, missing.rate=miss.rate)
snpset.id <- unlist(snpset)
gds2fasta(genofile, file.prefix, snp.id = snpset.id)
