// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

def VERSION = '0.2' // Not possible to retrieve version from tool

process FEELNC_CODPOT {
    tag "$lncrna_gtf"
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
    path genome //gtf or fasta
    path coding_annotation_gtf //gtf or fasta
    path lncrna_gtf

    output:
    path "exons.*.gtf"  , emit: lncrna_gtf
    path "*.version.txt", emit: version //TODO how to get version

    script:
    def software = getSoftwareName(task.process)
    """
    path_to_codpot=\$(which FEELnc_codpot.pl)
    export FEELNCPATH=\${path_to_codpot%/*}/..

    FEELnc_codpot.pl \\
        --genome $genome \\
        --mRNAfile $coding_annotation_gtf \\
        --infile $lncrna_gtf \\
        --biotype transcript_biotype=protein_coding \\
        --numtx 5000,5000 \\
        --kmer 1,2,3,6,9,12 \\
        --outdir . \\
        --outname exons \\
        --mode shuffle \\
        --spethres=0.98,0.98 \\
        $options.args

    echo $VERSION > ${software}.version.txt
    """
}
