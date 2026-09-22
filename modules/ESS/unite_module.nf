/*
----------------------------------------------------------------------------------------
    ESS_GET_UNITE_DATA

    Downloads UNITE fungal ITS reference sequences and taxonomy data
 ----------------------------------------------------------------------------------------
 */

process ESS_GET_UNITE_DATA {

    tag "Downloading from UNITE"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    conda params.qiime_conda_env
    container null

    output:
    path "unite_sequences.qza", emit: seqs
    path "unite_taxonomy.qza",  emit: taxa
    path "versions.yml",        emit: versions

    script:
    def singleton_flag = params.ess.unite_singletons.toString().toBoolean() ? '--p-singletons' : '--p-no-singletons'
    """
    qiime rescript get-unite-data \
        --p-version ${params.ess.unite_version} \
        --p-taxon-group ${params.ess.unite_taxon_group} \
        --p-cluster-id ${params.ess.unite_cluster_id} \
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