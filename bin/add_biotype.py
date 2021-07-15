#!/usr/bin/env python

import sys
import re
import argparse

def __get_arguments():
    __description__ = "Scan annotations file for biotypes and append the corresponding transcript_biotype field to gene file entries"
    parser = argparse.ArgumentParser(description=__description__)
    parser.add_argument("annotations_gtf", type=str, help="annotation file")
    parser.add_argument("genes_gff",	   type=str, help="gene file")
    return parser.parse_args()

args = __get_arguments()
biotypes = {}

with open(args.annotations_gtf) as annot_fh:
    for line in annot_fh:
        fields = line.strip().split('\t')
        if fields[2] != "transcript": continue
        tId = re.search('transcript_id "([^;]*)";*', fields[8] )
        biotype = re.search('biotype "([^;]*)";*', fields[8] )
        if tId.group(1) not in biotypes:
            biotypes[tId.group(1)] = biotype.group(1)

with open(args.genes_gff) as genes_fh:
    for line in genes_fh:
        line = line.strip('\n')
        fields = line.split('\t')
        if not fields[0].startswith('#') and fields[2] != "gene":
            tId = re.search('transcript_id "([^;]*)";*', fields[8] )
            if tId.group(1) in biotypes:
                print(line, 'transcript_biotype "{}";'.format(biotypes[tId.group(1)]))
            else:
                print(line)
        else:
            print(line)
