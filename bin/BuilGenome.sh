#!/usr/bin/bash
ref=$1

bwa="/export/personal/mengmh/software/bwa-0.7.15/bwa"
samtools="/export/personal/mengmh/software/samtools-1.4/samtools"
picard="/export/personal/mengmh/software/picard/picard.jar"

if [ -n "$ref" ];then  
	fai=${ref}.fai
    dict=${ref}.dict    
    intervals=${ref}.intervals
	dict=`echo $dict |sed 's/.fa//g' `   
	${bwa} index $ref
    ${samtools} faidx $ref
    java -jar ${picard} CreateSequenceDictionary R= ${ref} O= ${dict}
    cut -f1 ${fai} > ${intervals}
else 
	echo "Please use like this:  sh ./BuilGenome.sh [your input fasta] "
fi
