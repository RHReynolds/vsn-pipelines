nextflow.preview.dsl=2

import java.nio.file.Paths

if(!params.containsKey("test")) {
  binDir = "${workflow.projectDir}/src/utils/bin/"
} else {
  binDir = ""
}

process SC__FILE_CONVERTER {

  cache 'deep'
  container params.sc.scanpy.container
  publishDir "${params.outdir}/data", mode: 'symlink'

  input:
    set id, file(f)
  output:
    file "${id}.SC__FILE_CONVERTER.${params.off}"
  script:
    switch(params.iff) {
      case "10x_mtx":
        // Check if output was generated with CellRanger v2 or v3
        f_cellranger_outs_v2 = file("${f.toRealPath()}/${params.useFilteredMatrix ? "filtered" : "raw"}_gene_bc_matrices/")
        f_cellranger_outs_v3 = file("${f.toRealPath()}/${params.useFilteredMatrix ? "filtered" : "raw"}_feature_bc_matrix")
        if(f_cellranger_outs_v2.exists()) {
          genomes = f_cellranger_outs_v2.list()
          if(genomes.size() > 1 || genomes.size() == 0) {
            throw new Exception("None or multiple genomes detected for the output generated by CellRanger v2. Selecting custom genome is currently not implemented.")
          } else {
            f_cellranger_outs_v2 = file(Paths.get(f_cellranger_outs_v2.toString(), genomes[0]))
          }
          f = f_cellranger_outs_v2
        } else if(f_cellranger_outs_v3.exists()) {
          f = f_cellranger_outs_v3
        }
        break;
      case "csv":
        break;
      case "tsv":
        break;
      default:
        throw new Exception("The given input format ${params.iff} is not recognized.")
        break;
    }
    """
    ${binDir}sc_file_converter.py \
       --input-format $params.iff \
       --output-format $params.off ${f} "${id}.SC__FILE_CONVERTER.${params.off}"
    """
}

process SC__FILE_CONVERTER_HELP {
  container params.sc.scanpy.container
  output:
    stdout()
  script:
    """
    ${workflow.projectDir}/src/utils/bin/sc_file_converter.py -h | awk '/-h/{y=1;next}y'
    """
}

process SC__FILE_CONCATENATOR() {

  container params.sc.scanpy.container
  publishDir "${params.outdir}/data", mode: 'symlink'

  input:
    file(f)
  output:
    file "${params.project_name}.SC__FILE_CONCATENATOR.${params.off}"
  script:
    """
    ${workflow.projectDir}/src/utils/bin/sc_file_concatenator.py \
      --file-format $params.off \
      ${(params.containsKey('join')) ? '--join ' + params.join : ''} \
      --output "${params.project_name}.SC__FILE_CONCATENATOR.${params.off}" $f
    """
}

process SC__STAR_CONCATENATOR() {

  container "docker://aertslab/sctx-scanpy:0.5.0"
  publishDir "${params.outdir}/data", mode: 'symlink'

  input:
    file(f)
  output:
    tuple id, file("${params.project_name}.SC__STAR_CONCATENATOR.${params.off}")
  script:
    id = params.project_name
    """
    ${workflow.projectDir}/src/utils/bin/sc_star_concatenator.py \
      --stranded $params.stranded \
      --output "${params.project_name}.SC__STAR_CONCATENATOR.${params.off}" $f
    """
}

include getBaseName from './files.nf'

process SC__FILE_ANNOTATOR() {

  container params.sc.scanpy.container
  publishDir "${params.outdir}/data", mode: 'symlink'

  input:
    file(f)
    file(metaDataFilePath)
  output:
    file "${getBaseName(f)}.SC__FILE_ANNOTATOR.${params.off}"
  script:
    """
    ${workflow.projectDir}/src/utils/bin/sc_file_annotator.py \
      ${(params.containsKey('type')) ? '--type ' + params.type : ''} \
      ${(params.containsKey('metaDataFilePath')) ? '--meta-data-file-path ' + metaDataFilePath.getName() : ''} \
      $f \
      "${getBaseName(f)}.SC__FILE_ANNOTATOR.${params.off}"
    """
}
