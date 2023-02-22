import re
import sys
import os.path

from itertools import groupby, chain
from operator import itemgetter

def help(error_no):
    print("Convert simple SNP data file to HapMap format", file=sys.stderr)
    print(file=sys.stderr)
    print("Version: 10112013", file=sys.stderr)
    print(file=sys.stderr)
    print("Usage:", file=sys.stderr)
    print("    %s Simple_SNP_data_file" % os.path.basename(sys.argv[0]), file=sys.stderr)
    print(file=sys.stderr)
    print("Simple SNP Data File Format:", file=sys.stderr)
    print("#Chrom\tPos\tRef\tSample_ID1\tSample_ID2\t...", file=sys.stderr)
    print("1\t1000\tA\tA\tT\t...", file=sys.stderr)
    print("1\t1002\tG\tC\tG\t...", file=sys.stderr)
    print("...", file=sys.stderr)
    print("2\t2000\tG\tC\tG\t...", file=sys.stderr)
    print("2\t2002\tA\tA\tT\t...", file=sys.stderr)
    print("...", file=sys.stderr)
    sys.exit(error_no)

if len(sys.argv) != 2: help(1)

simple_file = sys.argv[1]

def determine_alleles(simple_data):
    base2allele = {"A": "AA", "C": "CC", "G": "GG", "T": "TT", "R": "AG", "Y": "CT", "K": "GT", "M": "AC", "S": "CG", "W": "AT"} 
    alleles = []
    genotype_data = []
    for simple_datum in simple_data:
        if simple_datum in base2allele:
            allele = base2allele[simple_datum.upper()]
            genotype_data.append(allele)
            alleles.append(list(allele))
        else:
            genotype_data.append("NN")

    # Tried to implement without dictionary data type as an experiment
    alleles = "/".join(sorted(zip(*sorted([(base, len(list(base_group))) for base, base_group in groupby(sorted(chain(*alleles)))], key=itemgetter(1), reverse=True))[0][:2]))
    if len(alleles) == 1:
        alleles = alleles + "/" + alleles

    return alleles, genotype_data

rs_num = 1
for line in open(simple_file, "r"):
    simple_data = line.strip().split()
    if simple_data[0].upper() == "#CHROM":
        print("rs#\talleles\tchrom\tpos\tstrand\tassembly#\tcenter\tprotLSID\tassayLSID\tpanelLSID\tQCcode\t" + \
            "\t".join(simple_data[2:]))
        continue

    alleles, genotype_data = determine_alleles(simple_data[2:])

    try:
        chrom = int(simple_data[0])
    except ValueError:
        print("The Chromosome ID should be choromosome number.\n", file=sys.stderr)
        help(1)

    try:
        pos = int(simple_data[1])
    except ValueError:
        print("The Position should be number.\n", file=sys.stderr)
        help(1)

    print(("rs%08i\t%s\t%i\t%i\t.\tNA\tNA\tNA\tNA\tNA\tNA\t" % (rs_num, alleles, chrom, pos)) + "\t".join(genotype_data))
    rs_num += 1
