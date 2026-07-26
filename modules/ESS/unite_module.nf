process ESS_GET_UNITE_DATA {

    tag "Downloading from UNITE"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    conda params.qiime_conda_env
    container null

    input:
    val version
    val taxon_group
    val cluster_id
    val singletons

    output:
    path "unite_sequences.qza", emit: seqs
    path "unite_taxonomy.qza",  emit: taxa
    path "versions.yml",        emit: versions

    script:
    def singleton_flag = singletons.toString().toBoolean() ? '--p-include-singletons' : '--p-no-include-singletons'
    """
    qiime rescript get-unite-data \
        --p-version ${version} \
        --p-taxon-group ${taxon_group} \
        --p-cluster-id ${cluster_id} \
        ${singleton_flag} \
        --o-sequences unite_sequences.qza \
        --o-taxonomy unite_taxonomy.qza \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "ESS_GET_UNITE_DATA":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}