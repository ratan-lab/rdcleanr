# rdcleanr
Implementation of a single position models to remove bias in NGS

### Installation
Type

```bash
make
```

to copy the binaries to a "bin" directory in the distribution. Ancilliary
scripts can be found in the "scripts" folder of the distribution.

### Implementation
Substantial biases plague sequences generated using massively parallel sequencing technologies, and effect downstream processing and interpretation of such data. Currently, this tool is designed to handle bias introduced due to varying GC content in the genome, but in the future we will incorporate other sources that effect short-read sequencing. The current method to deal with GC bias is similar to that described in Benjamini and Speed, 2012. In that article the authors showed that GC-bias is run-specific, and base composition around the two fragment break points correlates with it.    

This implementation proceeds in two separate steps. The first step takes in the alignments as inputs and calculate a fragment rate corresponsind to GC values in the range [0,L], where L is the average fragment length calculated from the paired-end dataset. We currently do not handle single-end reads. This is implemented in a python script compute_gc_bias which can be used as follows

```bash
    usage:
     compute_gc_bias [options] reference.fa mappable.bed alignments.bam

    where the options are:
        -h,--help     : print usage and quit
        -d,--debug    : print debug information
        -t,--threads  : use these many threads [1]
        -s,--shift    : ignore these many bases at the edge of the fragments [0]
        -m,--minpos   : trust rates only if the number of positions with GC
                        value exceed this threshold [1000]
        -f,--fraction : subsample this fraction of positions to calculate the 
                        rates [0.01]
        -c,--chroms   : use this comma-separated list of chromosome in 
                        calculating the rates only [all]
        -v,--version  : print version and exit
        -q,--quality  : do not consider locations where the mean MQ is less
                        than this threshold [30]
        -a,--avgcov   : average coverage to expect in the BAM file [auto]

   where the arguments are:
        reference.fa : the fasta file of reference sequence
        mappable.bed : the file in BED format that includes regions that are
                       mappable reads of lengths used in this run
        alignments.bam : the alignments of the reads in BAM format 

    Notes:
    1. Optionally the user can specify the number of positions to sample by
       specifying the -f option as an integer > 1.
    2. A script convert_gem_to_bed with this distribution can be used to 
       generate mappable.bed from the output of gem-mappability.
    3. The average coverage is calculated if it is not specified by the user. 
```

The output from this script is a file which the following columns
```bash
GC     : G+C bases in this region
numpos : number of positions in the (sub)sample with the G+C content specified in column 1
frags  : number of fragments in the (sub)sample with the G+C content specified in column 1
scale1 : a multiplier of fragment count that should be used for positions with the G+C content  specified in column 1 within the [0,L] range of the position based on subsampling
scale2 : a multiplier of fragment count that should be used for positions with the G+C content specified in column 1 after smoothing scale1
```
The second script then takes this file and computes the corrected counts for locations (stretches of locations) that are mappable.

It also bins the data into bins of size as specified by the user. This is implemented in correct_gc_bias, and can be used as follows:

```bash
    usage:
    correct_gc_bias [options] output.txt reference.fa reference.map rates.txt
alignments.bam

    where the options are:
        -h,--help    : print usage and quit
        -d,--debug   : print debug information
        -t,--threads : use these many threads [1]
        -b,--binsize : number of mappable bases in a bin [100]
        -x,--noloess : do not run additional loess correction 
        -m,--minspan : ignore mappable sections smaller than this [40]
        -v,--version : print version and exit
    
    where the arguments are:
        output.txt   : the output file
        reference.fa : the fasta file of reference sequence
        mappable.bed : the file in BED format that includes regions that are
                       mappable reads of lengths used in this run
        rates.txt    : the output from compute_gc_bias
        alignments.bam : the alignments of the reads in BAM format 

    Notes:
    1. The loess correction is run on the binned counts to remove any bias
       that was not accounted for using the fragment model and could effect
       the data at that resolution.
    2. The --minspan defaults work with reads aligned using BWA mem algorithm,
       which requires a seed of 19. 
    3. When using a reference.map that has all regions except the N's in the 
       reference genome, the user should use --quality 0 so that all reads, and 
       not only the uniquely mapped ones are counted.
```

### Notes
gem-mappability (http://algorithms.cnag.cat/wiki/The_GEM_library) can be used to compute the mappability of each region of a reference genome. In order to convert the output of gem-mappability to a format accepted by rdcleanr, it should be converted to a BED format file with only the mappable locations. If the output from gem-mappability is reference.gem.mappability, and the gem index is called reference.index.gem, then the following steps should be used

```bash
gem-2-wig -I reference.index.gem -i reference.gem.mappability -o tmp
wigToBigWig tmp.wig tmp.sizes tmp.bigwig
bigWigToBedGraph tmp.bigwig tmp.bedgraph
cat tmp.bedgraph | awk '$$4 == 1' | cut -f 1,2,3 > reference.map.bed
rm tmp.wig tmp.sizes tmp.bigwig tmp.bedgraph
```
