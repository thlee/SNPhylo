import re
import sys
import os.path

def help(error_no):
    print "Remove VCF data which have many low depth of coverage samples"
    print
    print "Version: 05132013"
    print
    print "Usage:"
    print "    %s VCF_file Maximum_%%_of_LCS_number Minimum_depth_of_coverage" % os.path.basename(sys.argv[0])
    print
    print "Acronyms:"
    print "    LCS: Low Coverage Sample"
    sys.exit(error_no)

if len(sys.argv) != 4: help(1)

vcf_file = sys.argv[1]
max_lcs_percent = float(sys.argv[2])
min_depth = int(sys.argv[3])

if not os.path.exists(vcf_file):
    print >> sys.stderr, "VCF file (%s) was not found!" % vcf_file
    sys.exit(1)

num_wrong_chr_id = 0
for vcf_line in open(vcf_file, "r"):
    if vcf_line[0] == "#":
        sys.stdout.write(vcf_line)
        if vcf_line[:6] == "#CHROM":
            max_num_low_depth_sample = (len(vcf_line.strip().split()) - 9) * (max_lcs_percent / 100.0)
    else:
        vcf_data = vcf_line.strip().split()

        try:
            _ = int(vcf_data[0])
        except ValueError:
            num_wrong_chr_id += 1
            continue

        dp_col_no = vcf_data[8].split(':').index('DP')
        genotype_data = vcf_data[9:]
        num_low_depth_sample = len([y for y in [x.split(':') for x in genotype_data] if int(y[dp_col_no]) < min_depth])
        if num_low_depth_sample < max_num_low_depth_sample:
            sys.stdout.write(vcf_line)

if num_wrong_chr_id > 0:
    print >> sys.stderr, "\nWarning: There were %i unreadable chromosome id%s. Identifier for a chromosome should be the chromosome number." % (num_wrong_chr_id, "s" if num_wrong_chr_id > 1 else "")
