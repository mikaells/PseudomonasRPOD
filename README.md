# PseudomonasRPOD

Psuedomonas species cannot be distuinguised using 16S gene amplicon sequencing. Instead the rpoD primers 

    ATYGAAATCGCCAARCG	

    CGGTTGATKTCCTTGA	

can be used to generate rpoD-amplicons, which then can be processed by this pipeline.

## Installation

    git clone https://github.com/mikaells/PseudomonasRPOD
    chmod 755 PseudomonasRPOD/bowtier.sh
    conda create --name rpoD
    conda activate rpoD
    conda install -c bioconda samtools bowtie2 parallel fastp

If you get a bowtie error about libtbb when running

    bowtie2 -h

then do

    conda install tbb=2020.2


## Running

The program bowtier.sh takes an input folder (-i) containing demultiplexed paired end files, an output folder (-o) and a database (-d) 

Test by
    #enter folder
    cd PseudomonasRPOD
    #run the files in pmix_in using the database in db/rpoD_amp and output in out/
    ./bowtier.sh -i pmix_in/ -o out -d db/rpoD_amp

The out/ -folder will now contain some temporary files, and importantly, the tables/ folder, in which a long table of how many reads mapped to each species.





