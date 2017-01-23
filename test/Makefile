all:reference simreads align correct

# BWA, SAMTOOLS and PIRS should be in PATH

reference:
	./../scripts/create_reference_sequence -g .80 1000000 > reference.fa
	bwa index reference.fa
	samtools faidx reference.fa

simreads:
	pirs simulate -l 100 -x 30 -m 300 -o illumina -z -n reference.fa

align:
	bwa mem reference.fa illumina_100_300_1.fq.gz illumina_100_300_2.fq.gz \
	| samtools view -bST reference.fa - \
	| samtools sort - alignment
	samtools index alignment.bam

correct:
	./../src/compute_gc_bias -s 2 reference.fa reference.bed alignment.bam \
		> rates.txt
	./../src/correct_gc_bias -b 1000 reference.fa reference.bed rates.txt \
		alignment.bam > corrected.txt
	./../scripts/plot_gc.R corrected.txt gc.png

.PHONY: clean

clean:
	ls -1 | grep -v Makefile | xargs rm
