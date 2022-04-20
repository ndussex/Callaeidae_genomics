#! /bin/bash -l
#SBATCH -A snic2017-1-555
#SBATCH -p core -n 7
#SBATCH -t 2-00:00:00
#SBATCH -C usage_mail

#job id: $SLURM_JOB_ID
#job name (-J): $SLURM_JOB_NAME
#tmp directory: $SNIC_TMP

# Step 1.5: realign reads around indels
#######################################

#java heap size: 2GB less than max. memory, i.e. 6GB per core
mem=36g
bams="/proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams"
ref="/proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/Kokako_genome/Kokako_improved/"

#Usage
#for f in $(ls *merged.bam | grep A* | sed 's/_merged.bam//g' | uniq); do sbatch /proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/scripts/mapping_to_ref/step2_indel_realignment_combined.sh $f; done

#####
##Copy files from home to tmp directory
#####
cp $bams/${1}*_merged.ba* ${SNIC_TMP}/
cp $ref/pseudochromosomes.fasta ${SNIC_TMP}/
cp $ref/pseudochromosomes.fasta.fai ${SNIC_TMP}/
cp $ref/pseudochromosomes.dict ${SNIC_TMP}/
cp /proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/Kokako_genome/B10K-Callaeas_wilsoni.genomic* ${SNIC_TMP}/

#########realign indels for all bam files from one species combined#########
cd ${SNIC_TMP}
REF="pseudochromosomes.fasta"
REF_original=B10K-Callaeas_wilsoni.genomic.fa
java -Xmx${mem} -jar /sw/apps/bioinfo/GATK/3.4.0/GenomeAnalysisTK.jar -T RealignerTargetCreator -R $REF_original $(printf ' -I %s' ${1}*_merged.bam) -o ${1}_realignment_targets.list -nt 6
java -Xmx${mem} -jar /sw/apps/bioinfo/GATK/3.4.0/GenomeAnalysisTK.jar -T IndelRealigner -R $REF_original $(printf ' -I %s' ${1}*_merged.bam) -targetIntervals ${1}_realignment_targets.list -nWayOut _realigned.bam

#####
##Copy files from tmp directory to project directory
#####
cp ${SNIC_TMP}/*realign* $bams


#start batch scripts to check the quality of the new bam files
cd $bams
