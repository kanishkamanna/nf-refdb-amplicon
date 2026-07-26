process ESS_GET_MIDORI2_DATA {

    tag "Downloading from MIDORI2"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    conda params.qiime_conda_env
    container null

    input:
    val target_gene
    val version

    output:
    path "midori2_sequences.qza", emit: seqs
    path "midori2_taxonomy.qza",  emit: taxa
    path "versions.yml",          emit: versions

    script:
    def version_param = version ? "--p-version '${version}'" : ''
    """
    qiime rescript get-midori2-data \
        --p-target-gene ${target_gene} \
        ${version_param} \
        --o-sequences midori2_sequences.qza \
        --o-taxonomy midori2_taxonomy.qza \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "ESS_GET_MIDORI2_DATA":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}