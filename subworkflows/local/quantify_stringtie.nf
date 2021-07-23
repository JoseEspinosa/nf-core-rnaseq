//
// Quantify Stringtie annotated transcripts
//

params.stringtie_merge_options                   = [:]
params.format_stringtie_gtf_options              = [:]
params.stringtie_quantify_new_annotation_options = [:]
params.stringtie_quantify_reference_options      = [:]
params.stringtie_prepde_new_annotation_options   = [:]
params.stringtie_prepde_reference_options        = [:]

include { STRINGTIE_MERGE      } from '../../modules/nf-core/modules/stringtie/merge/main' addParams( options: params.stringtie_merge_options )
include { FORMAT_STRINGTIE_GTF } from '../../modules/local/format_stringtie_gtf'           addParams( options: params.format_stringtie_gtf_options )
include { STRINGTIE as STRINGTIE_NEW_ANNOTATION               } from '../../modules/nf-core/modules/stringtie/stringtie/main' addParams( options: params.stringtie_quantify_new_annotation_options )
include { STRINGTIE as STRINGTIE_REFERENCE                    } from '../../modules/nf-core/modules/stringtie/stringtie/main' addParams( options: params.stringtie_quantify_reference_options )
include { STRINGTIE_PREPDE as STRINGTIE_PREPDE_NEW_ANNOTATION } from '../../modules/local/stringtie_prepde'                   addParams( options: params.stringtie_prepde_new_annotation_options )
include { STRINGTIE_PREPDE as STRINGTIE_PREPDE_REFERENCE      } from '../../modules/local/stringtie_prepde'                   addParams( options: params.stringtie_prepde_reference_options )

workflow QUANTIFY_STRINGTIE {
    take:
    stringtie_gtf // channel: /path/to/genome.gtf
    reference_gtf // channel: /path/to/genome.gtf
    ch_genome_bam // channel: /path/to/genome.bam

    main:

    //
    // Merges the gtf files annotated using the bam files with the reference
    //
    STRINGTIE_MERGE (
        stringtie_gtf,
        reference_gtf
    )

    //
    // Reformats the merged gtf: gene boundaries and biotypes
    //
    FORMAT_STRINGTIE_GTF (
        STRINGTIE_MERGE.out.gtf,
        reference_gtf
    )

    //
    // Quantifies transcript expression of the new annotation
    //
    STRINGTIE_NEW_ANNOTATION (
        ch_genome_bam,
        FORMAT_STRINGTIE_GTF.out.gtf
    )

    //
    // Generates the count matrices for genes and transcripts with the output of stringtie quantification
    // on the new annotated transcripts
    //
    STRINGTIE_PREPDE_NEW_ANNOTATION (
        STRINGTIE_NEW_ANNOTATION.out.transcript_gtf
    )

    //
    // Quantifies transcript expression of the reference annotation
    //
    STRINGTIE_REFERENCE (
        ch_genome_bam,
        reference_gtf
    )

    //
    // Generates the count matrices for genes and transcripts with the output of stringtie quantification
    // on only the reference transcripts
    //
    STRINGTIE_PREPDE_REFERENCE (
        STRINGTIE_REFERENCE.out.transcript_gtf
    )

    emit:
    stringtie_merged_gtf                               = STRINGTIE_MERGE.out.gtf                                    // path: stringtie.merged.gtf

    stringtie_merged_biotypes_gtf                      = FORMAT_STRINGTIE_GTF.out.gtf                               // path: stringtie.merged.biotypes.gtf

    stringtie_new_annotation_coverage_gtf              = STRINGTIE_NEW_ANNOTATION.out.coverage_gtf                  // path: *.coverage.gtf
    stringtie_new_annotation_transcript_gtf            = STRINGTIE_NEW_ANNOTATION.out.transcript_gtf                // path: *.transcripts.gtf
    stringtie_new_annotation_abundance                 = STRINGTIE_NEW_ANNOTATION.out.abundance                     // path: *.abundance.txt
    stringtie_new_annotation_ballgown                  = STRINGTIE_NEW_ANNOTATION.out.ballgown                      // path: *.ballgown
    stringtie_new_annotation_version                   = STRINGTIE_NEW_ANNOTATION.out.version                       // path: *.version.txt

    stringtie_reference_coverage_gtf                   = STRINGTIE_REFERENCE.out.coverage_gtf                       // path: *.coverage.gtf
    stringtie_reference_transcript_gtf                 = STRINGTIE_REFERENCE.out.transcript_gtf                     // path: *.transcripts.gtf
    stringtie_reference_abundance                      = STRINGTIE_REFERENCE.out.abundance                          // path: *.abundance.txt
    stringtie_reference_ballgown                       = STRINGTIE_REFERENCE.out.ballgown                           // path: *.ballgown
    stringtie_reference_version                        = STRINGTIE_REFERENCE.out.version                            // path: *.version.txt

    stringtie_prepde_new_annotation_gene_counts        = STRINGTIE_PREPDE_NEW_ANNOTATION.out.genes_counts_csv       // path: *.genes_counts.csv
    stringtie_prepde_new_annotation_transcripts_counts = STRINGTIE_PREPDE_NEW_ANNOTATION.out.transcripts_counts_csv // path: *.transcripts_counts.csv

    stringtie_prepde_reference_gene_counts             = STRINGTIE_PREPDE_REFERENCE.out.genes_counts_csv            // path: *.genes_counts.csv
    stringtie_prepde_reference_transcripts_counts      = STRINGTIE_PREPDE_REFERENCE.out.transcripts_counts_csv      // path: *.transcripts_counts.csv
}
