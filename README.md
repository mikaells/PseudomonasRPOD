# PseudomonasRPOD

Psuedomonas species cannot be distuinguised using 16S gene amplicon sequencing. Instead the rpoD primers 
ATYGAAATCGCCAARCG	
CGGTTGATKTCCTTGA	

can be used to generate rpoD-amplicons, which then can be processed by this pipeline.

#Installation

git clone https://github.com/mikaells/PseudomonasRPOD

conda create --name rpoD
conda install -c bioconda samtools bowtie2 parallel fastp

If you get a bowtie error about libtbb then do
conda install tbb=2020.2

#Running

./bowtier.sh -i pmix_in/ -o out -d db/rpoD_amp





