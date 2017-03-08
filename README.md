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
        -m,--minpos   : trust rates only if the number of positions with GC value
                        exceed this threshold [1000]
        -f,--fraction : subsample this fraction of positions to calculate the 
                        rates [0.1]
        -c,--chroms   : use this comma-separated list of chromosome in calculating
                        the rates only [all]

   where the arguments are:
        reference.fa : the fasta file of reference sequence
        mappable.bed : the file in BED format that includes regions that are mappable 
                       reads of lengths used in this run
        alignments.bam : the alignments of the reads in BAM format 
        
        
    Notes:
    1. Optionally the user can specify the number of positions to sample by
       specifying the -f option as an integer > 1.
    2. A script convert_gem_to_bed with this distribution can be used to generate 
       mappable.bed from the output of gem-mappability.
```

The output from this script is a file which the following columns
```bash
GC     : G+C bases in this region
numpos : number of positions in the (sub)sample with the G+C content specified in column 1
frags  : number of fragments in the (sub)sample with the G+C content specified in column 1
scale  : a multiplier of fragment count that should be used for positions with the G+C content 
        specified in column 1 within the [0,L] range of the position
```
Additionally the last line in the output adds information about L which is useful in the next step.

The second script then takes this file and computes the corrected counts for locations that are 
- mappable and 
- we were able to calculate the scale for the associated GC content.

It also bins the data into bins of size as specified by the user. This is implemented in correct_gc_bias, and can be used as follows:

```bash
    usage:
        correct_gc_bias  [options] reference.fa reference.map rates.txt alignments.bam

    where the options are:
        -h,--help    : print usage and quit
        -d,--debug   : print debug information
        -t,--threads : use these many threads [1]
        -b,--binsize : number of mappable bases in a bin [100]
        -l,--loess   : run additional loess correction 

    where the arguments are:
        reference.fa : the fasta file of reference sequence
        mappable.bed : the file in BED format that includes regions that are mappable 
                       reads of lengths used in this run
        rates.txt    : the output from compute_gc_bias
        alignments.bam : the alignments of the reads in BAM format 

    Notes:
    1. The loess correction is run on the binned counts to remove any bias
       that was not accounted for using the fragment model and could effect
       the data at that resolution.
```

