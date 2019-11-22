nextflow.preview.dsl=2

process SC__DROP_SEQ_TOOLS__CONVERT_TO_REFFLAT {
    
    container params.sc.dropseqtools.container
    publishDir "${params.global.outdir}/00.refdata", mode: 'symlink'
    clusterOptions "-l nodes=1:ppn=${params.global.threads} -l walltime=1:00:00 -A ${params.global.qsubaccount}"

    input:
    file(annotation)
    file(seqdict)
    
    output:
    file("${seqdict.baseName}.refFlat")
    
    script:
    """
    ConvertToRefFlat \
        ANNOTATIONS_FILE=${annotation} \
        SEQUENCE_DICTIONARY=${seqdict} \
        OUTPUT=${seqdict.baseName}.refFlat
    """

}