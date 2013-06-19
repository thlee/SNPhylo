=======
SNPhylo
=======

Introduction
------------
Phylogenetic tree is a good tool to infer evolutionary relationships among various organisms so the tree has been used in many evolutionary studies. Consequently, phylogenetic tree based on SNP data have been determined in resequencing projects. However, there was no simple way to determine phylogenetic tree with the huge number of variants determined from resequencing data. Thus, we had developed new pipeline, SNPhylo, to construct phylogenetic tree based on SNP data. With this pipeline, user can construct a phylogenetic tree from a file containing huge SNP data.

Features
--------
1. Tree construction based on genome wide SNPs. Conventional tree construction is based on hand full of genes with certain properties such single copy gene, ribosomal RNA gene, Internal transcribed spacer sequences (ITS). SNPhylo builds tree with genome wide information, thus, it is more accurate
2. Reduce SNP redundancy by linkage disequilibrium (LD).SNPs in a same LD block provides redundant lineage information. SNPhylo keeps only one informative SNP in a LD block. It greatly decreases running time without losing informative sites.
3. Tree construction process is highly automated. SNPhylo takes most common SNP/genotype format (vcf/hapmap) as input and produces maximum likelihood tree with only one command!

Homepage
--------
http://chibba.pgml.uga.edu/snphylo

Contact
-------
Tae-Ho Lee (thlee_at_uga.edu) or Hui Guo (hguo_at_uga.edu)
