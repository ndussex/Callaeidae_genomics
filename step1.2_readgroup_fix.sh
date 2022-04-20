#! /bin/bash -l
#SBATCH -A snic2017-1-555
#SBATCH -p core
#SBATCH -n 1
#SBATCH -t 0-10:00:00


#job id: $SLURM_JOB_ID
#job name (-J): $SLURM_JOB_NAME
#tmp directory: $SNIC_TMP

# Step 1.2: adding read group to bam files
#################################################

#########Usage#########
#cd /proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams
#historical
#for f in $(ls AUC2*.rmdupPS.bam | grep AUC2 | sed 's/.bam//g'); do sbatch /proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/scripts/mapping_to_ref/step1.1_readgroup_fix.sh $f; done

file=$1

#java heap size: 2GB less than max. memory, i.e. 6GB per core
mem=6g

#directories
raw_bams="/proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams"
proc_bams="/proj/sllstore2017093/b2016263/b2016263_nobackup/Callaeidae/deepseq_data/bams"

#lookup table for read group ids. Renamed lanes according to flow cell ids used.
table="/proj/sllstore2017093/b2016263/b2016263/private/Callaeidae/scripts/mapping_to_ref/Read_group_info.list"

#####
##Copy files from home to tmp directory
#####
cp $raw_bams/${file}.bam ${SNIC_TMP}/

#########read group format########
#@RG\tID:group1\tSM:sample1\tPL:illumina\tLB:lib1\tPU:unit1

#########sort (Picard), add read group information and index it#########
cd ${SNIC_TMP}
#RGID (String)  Read Group ID Default value: 1. This option can be set to 'null' to clear the default value. Be sure to change from default of 1! Assigned consecutive number for each sample (one number per pair) starting at 1001. Lookup table: column 2.
rgid=`awk '$1 == LOOKUPVAL { print $2 }' LOOKUPVAL=$file $table`

#RGSM (String)  Read Group sample name Required. Lookup table: column 3.
rgsm=`awk '$1 == LOOKUPVAL { print $3 }' LOOKUPVAL=$file $table`

#RGLB (String)  Read Group Library Required. Lookup table: column 4.
rglb=`awk '$1 == LOOKUPVAL { print $4 }' LOOKUPVAL=$file $table`

#RGPU (String)  Read Group platform unit (eg. run barcode) Required. RGPU = RGSM.RGID_date_RGLB. Lookup table: column 5.
rgpu=`awk '$1 == LOOKUPVAL { print $5 }' LOOKUPVAL=$file $table`

java -Xmx${mem} -jar /sw/apps/bioinfo/picard/1.141/milou/picard.jar AddOrReplaceReadGroups INPUT=${file}.bam OUTPUT=${file}_rg.bam RGID=$rgid RGSM=$rgsm RGPL=illumina RGLB=$rglb RGPU=$rgpu SORT_ORDER=coordinate CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT

#########check bam files#########
java -Xmx${mem} -jar /sw/apps/bioinfo/picard/1.141/milou/picard.jar ValidateSamFile INPUT=${file}_rg.bam OUTPUT=${file}_rg_validateSamFile.txt MODE=SUMMARY

module load bioinfo-tools samtools/1.3
samtools flagstat ${file}_rg.bam > ${file}_rg_stats.txt

#########check if read groups have been added successfully#########
samtools view -H ${file}_rg.bam | grep '^@RG' > ${file}_rg.rgcheck1.txt
#samtools view -H ${file}_rg.bam > ${file}_rg.rgcheck2.txt

#####
##Copy files from tmp directory to project directory
#####
cp ${SNIC_TMP}/*rg* $proc_bams
