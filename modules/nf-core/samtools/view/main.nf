process SAMTOOLS_VIEW {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::samtools=1.17"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(input), path(index)
    tuple val(meta2), path(fasta)
    path qname

    output:
    tuple val(meta), path("${prefix}.bam"),                                    emit: bam,            optional: true
    tuple val(meta), path("${prefix}.cram"),                                   emit: cram,           optional: true
    tuple val(meta), path("${prefix}.sam"),                                    emit: sam,            optional: true
    tuple val(meta), path("${prefix}.${file_type}.bai"),                       emit: bai,            optional: true
    tuple val(meta), path("${prefix}.${file_type}.csi"),                       emit: csi,            optional: true
    tuple val(meta), path("${prefix}.${file_type}.crai"),                      emit: crai,           optional: true
    tuple val(meta), path("${prefix}.unselected.${file_type}"),                emit: unselected,       optional: true
    tuple val(meta), path("${prefix}.unselected.${file_type}.{bai,csi,crsi}"), emit: unselected_index, optional: true
    path  "versions.yml",                                                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--reference ${fasta}" : ""
    file_type = args.contains("--output-fmt sam") ? "sam" :
                    args.contains("--output-fmt bam") ? "bam" :
                    args.contains("--output-fmt cram") ? "cram" :
                    input.getExtension()
    readnames = qname ? "--qname-file ${qname} --output-unselected ${prefix}.unselected.${file_type}": ""
    if ("$input" == "${prefix}.${file_type}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    samtools \\
        view \\
        --threads ${task.cpus-1} \\
        ${reference} \\
        ${readnames} \\
        $args \\
        -o ${prefix}.${file_type} \\
        $input \\
        $args2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    touch ${prefix}.cram

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
