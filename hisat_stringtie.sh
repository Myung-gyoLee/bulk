#!/bin/bash
#####################################################################
### HISAT2 StringTie2

name="samplelist"
main=/rnapipe

hisat_dir=/data/utils/hisat2-2.2.1
sam_dir=/data/utils/samtools-1.14
qualimap_dir=/data/utils/qualimap_v2.2.1
stringtie_dir=/data/utils/stringtie-2.2.0.Linux_x86_64

hindex=/data/sequencing_data/ref/mus_musculus/hisat
tout=${main}/trimmed
sout=${main}/alignedsam
about=${main}/alignedbam
tieout=${main}/alignedbam
qcout=${main}/rnaqc
gtfout=${main}/gtf

mkdir -p ${tout}
mkdir -p ${sout}
mkdir -p ${about}
mkdir -p ${tieout}
mkdir -p ${qcout}
mkdir -p ${gtfout}

while read name
do 
nohup time ${hisat_dir}/hisat2 -p 24 --dta -x ${hindex}/genome_tran  --no-spliced-alignment  -U ${tout}/${name}.bbduk.fq -S ${sout}/${name}_aligned.sam 1>${name}_hisat2_log.txt 2>&1

echo 'hisat2 SAM to BAM '${name}
${sam_dir}/samtools view -bS ${sout}/${name}_aligned.sam | ${sam_dir}/samtools sort -@ 8 -o ${about}/${name}_aligned.sorted.bam

echo 'RNA-seq QC '${name}
nohup time ${qualimap_dir}/qualimap rnaseq -bam ${about}/${name}_aligned.sorted.bam -gtf ${hindex}/genome.gtf -outdir ${qcout}/${name}_rnaseq_qc_results --java-mem-size=4G 1>${name}_qualimap_log.txt 2>&1
# cp ${name}_rnaseq_qc_results/images_qualimapReport/*Total?.png ../../coverage_plot/${name}_coverage.png

echo 'Quantification '${name}
nohup time ${stringtie_dir}/stringtie ${about}/${name}_aligned.sorted.bam -p 24 -l ${name} -o ${gtfout}/${name}.gtf -G ${hindex}/genome.gtf -A  ${gtfout}/${name}_abundant.gtf -C  ${gtfout}/${name}_coverage.gtf -e 1>${name}_stringtie_log.txt 2>&1

done < $main/fname.txt &
