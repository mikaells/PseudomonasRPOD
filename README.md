# PseudomonasRPOD

Psuedomonas species cannot be distuinguised using 16S gene amplicon sequencing. Instead the rpoD primers 

    ATYGAAATCGCCAARCG	

    CGGTTGATKTCCTTGA	

can be used to generate rpoD-amplicons, which then can be processed by this pipeline.

## Installation

    git clone https://github.com/mikaells/PseudomonasRPOD

    conda create --name rpoD
    conda install -c bioconda samtools bowtie2 parallel fastp
    conda activate rpoD

If you get a bowtie error about libtbb when running

    bowtie2 -h

then do

    conda install tbb=2020.2


## Running

The program bowtier.sh takes an input folder (-i) containing demultiplexed paired end files, an output folder (-o) and a database (-d) 

Test by

    ./bowtier.sh -i pmix_in/ -o out -d db/rpoD_amp





