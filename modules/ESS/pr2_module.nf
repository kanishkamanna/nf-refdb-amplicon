process ESS_GET_PR2_DATA {

    tag "Downloading from PR2"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    conda params.qiime_conda_env
    container null

    output:
    path "pr2_sequences.qza", emit: seqs
    path "pr2_taxonomy.qza",  emit: taxa
    path "versions.yml",      emit: versions

    script:
    def version_param = params.ess.pr2_version ? "--p-version '${params.ess.pr2_version}'" : ''
    """
    qiime rescript get-pr2-data \
        ${version_param} \
        --o-pr2-sequences pr2_sequences.qza \
        --o-pr2-taxonomy pr2_taxonomy.qza \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "ESS_GET_PR2_DATA":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}