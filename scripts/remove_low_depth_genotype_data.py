import re
import sys
import os.path

def help(error_no):
    print "Remove VCF data which have many low depth of coverage samples"
    print
    print "Version: 10012013"
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
num_no_dp_data = 0
num_pass_wo_dp_test = 0
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

        format_col = vcf_data[8].split(':')
        format_col_len = len(format_col)

        try:
            dp_col_no = format_col.index('DP')
        except ValueError:
            dp_col_no = -1
            num_no_dp_data += 1

        num_low_depth_sample = 0
        for genotype in vcf_data[9:]: # In order to increase processing speed, several 'if' and 'continue' statements were used in this loop.
            if genotype == ".":
                num_low_depth_sample += 1
                continue

            genotype_col = genotype.split(':')
            if len(genotype_col) != format_col_len:
                num_low_depth_sample += 1
                continue

            if dp_col_no > 0:
                if genotype_col[dp_col_no] < min_depth:
                    num_low_depth_sample += 1
            else:
                num_pass_wo_dp_test += 1

        if num_low_depth_sample < max_num_low_depth_sample:
            sys.stdout.write(vcf_line)

determine_was_were = lambda x: "were" if x > 1 else "was"

if num_wrong_chr_id > 0:
    print >> sys.stderr, "\nWarning: There %s %i unreadable chromosome id%s. Identifier for a chromosome should be a number." % \
        (determine_was_were(num_wrong_chr_id), num_wrong_chr_id, "s" if num_wrong_chr_id > 1 else "")

if num_no_dp_data > 0:
    print >> sys.stderr, "\nWarning: There %s %i SNP position%s which did not have DP information." % \
        (determine_was_were(num_no_dp_data), num_no_dp_data, "s" if num_no_dp_data > 1 else "")

if num_pass_wo_dp_test > 0:
    print >> sys.stderr, "\nWarning: %i SNP%s %s passed without the read depth assessment because of the absence of the DP column." % \
        (num_pass_wo_dp_test, "s" if num_pass_wo_dp_test > 1 else "", determine_was_were(num_pass_wo_dp_test))
