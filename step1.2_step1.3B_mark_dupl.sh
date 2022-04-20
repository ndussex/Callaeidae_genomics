#! /bin/bash -l
#SBATCH -A snic2017-1-555
#SBATCH -p core -n 3
#SBATCH -t 0-20:00:00
#SBATCH -C usage_mail

#job id: $SLURM_JOB_ID
#job name (-J): $SLURM_JOB_NAME
#tmp directory: $SNIC_TMP

#java heap size: 2GB less than max. memory, i.e. 6GB per core
mem=12g
bams="/proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams"
ref="/proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/Kokako_genome/Kokako_improved/"

#########Input files#########
#Bam files incl. read groups, sorted plus indexed

######### Usage #########
#cd /proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams

###step 1.2###
#for f in $(ls *_rg.bam | sed 's/.bam//g'); do sbatch //proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/scripts/mapping_to_ref/step1.2_step1.3B_mark_dupl.sh $f; done

#####
##Copy files from home to tmp directory
#####
cp $bams/${1}.ba* ${SNIC_TMP}/
cp $ref/pseudochromosomes.fasta ${SNIC_TMP}/
cp $ref/pseudochromosomes.fasta.fai ${SNIC_TMP}/
cp $ref/pseudochromosomes.dict ${SNIC_TMP}/
cp /proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/Kokako_genome/B10K-Callaeas_wilsoni.genomic* ${SNIC_TMP}/

#########mark duplicates and index it#########
cd ${SNIC_TMP}
java -Xmx${mem} -jar /sw/apps/bioinfo/picard/1.141/milou/picard.jar MarkDuplicates INPUT=${1}.bam OUTPUT=${1}_dedup.bam METRICS_FILE=metrics.txt CREATE_INDEX=true

#########check if bam files are intact#########
java -Xmx${mem} -jar /sw/apps/bioinfo/picard/1.141/milou/picard.jar ValidateSamFile INPUT=${1}_dedup.bam OUTPUT=${1}_dedup_validateSamFile.txt MODE=SUMMARY

module load bioinfo-tools samtools/1.3
samtools flagstat ${1}_dedup.bam > ${1}_dedup_stats.txt

REF="pseudochromosomes.fasta"
REF_original=B10K-Callaeas_wilsoni.genomic.fa
java -Xmx${mem} -jar /sw/apps/bioinfo/GATK/3.4.0/GenomeAnalysisTK.jar -T CountLoci -R $REF_original -I ${1}_dedup.bam -o ${1}_dedup_CountLoci.txt
java -Xmx${mem} -jar /sw/apps/bioinfo/GATK/3.4.0/GenomeAnalysisTK.jar -T DepthOfCoverage -R $REF_original -I ${1}_dedup.bam -o ${1}_dedup_DepthOfCoverage.txt

#####
##Copy files from tmp directory to project directory
#####
cp ${SNIC_TMP}/*dedup*bam  $bams

