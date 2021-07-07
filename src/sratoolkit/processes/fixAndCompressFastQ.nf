nextflow.enable.dsl=2

if(!params.containsKey("test")) {
    binDir = "${workflow.projectDir}/src/sratoolkit/bin/"
} else {
    binDir = ""
}

toolParams = params.sratoolkit

process FIX_AND_COMPRESS_SRA_FASTQ {

    container toolParams.container
    publishDir "${params.global.outdir}/data/raw/fastqs_fixed_and_compressed", mode: 'symlink', overwrite: true
    label 'compute_resources__sratoolkit'
    maxRetries 0

    input:
        tuple val(sraId), file("${sraId}_*.fastq")
    
    output:
        tuple val(sraId), file("${sraId}_*.fastq.gz")
    
    script:
        """
        # Fetch script to fix SRA FASTQ (fasterq-dump does not have the -F option as fastq-dump do to keep original sequence names).
        # Fixing the FASTQ files is required for future pre-processing (e.g.: scATAC-seq pipelines)
        # We cannot source the script directly:
        # - 1) by default it generates help text to stdout
        # - 2) if redirecting the stdout of to the trash i.e. /dev/null, Nextflow will think no files have been generated
        curl -fsSL https://raw.githubusercontent.com/aertslab/single_cell_toolkit/master/fix_sra_fastq.sh -o fix_sra_fastq.sh
        chmod a+x ./fix_sra_fastq.sh
        # Fix the FASTQ files and compress them
        export compress_fastq_threads="${task.cpus}"
        NUM_FASTQ_FILES=\$(ls ./*.fastq | wc -l)
        echo "Fixing and compressing \${NUM_FASTQ_FILES} FASTQ files in parallel with \${compress_fastq_threads} compression threads for each task..."
        echo *.fastq | tr ' ' '\n' | xargs -P "\${NUM_FASTQ_FILES}" -n 1 -I {} ./fix_sra_fastq.sh "{}" "{}.gz" pigz
        """

}
