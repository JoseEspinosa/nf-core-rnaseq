// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process ASSIGN_FEELNC_BIOTYPE {
    tag "$feelnc_gtf"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "conda-forge::gawk=5.1.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gawk:5.1.0"
    } else {
        container "quay.io/biocontainers/gawk:5.1.0"
    }

    input:
    path feelnc_gtf
    path exons_biotypes

    output:
    path "coding_transcripts.gtf", emit: coding_transcripts

    script:
    """
    # Enrich assembled annotation with new biotypes
    cp $feelnc_gtf novel.feelnc_biotype.gff
    for biotype in lncRNA mRNA noORF TUCp; do
        if [ -f exons.\$biotype.gtf ]; then
            awk -v biotype=\$biotype '
                BEGIN {
                    FS = "\t"
                }
                NR == FNR {
                    match(\$9, /transcript_id "([^;]*)";*/, tId)
                    transcripts[tId[1]] = 0
                    next
                }
                {
                    match(\$9, /transcript_id "([^;]*)";*/, tId)
                    if (tId[1] in transcripts) {
                        # Check if there is already a biotype in the annotation
                        match(\$9, /biotype=([^;]*)*/, oldBiotype)
                        if (oldBiotype[1]) {
                            print \$0
                        } else {
                            print \$0 " feelnc_biotype \\"" biotype "\\";"
                        }
                    } else {
                        print \$0
                    }
                }
            ' exons."\$biotype".gtf novel.feelnc_biotype.gff > tmp.gff
            mv tmp.gff novel.feelnc_biotype.gff
        fi
    done

    # Make a summary of the FEELnc classification
    awk '
        BEGIN {
            FS = OFS = "\t"
            feelnc_classes["lncRNA"] = feelnc_classes["noORF"] = feelnc_classes["mRNA"] = feelnc_classes["TUCp"] = feelnc_classes[""] = 0
        }
        \$3 == "transcript" {
            ++nb_transcripts
            match(\$9, /feelnc_biotype "([^;]*)";*/, feelnc_biotype)
            ++feelnc_classes[feelnc_biotype[1]]
        }
        END {
            print "Lnc transcripts",feelnc_classes["lncRNA"]
            print "Coding transcripts from FEELnc classification",feelnc_classes["mRNA"]
            print "Transcripts with no ORF",feelnc_classes["noORF"]
            print "Transcripts of unknown coding potential",feelnc_classes["TUCp"]
        }
    ' novel.feelnc_biotype.gff > feelnc_classification_summary.txt

    # Filter coding transcripts for lnc-messenger interactions
    grep -E '#|transcript_biotype "protein_coding"|feelnc_biotype "mRNA"' $feelnc_gtf > coding_transcripts.gtf
    """
}
