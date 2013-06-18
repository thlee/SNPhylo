function ask_program_path {
    local program_name="${1}"

    while :
    do
        local program_path=""
        echo 1>&2
        read -p "${program_name} is not found. Is the program already installed? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo 1>&2
            read -p "Please enter the path of ${program_name} program (ex: /home/foo/bin/${program_name}): " program_path
            [ -e "${program_path}" -a -x "${program_path}" ] && break
        else
            break
        fi
    done

    echo "${program_path}"
}

function ask_r_lib_dir {
    while :
    do
        local r_lib_dir=""
        echo 1>&2
        read -p "At least one R library (gdsfmt, SNPRelate or getopt) to run this pipeline is not found. Is the program already installed? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo 1>&2
            read -p "Please enter the directory of the R libraries (ex: /home/foo/r_library): " r_lib_dir
            [ $(check_R_library "${r_lib_dir}") -eq 0 ] && break
        else
            break
        fi
    done

    echo "${r_lib_dir}"
}

function determine_program_path {
    local program_name="${1}"
    local program_path=""
   
    program_path="$(which "${program_name}" 2> /dev/null | tail -n1 | tr -d '\t')" #To remove alias information
    if [ -z "${program_path}" ]
    then
        program_path=$(ask_program_path "${program_name}")
    else
        if [ -e "${program_path}" -a -x "${program_path}" ]
        then
            echo 1>&2
            read -p "The detected path of ${program_name} is ${program_path}. Is it correct? [Y/n] " -n 1
            if [[ ${REPLY} =~ ^[Nn]$ ]]
            then
                program_path="$(ask_program_path "${program_name}")"
            fi
        else
            program_path="$(ask_program_path "${program_name}")"
        fi
    fi

    echo "${program_path}"
}

function check_R_library {
    local r_lib_dir="${1}"

    if [ -z "${r_lib_dir}" ]
    then
        "${R_BASE_DIR}/R" --vanilla --slave <<R_SCRIPT
if (all(c("gdsfmt", "SNPRelate", "getopt") %in% rownames(installed.packages()))) {
    quit(save="no", status=0)
} else {
    quit(save="no", status=1)
}
R_SCRIPT
    else
        "${R_BASE_DIR}/R" --vanilla --slave <<R_SCRIPT
if (all(c("gdsfmt", "SNPRelate", "getopt") %in% rownames(installed.packages(lib.loc="${r_lib_dir}")))) {
    quit(save="no", status=0)
} else {
    quit(save="no", status=1)
}
R_SCRIPT
    fi
    echo $?
}

# Main
# BASE_DIR=$(dirname $(readlink -f "$0")) # readlink in Mac OS X does not support the '-f' option
BASE_DIR=$(cd "$(dirname "$0")" && pwd)

BASH_PATH="$(which bash 2> /dev/null | tail -n1 | tr -d '\t')" #To remove alias information

echo "START TO SET UP FOR SNPHYLO!!!"

[ -e "${BASE_DIR}/snphylo.cfg" ] && rm -f "${BASE_DIR}/snphylo.cfg"
touch "${BASE_DIR}/snphylo.cfg"

# Check programs
exec 16<> setup.data
while read -u 16 var_name program_name program_url
do
    program_path="$(determine_program_path "${program_name}")"
    if [ -z "${program_path}" ]
    then    
        echo -e "\nYou can download ${program_name} at ${program_url}.\nPlease, install the program and restart this script."
        rm -f "${BASE_DIR}/snphylo.cfg"
        exit 1
    else
        echo "${var_name}='${program_path}'" >> "${BASE_DIR}/snphylo.cfg"
        [ "${var_name}" == "RSCRIPT" ] && R_BASE_DIR="${program_path%/Rscript}"
    fi
done

# Check and install R libraries
if [ $(check_R_library) -eq 1 ]
then
    r_lib_dir="$(ask_r_lib_dir)"
    if [ -z "${r_lib_dir}" ]
    then
        echo 1>&2
        read -p "Do you want to install the libraries by this script? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            [ ! -e "${BASE_DIR}/R_LIBS/" ] && mkdir -p "${BASE_DIR}/R_LIBS/"
            "${R_BASE_DIR}/R" --vanilla --slave <<R_SCRIPT
install.packages("SNPRelate", lib="${BASE_DIR}/R_LIBS/", repos="http://cran.r-project.org", type="source")
install.packages("getopt", lib="${BASE_DIR}/R_LIBS/", repos="http://cran.r-project.org", type="source")
R_SCRIPT
            if [ $(check_R_library "${BASE_DIR}/R_LIBS/") -eq 1 ]
            then
                echo -e "\nFail to install the libraries. :("
                r_lib_dir=""
            else
                r_lib_dir="${BASE_DIR}/R_LIBS/"
            fi
        else
            r_lib_dir=""
        fi
    fi

    if [ -z "${r_lib_dir}" ]
    then
        echo -e "\nYou can download the libraries at http://cran.r-project.org/web/packages/SNPRelate/index.html.\nPlease, install the libraries and restart this script."
        rm -f "${BASE_DIR}/snphylo.cfg"
        exit 1
    else
        echo "R_LIBS_DIR='${r_lib_dir}'" >> "${BASE_DIR}/snphylo.cfg"
    fi
fi

# Make a pipeline script file
(echo '#!'${BASH_PATH}; grep -ve "^#!" ${BASE_DIR}/snphylo.template) > ${BASE_DIR}/snphylo.sh
chmod a+x snphylo.sh

echo
echo "SNPHYLO is successfully installed!!!"

exit 0
