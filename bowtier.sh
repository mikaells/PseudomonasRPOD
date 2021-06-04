#!/bin/bash

####
#A program to clean and bowtie files in a folder
####

#Input sanitation
if [ "$#" -lt 4 ]; then
	echo -e "\nUsage is\nBowtier \n\t-i|--input <inputfolder>\n\t-o|--output <outputfolder> \n\t-d|--database <database>.\n\n"
	exit;
fi

while :
do
 case "$1" in
	-h | --help)
		echo -e "\nUsage is\nBowtier \n\t-i|--input <inputfolder>\n\t-o|--output <outputfolder> \n\t-d|--database <database>.\n\n"
		exit 0
		;;
	-i | --input)
		input_dir="$2"
		count=`ls -1 "$input_dir"/*.fastq 2>/dev/null | wc -l`
		if [ $count != 0 ];	then
			shift 2
		else
			echo -e "$input_dir does not exist or does not contain demul files!"
			exit 1
		fi
		;;
	-o | --output)
		output_dir="$2"
		mkdir -p $output_dir
		if [ -d "$output_dir" ]; then
			shift 2
		else
			echo -e "$output_dir is not a valid directory"
			exit 2
		fi
		;;
	-d | --database)
		database="$2"
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

echo -e "\nWorking on $input_dir\n";
mkdir -p $output_dir/
mkdir -p $output_dir/demul_in
mkdir -p $output_dir/clean
mkdir -p $output_dir/classify
mkdir -p $output_dir/tables


#the function we use for the loop in the main program
mainFunc () {

	threads=1

	forw_file=$1
	output_dir=$2
	database=$3
	input_dir=$4


	#reverse file is the same as forward but with R instead of F
	rev_file=${forw_file/_R1_/_R2_}

	forw_name=$(basename "$forw_file")
	forw_name="${forw_name%.*}"
	rev_name=$(basename "$rev_file")
	rev_name="${rev_name%.*}"


	#clean ends and remove bad sequences in both reads with fastp
	fastp -i $input_dir/$forw_file -I $input_dir/$rev_file -o $output_dir/clean/$forw_name.clean -O $output_dir/clean/$rev_name.clean 2> $output_dir/clean/$rev_name.fastp.rep 

	#use bowtie to match pairs to database
	#-X is max length between pairs, --ff is because reverse reads is reverse complemented so both are forward matching
	#also unalligned sequenses are ignored and there are no header in SAM file
	#returns a SAM file and bowtie report is returned through 2>
	bowtie2 -x $database -1 $output_dir/clean/$forw_name.clean -2 $output_dir/clean/$rev_name.clean -S $output_dir/classify/$forw_name.sam -X 900 --ff  --no-unal  --very-sensitive -p $threads 2> $output_dir/classify/$forw_name.bowtierep 

	#SAM is a confusing format, so we only keep the 3rd field (the match name), which we pipe along to get a abundance table
	awk -F '\t' '$2<100 {print $3} ' $output_dir/classify/$forw_name.sam | sort | uniq -c | sort -nr > $output_dir/tables/$forw_name.table 

	#get only concordant and highish quality
	samtools view -f2 -S $output_dir/classify/$forw_name.sam > $output_dir/classify/$forw_name.PP_Q10.sam

	#SAM is a confusing format, so we only keep the 3rd field (the match name), which we pipe along to get a abundance table
	awk -F '\t' '$2<100 {print $3} ' $output_dir/classify/$forw_name.PP_Q10.sam | sort | uniq -c | sort -nr > $output_dir/tables/$forw_name.PP_Q10.table

}


#then we loop through the files in the demul folder, calling the function on each
#the & sends process to background, in practice running all files in parallel
#watch out if you have more files than cores!#for file in $(ls $output_dir/demul_in/ | grep ".F.fastq")



cores=$( nproc --all )

export -f mainFunc
parallel -j $cores --linebuffer mainFunc :::  $(ls $input_dir | grep "_R1_") ::: $output_dir ::: $database ::: $input_dir

#done
