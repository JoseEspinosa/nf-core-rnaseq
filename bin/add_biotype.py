#!/usr/bin/env python

import sys
import re
import argparse

def __get_arguments(args=None):
    __description__ = "Scan annotations file for biotypes and append the corresponding transcript_biotype field to gene file entries"
    __Epilog__ = "Example usage: python add_biotype.py <ANNOTATION_GTF> <REFERENCE_GFF>"

    parser = argparse.ArgumentParser(description=__description__, epilog=__Epilog__)
    parser.add_argument("ANNOTATION_GTF", type=str, help="annotation file")
    parser.add_argument("REFERENCE_GFF",  type=str, help="reference genes file")
    return parser.parse_args(args)

def add_biotype(annotation_gtf, reference_gff):
    """
    This function assigns the transcript biotype to the de novo transcripts
    of the annotation file if already present in the reference annotation

    This script is adapted from the FAANG/analysis-TAGADA pipeline
    """

    args = __get_arguments()
    biotypes = {}

    with open(annotation_gtf) as annot_fh:
        for line in annot_fh:
            fields = line.strip().split('\t')
            if fields[2] != "transcript": continue
            tId = re.search('transcript_id "([^;]*)";*', fields[8] )
            biotype = re.search('biotype "([^;]*)";*', fields[8] )
            if tId.group(1) not in biotypes:
                biotypes[tId.group(1)] = biotype.group(1)

    with open(reference_gff) as genes_fh:
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

def main(args=None):
    args = __get_arguments(args)
    add_biotype(args.ANNOTATION_GTF, args.REFERENCE_GFF)

if __name__ == "__main__":
    sys.exit(main())
