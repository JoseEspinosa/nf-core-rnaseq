// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process STRINGTIE_MERGE {
    tag "$gtf"
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
    path gtf_to_merge //TODO check how this is done in other modules receiving a list of files (collect)
    path gtf

    output:
    path("new.annotation.gtf"), emit: annotation_gtf
    // tuple val(meta), path("*.transcripts.gtf"), emit: transcript_gtf
    // tuple val(meta), path("*.abundance.txt")  , emit: abundance
    // tuple val(meta), path("*.ballgown")       , emit: ballgown
    path  "*.version.txt"     , emit: version

    script:
    def software = getSoftwareName(task.process)
    """
    stringtie --merge \\
        $gtf_to_merge \\
        -G $gtf \\
        -o new.annotation.gtf \\
        $options.args

    stringtie --version > ${software}.version.txt
    """
}
