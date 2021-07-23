//
// Quantify Stringtie annotated transcripts
//

params.stringtie_merge_options                   = [:]
params.format_stringtie_gtf_options              = [:]
params.stringtie_prepde_options                  = [:]
params.stringtie_quantify_new_annotation_options = [:]
params.stringtie_quantify_reference_options      = [:]

include { STRINGTIE_MERGE      } from '../../modules/nf-core/modules/stringtie/merge/main' addParams( options: params.stringtie_merge_options )
include { FORMAT_STRINGTIE_GTF } from '../../modules/local/format_stringtie_gtf'           addParams( options: params.format_stringtie_gtf_options )
include { STRINGTIE_PREPDE     } from '../../modules/local/stringtie_prepde'               addParams( options: params.stringtie_prepde_options )
include { STRINGTIE as STRINGTIE_NEW_ANNOTATION               } from '../../modules/nf-core/modules/stringtie/stringtie/main' addParams( options: params.stringtie_quantify_new_annotation_options )
include { STRINGTIE as STRINGTIE_REFERENCE                    } from '../../modules/nf-core/modules/stringtie/stringtie/main' addParams( options: params.stringtie_quantify_reference_options )

workflow QUANTIFY_STRINGTIE {
    take:
    stringtie_gtf // channel: /path/to/genome.gtf
    reference_gtf // channel: /path/to/genome.gtf
    ch_genome_bam // channel: /path/to/genome.bam

    main:

    STRINGTIE_MERGE (
        stringtie_gtf,
        reference_gtf
    )

    FORMAT_STRINGTIE_GTF (
        STRINGTIE_MERGE.out.gtf,
        reference_gtf
    )

    STRINGTIE_NEW_ANNOTATION (
        ch_genome_bam,
        FORMAT_STRINGTIE_GTF.out.gtf
    )

    ch_gtf_transcripts = STRINGTIE_NEW_ANNOTATION.out.transcript_gtf

    // ch_gtf_new_annotation.map {
    //         meta, gtf ->
    //             meta.id = meta.id + '.new_annotation'
    //             [ meta, gtf ]
    //     }
    //     .set { ch_gtf_new_annotation }

    STRINGTIE_REFERENCE (
        ch_genome_bam,
        reference_gtf
    )

    ch_gtf_transcripts = ch_gtf_transcripts.mix (STRINGTIE_REFERENCE.out.transcript_gtf)

    // STRINGTIE_REFERENCE
    //     .out
    //     .transcript_gtf
    //     .map {
    //         meta, gtf ->
    //             meta.id = meta.id + '.reference'
    //             [ meta, gtf ]
    //     }
    //     // .mix ( ch_gtf_new_annotation )
    //     .set { ch_gtf_reference }

    // ch_gtf_transcripts = ch_gtf_new_annotation.mix(ch_gtf_reference)
    // ch_gtf_transcripts.view()

    STRINGTIE_PREPDE (
        // STRINGTIE_REFERENCE.out.transcript_gtf
        ch_gtf_transcripts
        // ch_gtf_reference
    )

    emit:
    stringtie_merged_gtf          = STRINGTIE_MERGE.out.gtf                     // path: stringtie.merged.gtf

    stringtie_merged_biotypes_gtf = FORMAT_STRINGTIE_GTF.out.gtf                // path: stringtie.merged.biotypes.gtf

    stringtie_coverage_gtf        = STRINGTIE_NEW_ANNOTATION.out.coverage_gtf   // path: *.coverage.gtf
    stringtie_transcript_gtf      = STRINGTIE_NEW_ANNOTATION.out.transcript_gtf // path: *.transcripts.gtf
    stringtie_abundance           = STRINGTIE_NEW_ANNOTATION.out.abundance      // path: *.abundance.txt
    stringtie_ballgown            = STRINGTIE_NEW_ANNOTATION.out.ballgown       // path: *.ballgown
    stringtie_version             = STRINGTIE_NEW_ANNOTATION.out.version        // path: *.version.txt

    stringtie_coverage_gtf        = STRINGTIE_REFERENCE.out.coverage_gtf        // path: *.coverage.gtf
    stringtie_transcript_gtf      = STRINGTIE_REFERENCE.out.transcript_gtf      // path: *.transcripts.gtf
    stringtie_abundance           = STRINGTIE_REFERENCE.out.abundance           // path: *.abundance.txt
    stringtie_ballgown            = STRINGTIE_REFERENCE.out.ballgown            // path: *.ballgown
    stringtie_version             = STRINGTIE_REFERENCE.out.version             // path: *.version.txt
}
