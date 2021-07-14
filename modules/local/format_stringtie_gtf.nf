// Import generic module functions
include { saveFiles } from './functions'

params.options = [:]

process FORMAT_STRINGTIE_GTF {
    tag "$stringtie_gtf"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'genome', meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "conda-forge::gawk=5.1.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gawk:5.1.0"
    } else {
        container "quay.io/biocontainers/gawk:5.1.0"
    }

    input:
    path stringtie_gtf
    path annotation_gtf

    output:
    path "stringtie.merged.biotypes.gtf", emit: gtf

    script: // compute_boundaries.awk is bundled with the pipeline, in nf-core/rnaseq/bin/
    """
    compute_boundaries.awk \\
        -v toadd=gene \\
        -v fldno=10 \\
        -v keys=gene_name,ref_gene_id \\
        $stringtie_gtf > stringtie_gtf.genes.gff

    cat $stringtie_gtf stringtie_gtf.genes.gff | sort -k1,1 -k4,4n -k5,5rn > new.genes.gff

    awk '
        BEGIN {
            FS = "\t"
        }
        NR == FNR {
            match(\$9, /transcript_id "([^;]*)";*/, tId)
            match(\$9, /biotype "([^;]*)";*/, biotype)
            if (tId[1] in biotypes) {
                next
            }
            else {
                biotypes[tId[1]] = biotype[1]
                next
            }
        }
        {
            if (substr(\$1,1,1) != "#" && \$3 != "gene") {
                match(\$9, /transcript_id "([^;]*)";*/, tId)
                if (tId[1] in biotypes) {
                    print \$0 " transcript_biotype \\""biotypes[tId[1]]"\\";"
                } else {
                    print \$0
                }
            } else {
                print \$0
            }
        }
    ' $annotation_gtf new.genes.gff > stringtie.merged.biotypes.gtf
    """
}
