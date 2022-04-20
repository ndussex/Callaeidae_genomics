#! /bin/bash -l
#SBATCH -A snic2017-1-555
#SBATCH -p core -n 6
#SBATCH -t 2-00:00:00
#SBATCH -C usage_mail

#job id: $SLURM_JOB_ID
#job name (-J): $SLURM_JOB_NAME
#tmp directory: $SNIC_TMP

#java heap size: 2GB less than max. memory, i.e. 6GB per core
mem=6g
bams="/proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams"
ref="/proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/Kokako_genome/Kokako_improved/"

######### Usage #########
#cd /proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams
#for f in $(ls *_dedup.bam | sed 's/_S[0-9]*.rmdupPS_rg_dedup.bam//g' | uniq); do sbatch /proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/scripts/mapping_to_ref/step1.3_merge.sh $f; done
#for f in $(ls *_dedup.bam | sed 's/_L[0-9]*[0-9].rmdup.sorted_rg_dedup.bam//g' | uniq); do sbatch /proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/scripts/mapping_to_ref/step1.3_merge.sh $f; done

#####
##Copy files from home to tmp directory
#####
cp $bams/${1}*_rg_dedup.ba* ${SNIC_TMP}/
cp $ref/pseudochromosomes.fasta ${SNIC_TMP}/
cp $ref/pseudochromosomes.fasta.fai ${SNIC_TMP}/
cp $ref/pseudochromosomes.dict ${SNIC_TMP}/
cp /proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/Kokako_genome/B10K-Callaeas_wilsoni.genomic* ${SNIC_TMP}/

#########Input files#########

#########merge bams per individual#########
cd ${SNIC_TMP}
#java -Xmx${mem} -jar /sw/apps/bioinfo/picard/1.141/milou/picard.jar MergeSamFiles $(printf ' INPUT= %s' ${1}_S[0-9]_originalref.rmdupPS_rg_dedup.bam) OUTPUT=${1}_merged.bam CREATE_INDEX=true

java -Xmx${mem} -jar /sw/apps/bioinfo/picard/1.141/milou/picard.jar MergeSamFiles $(printf ' INPUT= %s' ${1}_L[0-9]*[0-9]*.rmdup.sorted_rg_dedup.bam) OUTPUT=${1}_merged.bam CREATE_INDEX=true


#########check bam files#########
java -Xmx${mem} -jar /sw/apps/bioinfo/picard/1.141/milou/picard.jar ValidateSamFile INPUT=${1}_merged.bam OUTPUT=${1}_merged.txt MODE=SUMMARY
module load bioinfo-tools samtools/1.3
samtools flagstat ${1}_merged.bam > ${1}_merged_stats.txt
#REF="pseudochromosomes.fasta"
REF_original=B10K-Callaeas_wilsoni.genomic.fa
java -Xmx${mem} -jar /sw/apps/bioinfo/GATK/3.4.0/GenomeAnalysisTK.jar -T CountLoci -R $REF_original -I ${1}_merged.bam -o ${1}_merged_CountLoci.txt
java -Xmx${mem} -jar /sw/apps/bioinfo/GATK/3.4.0/GenomeAnalysisTK.jar -T DepthOfCoverage -R $REF_original -I ${1}_merged.bam -o ${1}_merged_DepthOfCoverage.txt

#####
##Copy files from tmp directory to project directory
#####
cp ${SNIC_TMP}/*merged*ba* $bams
cp ${SNIC_TMP}/*txt $bams

