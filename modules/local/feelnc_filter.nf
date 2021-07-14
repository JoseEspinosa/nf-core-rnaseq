// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

def VERSION = '0.2' // Not possible to retrieve version from tool

process FEELNC_FILTER {
    tag "$new_annotation_gtf"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::feelnc=0.2" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/feelnc:0.2--pl526_0"
    } else {
        container "quay.io/biocontainers/feelnc:0.2--pl526_0"
    }

    input:
    path new_annotation_gtf
    path coding_annotation_gtf

    output:
    path "candidate_lncrna.gtf", emit: candidate_lncrna_gtf
    path "*.version.txt"       , emit: version

    script:
    def software = getSoftwareName(task.process)
    """
    FEELnc_filter.pl \\
        --infile $new_annotation_gtf \\
        --mRNAfile $coding_annotation_gtf \\
        $options.args > candidate_lncrna.gtf

    echo $VERSION > ${software}.version.txt
    """
}
