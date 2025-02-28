#/usr/bin/bash

dir=$1
sample=$2 

index=/workspace/rsrch2/common_data/Align2Index/bowtie2_index/mm10/mm10


Qc="01_Fastp"


if [ ! -d $dir/01_Fastp ]
then 
  mkdir -p $dir/01_Fastp
fi

if [ ! -d $dir/02_bowtie2_mapping ] 
then
  mkdir -p ${dir}/02_bowtie2_mapping
fi

if [ ! -d $dir/03_Unique_mapped/mm10 ]
then 
   mkdir -p $dir/03_Unique_mapped/mm10
fi

if [ ! -d $dir/04_homer/tagDirectory/ ]; then
  mkdir -p $dir/04_homer/tagDirectory/
fi

if [ ! -d $dir/04_homer/bigwig/ ]; then
  mkdir -p $dir/04_homer/bigwig/
fi

if [ ! -d $dir/logs ] 
then
  mkdir -p ${dir}/logs
fi

cd $dir
echo -e "Now process ${sample} at ${date} \n" >$dir/logs/StarBigwik_${sample}.log
echo -e "####################Now do fastp######################\n" >>$dir/logs/StarBigwik_${sample}.log
      
echo $sample
file=$(cat $dir/rawdata/sample.info.txt | grep $sample | cut -f 3)
f=$(ls $dir/rawdata/Fastq/${file}*)
fastp -w 16 -i $f -o $dir/$Qc/${sample}.fq.gz -h $dir/$Qc/${sample}.html

echo -e "####################Now bowtie2 for ${sample} with mm10 at ${date}######################\n" >>$dir/logs/StarBigwik_${sample}.log
bowtie2 --mm -p 20 -x $index -U ${dir}/$Qc/${sample}.fq.gz 2> $dir/logs/${sample}.align.log | samtools view -Sbh -@ 20 | samtools sort -@ 20 >$dir/02_bowtie2_mapping/${sample}_mm10.sorted.bam
echo "bowtie2 for ${sample} with mm10 is done at ${date}" >>$dir/logs/StarBigwik_${sample}.log

echo "Begine to convert the bam file and statisc the bam file"

#######################begine with mm10 mapping#############################################################
###sort with name and convert the bam to sam . then make statics the mapping results of mapping results###
samtools sort -n -@ 20 $dir/02_bowtie2_mapping/${sample}_mm10.sorted.bam -O SAM >$dir/02_bowtie2_mapping/${sample}_mm10.sorted.sam
SAMstats --sorted_sam_file $dir/02_bowtie2_mapping/${sample}_mm10.sorted.sam --outf $dir/02_bowtie2_mapping/${sample}.flagstat.qc

echo -e "get the uniq mapped alignments from sorted bam file in mm10 dir" >>$dir/logs/StarBigwik_${sample}.log

######################## post-alignment filtering for SE####
####remove low quanlity mapping including unmapped, not primary alignments, reads failing platform and dumplicates 
########this step used to Remove duplicates (-F1804 keep the duplicates) multi-mapped reads (those with MAPQ <30,using -q in samtools) 
samtools view -bq 30 -F 1804 -@ 20 -o $dir/03_Unique_mapped/mm10/${sample}_mm10.sorted.unique.bam $dir/02_bowtie2_mapping/${sample}_mm10.sorted.bam



##################Picard to process( conda activate gatk ) activate conda envioroment##############
picard MarkDuplicates \
	I=$dir/03_Unique_mapped/mm10/${sample}_mm10.sorted.unique.bam \
	O=${dir}/03_Unique_mapped/mm10/${sample}_marked_duplicates.bam \
	M=${dir}/03_Unique_mapped/mm10/${sample}_dup.qc \
	VALIDATION_STRINGENCY=LENIENT \
	ASSUME_SORTED=TRUE \
	REMOVE_DUPLICATES=FALSE 



#######################index final bam


samtools view -F 1804 -@ 20 -b ${dir}/03_Unique_mapped/mm10/${sample}_marked_duplicates.bam -o ${dir}/03_Unique_mapped/mm10/${sample}.final.bam
samtools index -@ 20 ${dir}/03_Unique_mapped/mm10/${sample}.final.bam ${dir}/03_Unique_mapped/mm10/${sample}.final.bai
samtools sort -n --threads 20 ${dir}/03_Unique_mapped/mm10/${sample}.final.bam -O SAM >${dir}/03_Unique_mapped/mm10/${sample}.final.sam
SAMstats --sorted_sam_file ${dir}/03_Unique_mapped/mm10/${sample}.final.sam --outf ${dir}/03_Unique_mapped/mm10/${sample}.final.flagstat.qc

echo "the process of alignment for  $sample with mm10 is done" >>$dir/logs/StarBigwik_${sample}.log

#make tagdirectory and bigwig from the final bam file##
makeTagDirectory $dir/04_homer/tagDirectory/${sample} ${dir}/03_Unique_mapped/mm10/${sample}.final.bam -tbp 1
makeUCSCfile $dir/04_homer/tagDirectory/${sample} -bigWig /workspace/rsrch2/common_data/Align2Index/StarIndex/mm10/chrNameLength.txt -fsize 1e20 -style rnaseq -strand both -o $dir/04_homer/bigwig/${sample}.bigwig






##########This part not run use picard markDuplicated to do duplicated related process###########
####samtools remove PCR duplicate process "markdup" bam#######################
#######bam processed with sort -n sort with name and the processed with fixmate ###then sort with chr coordinate
###finally processed with markdup to remove duplicates#########################

# cd $dir/03_Unique_mapped/mm10

#samtools sort -n -@ 10 ${sample}_mm10.sorted.unique.bam -o ${sample}_mm10.temp.unique.bam
#samtools fixmate -@ 10 -m ${sample}_mm10.temp.unique.bam ${sample}_mm10.fix.temp.uniq.bam
#samtools sort  -@ 10 ${sample}_mm10.fix.temp.uniq.bam -o ${sample}_mm10.fix.temp.soted.uniq.bam
#samtools markdup -r -s -@ 10 ${sample}_mm10.fix.temp.soted.uniq.bam ${sample}_mm10.rmdup.sorted.unique.bam -f ${sample}_mm10.rmdup.log


#rm *temp*bam
#echo "the process of $sample with mm10 is done" >>$dir/logs/StarBigwik_${sample}.log
