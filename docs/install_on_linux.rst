===========================
Installing SNPhylo on Linux
===========================

On Fedora 18 (64 bit)
---------------------

1. Install the R and the libraries to insall R packages (if they are not installed; as root) ::
    $ yum -y install R
    ...... (Installing the R)

    $ yum -y groupinstall "X Software Development" 
    ...... (Installing the libraries to install R packages)

2. Make a SNPhylo directory in your home directory ::

    $ echo ${HOME} # Determine your home directory
    /home/foo (This will be different on your system)

    $ SNPHYLO_HOME="/home/foo/snphylo" # "/home/foo" should be changed to your home directory determined above

    $ mkdir -p "${SNPHYLO_HOME}/bin"

3. Install the MUSCLE (if MUSCLE is not installed) ::

    $ curl -O http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
    ...... (Downloaing the MUSCLE program)

    $ tar xvfz muscle3.8.31_i86linux64.tar.gz -C "${SNPHYLO_HOME}/bin"
    ...... (Uncompressing the MUSCLE program)

    $ ln -sf "${SNPHYLO_HOME}/bin/muscle3.8.31_i86linux64" "${SNPHYLO_HOME}/bin/muscle"

4. Install the Phylip package (if Phylip package is not installed) ::

    $ curl -O http://evolution.gs.washington.edu/phylip/download/phylip-3.695.tar.gz
    ...... (Downloaing the Phylip source codes)

    $ tar xvfz phylip-3.695.tar.gz -C "${SNPHYLO_HOME}"
    ...... (Uncompressing the Phylip source codes)

    $ ln -sf "${SNPHYLO_HOME}/phylip-3.695" "${SNPHYLO_HOME}/phylip"

    $ pushd "${SNPHYLO_HOME}/phylip/src"

    $ cp Makefile.unx Makefile
    $ make install
    ...... (Compiling and installing the Phylip programs)

    $ popd

5. Install the SNPhylo ::

    $ curl -O http://chibba.pgml.uga.edu/snphylo/snphylo.tar.gz
    ...... (Downloading the SNPhylo)

    $ tar xvfz snphylo.tar.gz -C "${SNPHYLO_HOME}"
    ...... (Uncompressing the SNPhylo)

6. Setup the SNPhylo ::

    $ pushd "${SNPHYLO_HOME}"

    $ bash setup.sh

    START TO SET UP FOR SNPHYLO!!!

    The detected path of Rscript is /bin/Rscript. Is it correct? [Y/n] y 

    The detected path of python is /bin/python. Is it correct? [Y/n] y

    muscle is not found. Is the program already installed? [y/N] y
    Please enter the path of muscle program (ex: /home/foo/bin/muscle): /home/foo/snphylo/bin/muscle

    dnaml is not found. Is the program already installed? [y/N] y
    Please enter the path of dnaml program (ex: /home/foo/bin/dnaml): /home/foo/snphylo/phylip/exe/dnaml

    At least one R package (gdsfmt, phangorn, SNPRelate or getopt) to run this pipeline is not found. Is the program already installed? [y/N] n

    Do you want to install the packages by this script? [y/N] y

    ...... (Installing R packages)

    SNPHYLO is successfully installed!!!

    $ popd

7. Test the SNPhylo ::

    $ curl -O http://chibba.pgml.uga.edu/snphylo/soybean.hapmap.gz
    $ gunzip soybean.hapmap.gz

    $ /home/foo/snphylo/snphylo.sh -H soybean.hapmap
    Start to remove low quality data.

    ...... (Verbose Messages)

    The tree file (snphylo.output.xx.tree) and the image (snphylo.output.xx.png) are successfully generated!
    Now, you can see the tree by a program such as MEGA4 (http://www.megasoftware.net/mega4/mega.html), FigTree (http://tree.bio.ed.ac.uk/software/figtree/) and Newick utilities (http://cegg.unige.ch/newick_utils).
    Good Luck!

On Ubuntu 13.10 (64 bit)
------------------------------

1. Install the R (if R is not installed; as root) ::

    $ apt-get -y install r-base-dev r-cran-getopt r-cran-rgl
    ...... (Installing the R and related packages)

2. Make a SNPhylo directory in your home directory ::

    $ echo ${HOME} # Determine your home directory
    /home/foo (This will be different on your system)

    $ SNPHYLO_HOME="/home/foo/snphylo" # "/home/foo" should be changed to your home directory determined above

    $ mkdir -p "${SNPHYLO_HOME}/bin"

3. Install the MUSCLE (if MUSCLE is not installed) ::

    $ curl -O http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
    ...... (Downloaing the MUSCLE program)

    $ tar xvfz muscle3.8.31_i86linux64.tar.gz -C "${SNPHYLO_HOME}/bin"
    ...... (Uncompressing the MUSCLE program)

    $ ln -sf "${SNPHYLO_HOME}/bin/muscle3.8.31_i86linux64" "${SNPHYLO_HOME}/bin/muscle"

4. Install the Phylip package (if Phylip package is not installed) ::

    $ curl -O http://evolution.gs.washington.edu/phylip/download/phylip-3.695.tar.gz
    ...... (Downloaing the Phylip source codes)

    $ tar xvfz phylip-3.695.tar.gz -C "${SNPHYLO_HOME}"
    ...... (Uncompressing the Phylip source codes)

    $ ln -sf "${SNPHYLO_HOME}/phylip-3.695" "${SNPHYLO_HOME}/phylip"

    $ pusd "${SNPHYLO_HOME}/phylip/src"

    $ cp Makefile.unx Makefile
    $ make install
    ...... (Compiling and installing the Phylip programs)

    $ popd

5. Install the SNPhylo ::

    $ curl -O http://chibba.pgml.uga.edu/snphylo/snphylo.tar.gz
    ...... (Downloading the SNPhylo)

    $ tar xvfz snphylo.tar.gz -C "${SNPHYLO_HOME}"
    ...... (Uncompressing the SNPhylo)

6. Setup the SNPhylo ::

    $ pushd "${SNPHYLO_HOME}"

    $ bash setup.sh

    START TO SET UP FOR SNPHYLO!!!

    The detected path of Rscript is /bin/Rscript. Is it correct? [Y/n] y 

    The detected path of python is /bin/python. Is it correct? [Y/n] y

    muscle is not found. Is the program already installed? [y/N] y
    Please enter the path of muscle program (ex: /home/foo/bin/muscle): /home/foo/snphylo/bin/muscle

    dnaml is not found. Is the program already installed? [y/N] y
    Please enter the path of dnaml program (ex: /home/foo/bin/dnaml): /home/foo/snphylo/phylip/exe/dnaml

    At least one R package (gdsfmt, phangorn, SNPRelate or getopt) to run this pipeline is not found. Is the program already installed? [y/N] n

    Do you want to install the packages by this script? [y/N] y

    ...... (Installing R packages)

    SNPHYLO is successfully installed!!!

    $ popd

7. Test the SNPhylo ::

    $ curl -O http://chibba.pgml.uga.edu/snphylo/soybean.hapmap.gz
    $ gunzip soybean.hapmap.gz

    $ /home/foo/snphylo/snphylo.sh -H soybean.hapmap
    Start to remove low quality data.

    ...... (Verbose Messages)

    The tree file (snphylo.output.xx.tree) and the image (snphylo.output.xx.png) are successfully generated!
    Now, you can see the tree by a program such as MEGA4 (http://www.megasoftware.net/mega4/mega.html), FigTree (http://tree.bio.ed.ac.uk/software/figtree/) and Newick utilities (http://cegg.unige.ch/newick_utils).
    Good Luck!
