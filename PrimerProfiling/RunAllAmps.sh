#!/bin/bash

####
#A program to primer amplicons from a set of files
#Mikael Lenz Strube 
#03-01-2021
####

#Input sanitation
if [ "$#" -lt 2 ]; then
	echo -e "\nUsage is\nRunAllAmps.sh \n\t-i|--input <inputfolder>\n\t-p|--primer <primerfile>\n\t[-d|--derep true/false]\n\t[-c|--clobber true/false].\n\n"
	exit;
fi

#working out where script is to avoid problems with being put in strange places
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#setting global variable, will be overwritten i argument is present

while :
do
 case "$1" in
	-h | --help)
		echo -e "\nUsage is\nRunAllAmps.sh \n\t-i|--input <inputfolder>\n\t-p|--primer <primerfile>\n\t[-d|--derep true/false]\n\t[-c|--clobber true/false].\n\n"
		exit 0
		;;
	-i | --input)
		inputfolder="$2"
		shift 2
		;;
	-p | --primer)
		primer="$2"
		shift 2
		;;
	-c | --clobber)
		clobber=$2
		shift 2
		;;
	-m | --middle)
		cutMiddle=$2
		shift 2
		;;
	--)
		shift
		break
		;;
	-*)
		echo -e "Error: Unexpected option $1"
		exit 4
		;;
	*)
		break
		;;
 esac
done

if [[ $cutMiddle == true ]]
then
	cutMiddleString="_noMiddle"
else
	cutMiddleString=""
fi


primeFolder="$( basename $primer .primers)$cutMiddleString";
outfolder="SingleGenomes"
primeSummaries="$primeFolder-summary"


echo "$primeFolder $outfolder $primeSummaries"
cat $primer


echo -e "\n***RunAllAmps running on $primeFolder***\n\n"


if [[ $clobber = true  ]]
then
	echo -e "Removing old run of $primeFolder."
	if [[ -d $primeFolder ]]
	then
		rm -r $primeFolder
		rm -r $primeSummaries
		echo -e "\n"
	else
		echo -e "\t$primeFolder-folder does not exist, ignoring --clobber\n\n"
	fi
elif [[ -d $primeFolder ]]
then
	echo -e "$primeFolder-folder already exists, run again with --clobber true to remake, will work on existing.\n\n"
fi



if [[ -d $outfolder ]]
then
	echo -e "\t$outfolder exist, working from here\n\n"
else
	sed -i 's/_genome//g; s/_assembly//g; s/_chromosome//g; s/_complete//g; s/Pseudomonas/P/g; s/[][]//g; s/[:,/()=]//g; s/[: ]/_/g' $inputfolder/*
	mkdir $outfolder

	for i in $inputfolder/*; do
		echo ""
		newf=$(head "$i" -n1 | cut -f1 -d" " | cut -f2 -d">");
		echo $i
		echo $newf;
		mkdir $outfolder/$newf;
		cp $i $outfolder/$newf/$newf.fna;
		sed -i 's/[:,/()=]//g; s/[: ]/_/g'  $outfolder/$newf/$newf.fna
		#rename 's/_genome//g; s/_assembly//g; s/_chromosome//g; s/_complete//g; s/Pseudomonas/P/g; s/[][]//g'  $outfolder/$newf/$newf.fna
	done

fi




if [[ -d $primeFolder ]]
then
	echo -e "\t$primeFolder exists, working from here\n\n"
else

	mkdir $primeFolder

	for i in $outfolder/*; do
		j=$(basename $i)

		in_silico_PCR.pl -s $i/*fna -p $primer -l 1500 -m -i -r > $primeFolder/$j.names 2> $primeFolder/$j.amps
		seqkit replace --quiet -p "(.+)" -r '{kv}' -k $primeFolder/$j.names $primeFolder/$j.amps > $primeFolder/$j.rename.amps

		if [[ $cutMiddle == true ]]
		then
			cutMiddleString=".noMiddle"
			Rscript $scriptDir/removeNonOverlap.R $primeFolder/$j.rename.amps $primeFolder/$j.noMiddle.rename.amps 300
			vsearch  --cluster_fast $primeFolder/$j.noMiddle.rename.amps -id 0.97  --quiet --sizeout --consout $primeFolder/$j.noMiddle.rename.clus97
		else
			cutMiddleString=""
			vsearch  --cluster_fast $primeFolder/$j.rename.amps -id 0.97  --quiet --sizeout --consout $primeFolder/$j.rename.clus97
		fi
	done
fi


mkdir -p $primeSummaries

cat $primeFolder/*clus97 | sed 's/centroid=//g' | sed 's/;seqs=.;size=.//g' > $primeSummaries/$primeFolder.all$cutMiddleString.clus97

perl -i -p -e 's/$/_$seen{$_}/ if ++$seen{$_}>1 and /^>/; ' $primeSummaries/$primeFolder.all$cutMiddleString.clus97

muscle -in $primeSummaries/$primeFolder.all$cutMiddleString.clus97 -out $primeSummaries/$primeFolder.all$cutMiddleString.clus97.aln -quiet

FastTree -quiet -nt -gtr  $primeSummaries/$primeFolder.all$cutMiddleString.clus97.aln > $primeSummaries/$primeFolder.all$cutMiddleString.clus97.tree

#if ncbi data, run
#probably easier to run right after making singleGenomes
#for i in ../primers/*; do j=$(basename $i .primers); echo $j; rename  's/_genome//g; s/_assembly//g; s/_chromosome//g; s/_complete//g; s/Pseudomonas/P/g; s/[][]//g ' $j/* ; done

