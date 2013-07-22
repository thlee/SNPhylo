import re
import sys
import os.path

def help(error_no):
    print "Remove SNP data which have many samples which have no SNP information"
    print
    print "Version: 07222013"
    print
    print "Usage:"
    print "    %s HapMap_file Maximum_%%_of_NSS_number" % os.path.basename(sys.argv[0])
    print
    print "Acronyms:"
    print "    NSS: Sample which has no SNP information"
    sys.exit(error_no)

if len(sys.argv) != 3: help(1)

hapmap_file = sys.argv[1]
max_nss_percent = float(sys.argv[2])

if not os.path.exists(hapmap_file):
    print >> sys.stderr, "HapMap file (%s) was not found!" % hapmap_file
    sys.exit(1)

num_wrong_chr_id = 0
for snp_line in open(hapmap_file, "r"):
    if snp_line[:3] == "rs#":
        max_num_nss = (len(snp_line.strip().split()) - 11) * (max_nss_percent / 100.0)
        sys.stdout.write(snp_line)
    else:
        snp_data = snp_line.strip().split()

        try:
            _ = int(snp_data[2])
        except ValueError:
            num_wrong_chr_id += 1
            continue

        genotype_data = snp_data[11:]
        if genotype_data.count('NN') < max_num_nss:
            sys.stdout.write(snp_line)

if num_wrong_chr_id > 0:
    print >> sys.stderr, "\nWarning: There were %i unreadable chromosome id%s. Identifier for a chromosome should be a number." % (num_wrong_chr_id, "s" if num_wrong_chr_id > 1 else "")
