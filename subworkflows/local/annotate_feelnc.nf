//
// lncRNAs prediction with FEELnc
//

params.feelnc_filter_options         = [:]
params.feelnc_codpot_options         = [:]
params.assign_feelnc_biotype_options = [:]
params.feelnc_classifier_options     = [:]

include { FEELNC_FILTER         } from '../../modules/local/feelnc_filter'         addParams( options: params.feelnc_filter_options         )
include { FEELNC_CODPOT         } from '../../modules/local/feelnc_codpot'         addParams( options: params.feelnc_codpot_options         )
include { ASSIGN_FEELNC_BIOTYPE } from '../../modules/local/assign_feelnc_biotype' addParams( options: params.assign_feelnc_biotype_options )
include { FEELNC_CLASSIFIER     } from '../../modules/local/feelnc_classifier'     addParams( options: params.feelnc_classifier_options     )

workflow ANNOTATE_FEELNC {
    take:
    new_transcripts_gtf  // channel: /path/to/genome.gtf
    reference_gtf        // channel: /path/to/genome.gtf
    transcript_fasta     // channel: /path/to/transcript.fasta

    main:

    //
    // Filter spurious transcripts (e.g. exons presents in reference annotation possible new isoforms)
    //
    FEELNC_FILTER (
        new_transcripts_gtf,
        reference_gtf
    )

    //
    // Compute the coding potential (CODPLOT) of candidate transcripts
    //
    FEELNC_CODPOT (
        transcript_fasta,
        reference_gtf,
        FEELNC_FILTER.out.candidate_lncrna_gtf
    )

    //
    // Assign the biotype obtained with feelnc to the transcripts
    //
    ASSIGN_FEELNC_BIOTYPE (
        new_transcripts_gtf,
        FEELNC_CODPOT.out.feelnc_predictions_gtf
    )

    //
    // Classifies lncRNAs taking into account neighboring genes
    //
    FEELNC_CLASSIFIER (
        ASSIGN_FEELNC_BIOTYPE.out.coding_transcripts,
        FEELNC_CODPOT.out.feelnc_predictions_gtf
    )

    emit:
    candidate_lncrna_gtf      = FEELNC_FILTER.out.candidate_lncrna_gtf               // path: lncRNA_classes.txt
    feelnc_filter_log         = FEELNC_FILTER.out.feelncfilter_log                   // path: *feelncfilter.log
    feelnc_filter_version     = FEELNC_FILTER.out.version                            // path: *.version.txt

    feelnc_predictions_gtf    = FEELNC_CODPOT.out.feelnc_predictions_gtf             // path: feelnc.predicted.*.gtf
    feelnc_codplot_version    = FEELNC_CODPOT.out.version                            // path: *.version.txt

    feelnc_classification_txt = ASSIGN_FEELNC_BIOTYPE.out.classification_summary_txt // path: feelnc_classification_summary.txt

    lncrna_classes            = FEELNC_CLASSIFIER.out.lncrna_classes                 // path: lncRNA_classes.txt
    feelnc_classifier_log     = FEELNC_CLASSIFIER.out.feelncclassifier_log           // path: *feelncclassifier.log
    feelnc_classifier_version = FEELNC_CLASSIFIER.out.version                        // path: *.version.txt
}
