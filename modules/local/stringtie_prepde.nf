// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process STRINGTIE_PREPDE {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::stringtie=2.1.4" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/stringtie:2.1.4--h7e0af3c_0"
    } else {
        container "quay.io/biocontainers/stringtie:2.1.4--h7e0af3c_0"
    }

    input:
    tuple val(meta), path(transcript_gtf) // should take the output of stringtie -o transcripts

    output:
    tuple val(meta), path ('*.genes_counts.csv')      , emit: genes_counts_csv
    tuple val(meta), path ('*.transcripts_counts.csv'), emit: transcripts_counts_csv
    path "*.version.txt"                              , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"

    """
    mkdir gtf
    mv $transcript_gtf gtf

    prepDE.py -i . \\
        -g ${prefix}.genes_counts.csv \\
        -t ${prefix}.transcripts_counts.csv \\
        -p gtf \\
        $options.args

    stringtie --version > ${software}.version.txt
    """
}
