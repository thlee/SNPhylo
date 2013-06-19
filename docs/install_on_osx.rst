==========================
Installing SNPhylo on OS X
==========================

On Lion (10.7.5; 64 bit)
------------------------

1. Install R and related packages ::

    R for Mac can be download at http://cran.rstudio.com/
    After R is installed, three related R-libraries can be installed following online installation
    at http://chibba.pgml.uga.edu/snphylo/.

2. Make a SNPhylo directory in your home directory ::

    $ echo ${HOME} # Determine your home directory
    /home/foo

    $ SNPHYLO_HOME="/home/foo/snphylo"

    $ mkdir -p "${SNPHYLO_HOME}/bin"

3. Install the MUSCLE (if MUSCLE is not installed) ::

    $ curl -O http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86darwin64.tar.gz
    ...... (Downloaing the MUSCLE program)

    $ tar xvfz muscle3.8.31_i86darwin64.tar.gz -C "${SNPHYLO_HOME}/bin"
    ...... (Uncompressing the MUSCLE program)

    $ ln -sf "${SNPHYLO_HOME}/bin/muscle3.8.31_i86darwin64" "${SNPHYLO_HOME}/bin/muscle.app"


4. Install the Phylip package (if Phylip package is not installed) ::

    $ curl -O http://evolution.gs.washington.edu/phylip/download/phylip-3.695.tar.gz
    ...... (Downloaing the Phylip source codes)

    $ tar xvfz phylip-3.695.tar.gz -C "${SNPHYLO_HOME}"
    ...... (Uncompressing the Phylip source codes)

    $ ln -sf "${SNPHYLO_HOME}/phylip-3.695" "${SNPHYLO_HOME}/phylip"

    $ pusd "${SNPHYLO_HOME}/phylip/src"

    $ cp Makefile.osx Makefile
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
    Please enter the path of muscle program (ex: /home/foo/bin/muscle): /home/foo/snphylo/bin/muscle.app

    dnaml is not found. Is the program already installed? [y/N] y
    Please enter the path of dnaml program (ex: /home/foo/bin/dnaml): /home/foo/snphylo/phylip/exe/dnaml.app

    SNPHYLO is successfully installed!!!

    $ popd

7. Test the SNPhylo ::

    $ curl -O http://chibba.pgml.uga.edu/snphylo/soybean.hapmap.gz
    $ gunzip soybean.hapmap.gz

    $ /home/foo/snphylo/snphylo.sh -H soybean.hapmap
    Start to remove low quality data.

    ...... (Verbose Messages)

    The tree file (snphylo.output.dnaml.tree) is successfully generated!
    Now, you can see the tree by a viewer program such as FigTree (http://tree.bio.ed.ac.uk/software/figtree/).
    Good Luck!
