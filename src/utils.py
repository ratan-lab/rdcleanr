from sys import stderr
from time import time
from math import sqrt, ceil
from bitarray import bitarray
from random import random

import pysam as ps

start_time = time()

def tabout(*args):
    """Return a tab-delimited string from the list
    """
    output = [str(x) for x in args if x != None]
    return "\t".join(output)

def update(message):
    """Print a formatted information message.
    """
    print >> stderr, message
    print >> stderr, "%d sec. elapsed" % (time() - start_time)
    print >> stderr, ""

def read_mq_map(mapname, chromosome, length):
    mqmap = bitarray([0]* length)

    # read in the mappability information marking the mappable bases
    with open(mapname, 'r') as f:
        for line in f:
            chrom,start,stop = line.strip().split("\t")
            if chrom == chromosome:
                mqmap[int(start):int(stop)] = True

    return mqmap
