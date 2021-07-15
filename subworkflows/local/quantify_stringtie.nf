//
// Quantify Stringtie annotated transcripts
//

params.stringtie_merge_options      = [:]
params.format_stringtie_gtf_options = [:]
params.stringtie_quantify_options   = [:]

include { STRINGTIE_MERGE      } from '../../modules/nf-core/software/stringtie/merge/main'     addParams( options: params.stringtie_merge_options      )
include { FORMAT_STRINGTIE_GTF } from '../../modules/local/format_stringtie_gtf'                addParams( options: params.format_stringtie_gtf_options )
include { STRINGTIE            } from '../../modules/nf-core/software/stringtie/stringtie/main' addParams( options: params.stringtie_quantify_options   )

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

    STRINGTIE (
        ch_genome_bam,
        FORMAT_STRINGTIE_GTF.out.gtf
    )

    emit:
    stringtie_merged_gtf          = STRINGTIE_MERGE.out.gtf      // path: stringtie.merged.gtf

    stringtie_merged_biotypes_gtf = FORMAT_STRINGTIE_GTF.out.gtf // path: stringtie.merged.biotypes.gtf

    stringtie_coverage_gtf        = STRINGTIE.out.coverage_gtf   // path: *.coverage.gtf
    stringtie_transcript_gtf      = STRINGTIE.out.transcript_gtf // path: *.transcripts.gtf
    stringtie_abundance           = STRINGTIE.out.abundance      // path: *.abundance.txt
    stringtie_ballgown            = STRINGTIE.out.ballgown       // path: *.ballgown
    stringtie_version             = STRINGTIE.out.version        // path: *.version.txt
}
