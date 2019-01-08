#!/bin/sh 
set -e
####
if [ $# != 1 ]
then
	echo -e "\t\tUsage: ReSEQ.sh < ./xxx.conf > [ sample configue file is like: /export/personal/mengmh/pipeline/ReSEQ/v1.2/example/ReSEQ.conf ] ";
	exit;
fi

###
configure=$(readlink -f $1) 
source $configure
###  output
mkdir -p $od 
if [ ! -e $od/Sample.list ];then 
	ls $id/*_R1.fq.gz |while read i ;do basename $i "_R1.fq.gz" ;done > $od/Sample.list
fi

## Refrence
mkdir -p ${REF}
if [ ! -e ${REF}/refrence.done ];then
	date "+%Y-%m-%d %H:%M:%S" && echo -e "\tPreparing : Building refrence index"
	cd ${REF}
	ln -s ${ref} refrence.fa
	${samtools} faidx refrence.fa
	${bwa} index refrence.fa
	${gatk} --java-options "-Xmx5G -Djava.io.tmpdir=./tmp" CreateSequenceDictionary --REFERENCE refrence.fa 
	touch refrence.done 
fi

## QC
mkdir -p $QC
cd $QC
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep1: cd $QC && /home/mengmh/bin/QSUB cmd.QC.sh ${name}_QC 1 1 "

if [ $fq_s -ge 2 ];then
	cat $od/Sample.list | while read i ; do echo "${fastp} -i ${id}/${i}_R1.fq.gz -o $QC/${i}_R1.fq.gz -I ${id}/${i}_R2.fq.gz -O $QC/${i}_R2.fq.gz -R ${i} -h ${i}.html -j ${i}.json -s ${fq_s} -d 1 " ;done > cmd.QC.sh 
else
	cat $od/Sample.list | while read i ; do echo "${fastp} -i ${id}/${i}_R1.fq.gz -o $QC/${i}_R1.fq.gz -I ${id}/${i}_R2.fq.gz -O $QC/${i}_R2.fq.gz -R ${i} -h ${i}.html -j ${i}.json -d 1 " ;done > cmd.QC.sh
fi

/home/mengmh/bin/QSUB cmd.QC.sh ${name}_QC 1 1 
${bin}/FastpStat.pl $QC

## Map
mkdir -p $MAP
cd $MAP
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep2：cd $MAP && /home/mengmh/bin/QSUB cmd.Mapping.sh  ${name}_MP ${thread} 1 "

if [ $fq_s -ge 2 ];then
	cat $od/Sample.list | while read i 
	do
		for y in $( seq 1 ${fq_s});do echo "${bwa} mem -R \"@RG\\tID:${i}\\tLB:${i}\\tPL:ILLUMINA\\tSM:${i}\" -t ${thread} -M $REF/refrence.fa $QC/${y}.${i}_R1.fq.gz $QC/${y}.${i}_R2.fq.gz |$samtools view -@ 2 -bS - | $samtools sort -@ 2 -m 1000000000 -o $MAP/${i}.${y}.bam" ;done 
	done > cmd.Mapping.sh 
else
	cat $od/Sample.list | while read i;do echo "${bwa} mem -R \"@RG\\tID:${i}\\tLB:${i}\\tPL:ILLUMINA\\tSM:${i}\" -t ${thread} -M $REF/refrence.fa $QC/${i}_R1.fq.gz $QC/${i}_R2.fq.gz |$samtools view -@ 2 -bS - | $samtools sort -@ 2 -m 1000000000 -o $MAP/${i}.bam" ;done > cmd.Mapping.sh
fi

/home/mengmh/bin/QSUB cmd.Mapping.sh  ${name}_MP ${thread} 1;

## Merge Sort 
mkdir -p $SORT 
cd $SORT
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep3: cd $SORT && /home/mengmh/bin/QSUB  00.cmd.MergeSort.sh ${name}_ST 1 5 "
cat $od/Sample.list | while read i 
do
	ls $MAP/${i}*.bam > ${i}.fofn
	echo "${samtools} merge -rcpf -l 3 -b ${i}.fofn ${i}.bam"
	echo "${samtools} stats ${i}.bam > ${i}.stat"
	echo "${samtools} flagstat ${i}.bam > ${i}.flagstat"
	echo "${samtools} depth -aa ${i}.bam |gzip > ${i}.depth.gz"
	echo "${bin}/StatDepth.pl ${i}.depth.gz ${i} > ${i}.depth.stat"
	echo "${samtools} index ${i}.bam"
done > 00.cmd.MergeSort.sh 
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep3-1: cd $SORT && /home/mengmh/bin/QSUB 00.cmd.MergeSort.sh ${name}_ST 1 6 "
/home/mengmh/bin/QSUB  00.cmd.MergeSort.sh ${name}_ST 1 6
python ${bin}/MapStat.py -i $SORT -o $SORT/MapStat.xls
${bin}/SplitBam.pl $SORT $REF/refrence.fa.fai ${split}
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep3-2: cd $SORT && /home/mengmh/bin/QSUB 01.cmd.SplitBam.sh  ${name}_SB 1 1"
/home/mengmh/bin/QSUB 01.cmd.SplitBam.sh  ${name}_SB 1 1 
cut -f1 Split.list > $od/Split.list

## Call SV
if [ $sv = 1 ];then
	mkdir -p $SV && cd $SV
	cat $od/Split.list |while read i ; do bams=`ls $SORT/*split/*${i}*bam|sed ':a;N;$!ba;s/\n/,/g'`;echo "${lump} -R ${REF}/refrence.fa -o ${i}.vcf -k -T ${i}.vcf.tmp -B ${bams}";done > 00.cmd.CallSV.sh
	date "+%Y-%m-%d %H:%M:%S" && echo -e "SV Calling is run: cd $SV && /home/mengmh/bin/QSUB 00.cmd.CallSV.sh ${name}_SV 2 1 & "
	/home/mengmh/bin/QSUB 00.cmd.CallSV.sh ${name}_SV 2 1 &
fi
## Duplication
mkdir -p $DUP
mkdir -p $DUP/tmp 
cd $DUP
ls $SORT/*/*bam|while read i ;
do 
	sam=$(basename $i)
	echo "${bin}/FilterBam.pl ${i} ${MapQ}|$samtools view -@ 2 -bS ->  $DUP/tmp/${sam}"
	echo "${samtools} rmdup $DUP/tmp/${sam} $DUP/${sam}"
	echo "${samtools} index $DUP/${sam}"
done > 00.cmd.Duplication.sh 
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep4: cd $DUP && /home/mengmh/bin/QSUB 00.cmd.Duplication.sh ${name}_DP 1 3 "
/home/mengmh/bin/QSUB 00.cmd.Duplication.sh ${name}_DP 1 3

## Call GVCF
mkdir -p $HAP
cd $HAP
ls $DUP/*bam| while read i ; do sam=$(basename $i ".bam" );echo "${gatk} --java-options \" ${hap_java_opt} \" HaplotypeCaller -ERC GVCF --sample-ploidy ${ploidy} -R $REF/refrence.fa -I ${i} -O $HAP/${sam}.g.vcf";done > 00.cmd.Haplotype.sh
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep5: cd $HAP && /home/mengmh/bin/QSUB 00.cmd.Haplotype.sh ${name}_HC ${thread} 1"
/home/mengmh/bin/QSUB 00.cmd.Haplotype.sh ${name}_HC 2  1
if [ ! -e 01.cmd.CreatIndex.sh.done ];then
	ls *g.vcf |while read i;do  echo "${bgzip} -@ 2 $i";echo "${tabix} -p vcf -f $i.gz";done  > 01.cmd.CreatIndex.sh 
	date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep5-1: cd $HAP && /home/mengmh/bin/QSUB /home/mengmh/bin/QSUB 01.cmd.CreatIndex.sh ${name}_ID 1 2 "
	/home/mengmh/bin/QSUB 01.cmd.CreatIndex.sh ${name}_ID 1 2 
fi

mkdir -p $VCF
cd $VCF
cat $od/Split.list |while read i ;
do 
	ls $HAP/*${i}.g.vcf.gz > ${i}.list
	sample_list=`perl -ne 'chomp; print "-V $_ "' ${i}.list`
	#echo "${gatk} --java-options \" ${type_java_opt} \" GenomicsDBImport $sample_list --genomicsdb-workspace-path $VCF/genomicsdb/${i} "
	echo "${gatk} --java-options \" ${type_java_opt} \" CombineGVCFs $sample_list -O ${i}.g.vcf -R $REF/refrence.fa"
	echo "${bgzip} -@ 4 ${i}.g.vcf && ${tabix} -p vcf -f ${i}.g.vcf.gz"
	echo "${gatk} --java-options \" ${type_java_opt} \" GenotypeGVCFs -O $VCF/${i}.vcf  -V ${i}.g.vcf.gz -R ${REF}/refrence.fa"
done > 00.cmd.Genotyping.sh 
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep6: cd $VCF && /home/mengmh/bin/QSUB 00.cmd.Genotyping.sh ${name}_GT 4 3"
/home/mengmh/bin/QSUB 00.cmd.Genotyping.sh ${name}_GT 4 3 

mkdir -p $SAI
mkdir -p $SAI/tmp 
cd $SAI/tmp 
cat $od/Split.list |while read i ;
do 
	echo "cd $SAI/tmp && ${vcftools} --vcf $VCF/${i}.vcf --min-alleles 2 --max-alleles 2 --recode --recode-INFO-all --out ${i} --min-meanDP $deep --maf $maf --max-missing $missing "
	#echo "$gatk --java-options \" ${hap_java_opt} \" SplitVcfs --INPUT ${i}.recode.vcf --SNP_OUTPUT ${i}.snp.raw.vcf  --INDEL_OUTPUT ${i}.indel.raw.vcf"
	echo "$gatk --java-options \" ${hap_java_opt} \" SelectVariants -V ${i}.recode.vcf -R $REF/refrence.fa --select-type-to-include SNP -O ${i}.snp.raw.vcf"
	echo "$gatk --java-options \" ${hap_java_opt} \" SelectVariants -V ${i}.recode.vcf -R $REF/refrence.fa --select-type-to-include INDEL -O ${i}.indel.raw.vcf"
	echo "$gatk --java-options \" ${hap_java_opt} \" VariantFiltration -V ${i}.snp.raw.vcf -O ${i}.snp.filter.tmp.vcf -cluster $cluster -window $window --filter-expression \"$snp_filter_exp\" --filter-name snp_filter --missing-values-evaluate-as-failing"
	echo "$gatk --java-options \" ${hap_java_opt} \" VariantFiltration -V ${i}.indel.raw.vcf -O ${i}.indel.filter.tmp.vcf --filter-expression \"$indel_filter_exp\" --filter-name indel_filter --missing-values-evaluate-as-failing"
	echo "$gatk --java-options \" ${hap_java_opt} \" SelectVariants -V ${i}.snp.filter.tmp.vcf -O ${i}.snp.filter.vcf --exclude-filtered"
	echo "$gatk --java-options \" ${hap_java_opt} \" SelectVariants -V ${i}.indel.filter.tmp.vcf -O ${i}.indel.filter.vcf --exclude-filtered"
done > 00.cmd.FilterVCF.sh 
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tStep7:cd $SAI/tmp && /home/mengmh/bin/QSUB 00.cmd.FilterVCF.sh ${name}_FV 1 7"
/home/mengmh/bin/QSUB 00.cmd.FilterVCF.sh ${name}_FV 1 7
cd $SAI
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tAll filter done; please wait for format transport"
if [ ! -e $SAI/00.cmd.CombinChr.sh.done ];then
	head -1 $od/Split.list |while read i ; do head -10000 $SAI/tmp/${i}.snp.filter.vcf | grep "#"  > snp.filter.vcf ; done
	cat $od/Split.list |while read i ; do grep -v "#" $SAI/tmp/${i}.snp.filter.vcf >> snp.filter.vcf ;done
	echo "${bin}/ExtractVCF.py SNP snp.filter.vcf " > 00.cmd.CombinChr.sh
	head -1 $od/Split.list |while read i ; do head -10000 $SAI/tmp/${i}.indel.filter.vcf | grep "#"  > indel.filter.vcf ; done
	cat $od/Split.list |while read i ; do grep -v "#" $SAI/tmp/${i}.indel.filter.vcf  >> indel.filter.vcf ; done
	echo "${bin}/ExtractVCF.py INDEL indel.filter.vcf" >> 00.cmd.CombinChr.sh
	/home/mengmh/bin/QSUB 00.cmd.CombinChr.sh ${name}_CC 1 1  
fi 
date "+%Y-%m-%d %H:%M:%S" && echo -e "\tCongratulation! All pipeline has done , please check your result "
############################################	
