#!/usr/bin/env bash

VERSION="20180901"

# Declare functions
print_help_and_exit () {
    echo -e "Determine phylogenetic tree based on SNP data with a VCF, a HapMap, a Simple SNP or a GDS file" 1>&2
    echo 1>&2
    echo -e "Version: ${VERSION}" 1>&2
    echo 1>&2
    echo -e "Usage:" 1>&2
    echo -e "\t$(basename $0) -v VCF_file [-p Maximum_PLCS (5)] [-c Minimum_depth_of_coverage (5)]|-H HapMap_file [-p Maximum_PNSS (5)]|-s Simple_SNP_file [-p Maximum_PNSS (5)]|-d GDS_file [-l LD_threshold (0.1)] [-m MAF_threshold (0.1)] [-M Missing_rate (0.1)] [-o Outgroup_sample_name] [-P Prefix_of_output_files (snphylo.output)] [-b [-B The_number_of_bootstrap_samples (100)]] [-a The_number_of_the_last_autosome (22)] [-t The_number_of_cores_used (1)] [-r] [-A] [-h]" 1>&2
    echo 1>&2
    echo -e "Options:" 1>&2
    echo -e "\t-A: Perform multiple alignment by MUSCLE" 1>&2
    echo -e "\t-b: Perform (non-parametric) bootstrap analysis and generate a tree" 1>&2
    echo -e "\t-h: Show help and exit" 1>&2
    echo -e "\t-r: Skip the step removing low quality data (-p and -c option are ignored)." 1>&2
    echo 1>&2
    echo -e "Acronyms:" 1>&2
    echo -e "\tPLCS: The percent of Low Coverage Sample" 1>&2
    echo -e "\tPNSS: The percent of Sample which has no SNP information" 1>&2
    echo -e "\tLD: Linkage Disequilibrium" 1>&2
    echo -e "\tMAF: Minor Allele Frequency" 1>&2
    echo 1>&2
    echo -e "Simple SNP File Format:" 1>&2
    echo -e "\t#Chrom\tPos\tSampleID1\tSampleID2\tSampleID3\t..." 1>&2
    echo -e "\t1\t1000\tA\tA\tT\t..." 1>&2
    echo -e "\t1\t1002\tG\tC\tG\t..." 1>&2
    echo -e "\t..." 1>&2
    echo -e "\t2\t2000\tG\tC\tG\t..." 1>&2
    echo -e "\t2\t2002\tA\tA\tT\t..." 1>&2
    echo -e "\t..." 1>&2
    [ -n "$2" ] && echo -e "\n$2" 1>&2
    exit $1
}

## Initialize variables
# BASE_DIR=$(dirname $(readlink -f "$0")) # readlink in Mac OS X does not support the '-f' option
BASE_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPTS_DIR="${BASE_DIR}/scripts"

source "${BASE_DIR}/snphylo.cfg"

if [ ! -z "${R_LIBS_DIR}" ]
then
    if [ -z "${R_LIBS}" ]
    then
        export R_LIBS="${R_LIBS_DIR}"
    else
        export R_LIBS="${R_LIBS_DIR}:${R_LIBS}"
    fi
fi

# In order to use Pypy instead of Python
PYPY="$(which pypy 2> /dev/null | tail -n1 | tr -d '\t')"
[ ! -z "${PYPY}" ] && PYTHON="${PYPY}"

vcf_file=""
hap_file="" # HapMap file path
gds_file=""
smp_file="" # Simple file path
min_depth_of_coverage=5
max_plcs_pnss=5
ld_threshold=0.1
maf_threshold=0.1
missing_rate=0.1
prefix_output="snphylo.output"
out_sample_id=""
bootstrap_analysis=0
muscle_analysis=0
num_bs_sample=100
num_last_autosome=22
skip_removing_low_quality_data=0
num_thread=1

# Parse positional parameters
while getopts "v:H:d:c:p:l:m:M:P:o:s:bB:Aa:t:rh" OPT
do
    case "${OPT}" in
        'v')
            vcf_file="${OPTARG}"
            ;;
        'H')
            hap_file="${OPTARG}"
            ;;
        'd')
            gds_file="${OPTARG}"
            ;;
        's')
            smp_file="${OPTARG}"
            ;;
        'c')
            min_depth_of_coverage="${OPTARG}"
            ;;
        'p')
            max_plcs_pnss="${OPTARG}"
            ;;
        'l')
            ld_threshold="${OPTARG}"
            ;;
        'm')
            maf_threshold="${OPTARG}"
            ;;
        'M')
            missing_rate="${OPTARG}"
            ;;
        'P')
            prefix_output="${OPTARG}"
            ;;
        'o')
            out_sample_id="${OPTARG}"
            ;;
        'B')
            num_bs_sample="${OPTARG}"
            ;;
        't')
            num_thread="${OPTARG}"
            ;;
        'b')
            bootstrap_analysis=1
            ;;
        'A')
            muscle_analysis=1
            ;;
        'r')
            skip_removing_low_quality_data=1
            ;;
        'a')
            num_last_autosome="${OPTARG}"
            ;;
        'h')
            print_help_and_exit 0
            ;;
        '?')
            print_help_and_exit 1
            ;;
        *)
            print_help_and_exit 1
            ;;
    esac
done

## Main processes
[ -z "${vcf_file}${hap_file}${gds_file}${smp_file}" ] && print_help_and_exit 1

if [ ! -z "${vcf_file}" ]
then
    [ ! -e "${vcf_file}" ] && print_help_and_exit 1 "VCF file (${vcf_file}) was not found!"
    [ $(wc -l < "${vcf_file}") -lt 5000 ] && print_help_and_exit 1 "VCF file (${vcf_file}) is too small to run this script!"

    if [ ${skip_removing_low_quality_data} -eq 1 ]
    then
        #
        [ $(wc -l < "${vcf_file}") -gt 1000000 ] && print_help_and_exit 1 "Error: There are too many SNP data in the file (${vcf_file})!\nPlease restart this script without '-r' option in order to remove low quality data."

        # Generate sequences from SNP data
        "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/generate_snp_sequence.R" --args -v "${vcf_file}" -l "${ld_threshold}" -m "${maf_threshold}" -M "${missing_rate}" -o "${prefix_output}" -a "${num_last_autosome}" -t "${num_thread}"
        [ $? != 0 ] && exit 1
    else
        # Remove VCF data which have many low depth of coverage samples
        echo "Start to remove low quality data."
        "${PYTHON}" "${SCRIPTS_DIR}/remove_low_depth_genotype_data.py" "${vcf_file}" ${min_depth_of_coverage} ${max_plcs_pnss} > "${prefix_output}.filtered.vcf"
        [ $? != 0 ] && exit 1

        # Determine and show the number of removed SNP data
        echo -e "\n$[$(wc -l < "${vcf_file}") - $(wc -l < "${prefix_output}.filtered.vcf")] low quality lines were removed."
        echo

        # 
        [ $(wc -l < "${prefix_output}.filtered.vcf") -lt 5000 ] && print_help_and_exit 1 "Error: There are too small number of SNP data in the file (${prefix_output}.filtered.vcf)!\nPlease restart this script with different parameter values (-p and/or -c)."

        # Generate sequences from SNP data
        "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/generate_snp_sequence.R" --args -v "${prefix_output}.filtered.vcf" -l "${ld_threshold}" -m "${maf_threshold}" -M "${missing_rate}" -o "${prefix_output}" -a "${num_last_autosome}" -t "${num_thread}"
        [ $? != 0 ] && exit 1
    fi
elif [ ! -z "${hap_file}" ]
then
    [ ! -e "${hap_file}" ] && print_help_and_exit 1 "HapMap file (${hap_file}) was not found!"
    [ $(wc -l < "${hap_file}") -lt 5000 ] && print_help_and_exit 1 "HapMap file (${hap_file}) is too small to run this script!"

    if [ ${skip_removing_low_quality_data} -eq 1 ]
    then
        #
        [ $(wc -l < "${hap_file}") -gt 1000000 ] && print_help_and_exit 1 "Error: There are too many SNP data in the file (${vcf_file})!\nPlease restart this script without '-r' option in order to remove low quality data."

        # Generate sequences from SNP data
        "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/generate_snp_sequence.R" --args -H "${hap_file}" -l "${ld_threshold}" -m "${maf_threshold}" -M "${missing_rate}" -o "${prefix_output}" -a "${num_last_autosome}" -t "${num_thread}"
        [ $? != 0 ] && exit 1
    else
        # Remove HapMap data which have many no genotype data
        echo "Start to remove low quality data."
    
        "${PYTHON}" "${SCRIPTS_DIR}/remove_no_genotype_data.py" "${hap_file}" ${max_plcs_pnss} > "${prefix_output}.filtered.hapmap"
        [ $? != 0 ] && exit 1
    
        # Determine and show the number of removed SNP data
        echo -e "\n$[$(wc -l < "${hap_file}") - $(wc -l < "${prefix_output}.filtered.hapmap")] low quality lines were removed"
        echo
    
        # 
        [ $(wc -l < "${prefix_output}.filtered.hapmap") -lt 5000 ] && print_help_and_exit 1 "Error: There are too small number of SNP data in the file (${prefix_output}.filtered.hapmap)!\nPlease restart this script with different parameter values (-p)."
    
        # Generate sequences from SNP data
        "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/generate_snp_sequence.R" --args -H "${prefix_output}.filtered.hapmap" -l "${ld_threshold}" -m "${maf_threshold}" -M "${missing_rate}" -o "${prefix_output}" -a "${num_last_autosome}" -t "${num_thread}"
        [ $? != 0 ] && exit 1
    fi
elif [ ! -z "${smp_file}" ]
then
    [ ! -e "${smp_file}" ] && print_help_and_exit 1 "Simple SNP file (${smp_file}) was not found!"
    [ $(wc -l < "${smp_file}") -lt 5000 ] && print_help_and_exit 1 "Simple data file (${smp_file}) is too small to run this script!"


    # Convert Simple SNP data file to HapMap file
    echo "Start to convert the simple SNP file to a HapMap file."

    "${PYTHON}" "${SCRIPTS_DIR}/convert_simple_to_hapmap.py" "${smp_file}" > "${prefix_output}.hapmap"
    [ $? != 0 ] && print_help_and_exit 1 "Error: The simple SNP file could not be converted to a HapMap file.\nPlease check the file and restart this script."


    if [ ${skip_removing_low_quality_data} -eq 1 ]
    then
        #
        [ $(wc -l < "${hap_file}") -gt 1000000 ] && print_help_and_exit 1 "Error: There are too many SNP data in the file (${vcf_file})!\nPlease restart this script without '-r' option in order to remove low quality data."

        # Generate sequences from SNP data
        "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/generate_snp_sequence.R" --args -H "${prefix_output}.hapmap" -l "${ld_threshold}" -m "${maf_threshold}" -M "${missing_rate}" -o "${prefix_output}" -a "${num_last_autosome}" -t "${num_thread}"
        [ $? != 0 ] && exit 1
    else
        # Remove HapMap data which have many no genotype data
        echo "Start to remove low quality data."
    
        "${PYTHON}" "${SCRIPTS_DIR}/remove_no_genotype_data.py" "${prefix_output}.hapmap" ${max_plcs_pnss} > "${prefix_output}.filtered.hapmap"
        [ $? != 0 ] && exit 1
    
        # Determine and show the number of removed SNP data
        echo -e "\n$[$(wc -l < "${prefix_output}.hapmap") - $(wc -l < "${prefix_output}.filtered.hapmap")] low quality lines were removed"
        echo
    
        # 
        [ $(wc -l < "${prefix_output}.filtered.hapmap") -lt 5000 ] && print_help_and_exit 1 "Error: There are too small number of SNP data in the file (${prefix_output}.filtered.hapmap)!\nPlease restart this script with different parameter values (-p)."
    
        # Generate sequences from SNP data
        "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/generate_snp_sequence.R" --args -H "${prefix_output}.filtered.hapmap" -l "${ld_threshold}" -m "${maf_threshold}" -M "${missing_rate}" -o "${prefix_output}" -a "${num_last_autosome}" -t "${num_thread}"
        [ $? != 0 ] && exit 1
    fi
elif [ ! -z "${gds_file}" ]
then
    [ ! -e "${gds_file}" ] && print_help_and_exit 1 "GDS file (${gds_file}) was not found!"

    # Generate sequences from SNP data
    "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/generate_snp_sequence.R" --args -d "${gds_file}" -l "${ld_threshold}" -m "${maf_threshold}" -M "${missing_rate}" -o "${prefix_output}" -a "${num_last_autosome}" -t "${num_thread}"
    [ $? != 0 ] && exit 1
else
    print_help_and_exit 1 "SNP data file was not found!"
fi


# Check the length of a sequence generated
seq_len=$(sed -n '2p' ${prefix_output}.fasta | wc -c)
if [ ${seq_len} -lt 500 ]
then
    print_help_and_exit 1 "Error: The length of sequence is too short (< 500 bp) to construct a tree!\nPlease restart this script with different parameter values (-l, -m and/or -M)."
elif [ ${seq_len} -lt 2000 ]
then
    echo -e "Warning: The length of sequence is too short (< 2000 bp) to construct a good tree!\nPlease consider to restart this script with different parameter values (-l, -m and/or -M)." 1>&2
elif [ ${seq_len} -gt 50000 ]
then
    print_help_and_exit 1 "Error: The length of sequence is too long (> 50000 bp) to construct a tree!\nPlease restart this script with different parameter values (-l, -m and/or -M)."
fi

#~/programs/clustalw/bin/clustalw2 -TYPE=DNA -ALIGN -OUTPUT=PHYLIP -INFILE=${prefix_output}.seq -OUTFILE=${prefix_output}.phylip
if [ ${muscle_analysis} -eq 1 ]
then
    "${MUSCLE}" -phyi -in "${prefix_output}.fasta" -out "${prefix_output}.phylip.txt"; [ $? != 0 ] && exit 1
else
    "${PYTHON}" "${SCRIPTS_DIR}/convert_fasta_to_phylip.py" "${prefix_output}.fasta" > "${prefix_output}.phylip.txt"
    [ $? != 0 ] && exit 1
fi

## Determine a phylogenetic tree
for rm_file in outfile outtree
do
    [ -e "${rm_file}" ] && rm -f "${rm_file}"
done

ln -sf "${prefix_output}.phylip.txt" infile

if [ -z "${out_sample_id}" ]
then
    echo -e "y\n" | "${DNAML}"; [ $? != 0 ] && exit 1
else
    out_sample_no=$[$(grep -ne "\<${out_sample_id}\>" infile | cut -f1 -d':') - 1]
    if [ ${out_sample_no} -eq -1 }
    then
        echo "Error!!! There is no sample name (${out_sample_id}) to use as a outgroup in a tree input file (${prefix_output}.phylip.txt)." 1>&2
        echo "Please check the name and restart this script." 1>&2
        rm -f infile
        exit 1
    else
        echo -e "o\n${out_sample_no}\ny\n" | "${DNAML}"; [ $? != 0 ] && exit 1
    fi
fi
mv outfile "${prefix_output}.ml.txt"
mv outtree "${prefix_output}.ml.tree"

rm -f infile

if [ -e ${prefix_output}.ml.tree ]
then
    "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/draw_unrooted_tree.R" --args -i "${prefix_output}.ml.tree" -o "${prefix_output}"
    [ $? != 0 ] && exit 1
fi

if [ ${bootstrap_analysis} -eq 1 ]
then
    "${R}" --slave --vanilla --file="${SCRIPTS_DIR}/determine_bs_tree.R" --args -i "${prefix_output}.ml.tree" -o "${prefix_output}" -p "${prefix_output}.phylip.txt" -n ${num_bs_sample}
    [ $? != 0 ] && exit 1
fi

echo "The tree file (${prefix_output}.xx.tree) and the image (${prefix_output}.xx.png) are successfully generated!"
echo "Now, you can see the tree by a program such as MEGA4 (http://www.megasoftware.net/mega4/mega.html), FigTree (http://tree.bio.ed.ac.uk/software/figtree/) and Newick utilities (http://cegg.unige.ch/newick_utils)."
echo "Good Luck!"
