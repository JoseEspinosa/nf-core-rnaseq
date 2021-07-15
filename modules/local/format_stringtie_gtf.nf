// Import generic module functions
include { saveFiles } from './functions'

params.options = [:]

process FORMAT_STRINGTIE_GTF {
    tag "$stringtie_gtf"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'genome', meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    path stringtie_gtf
    path annotation_gtf

    output:
    path "stringtie.merged.biotypes.gtf", emit: gtf

    script: // compute_boundaries.awk and add_biotype.py are bundled with the pipeline, in nf-core/rnaseq/bin/
    """
    compute_boundaries.awk \\
        -v toadd=gene \\
        -v fldno=10 \\
        -v keys=gene_name,ref_gene_id \\
        $stringtie_gtf > stringtie_gtf.genes.gff

    cat $stringtie_gtf stringtie_gtf.genes.gff | sort -k1,1 -k4,4n -k5,5rn > new.genes.gff

    add_biotype.py \\
        $annotation_gtf \\
        new.genes.gff > stringtie.merged.biotypes.gtf
    """
}
