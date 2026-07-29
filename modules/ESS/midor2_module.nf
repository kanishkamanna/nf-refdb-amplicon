process ESS_GET_MIDORI2_DATA {
    label 'process_low'
    tag "Downloading from MIDORI2"
    conda params.qiime_conda_env

    input:
    val target_gene

    output:
    path "midori2_sequences/", emit: sequences_collection
    path "midori2_taxonomy/",  emit: taxonomy_collection
    path "versions.yml",       emit: versions

    script:
    """
    qiime rescript get-midori2-data \
        --p-mito-gene ${target_gene} \
        --o-midori2-sequences midori2_sequences/ \
        --o-midori2-taxonomy midori2_taxonomy/ \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "ESS_GET_MIDORI2_DATA":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}