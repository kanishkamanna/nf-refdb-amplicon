/*
----------------------------------------------------------------------------------------
    ESS_GET_NCBI_DATA

    Downloads NCBI reference sequences and taxonomy data
 ----------------------------------------------------------------------------------------
 */

process ESS_GET_NCBI_DATA {

    tag "Downloading from NCBI"
    label 'process_long'

    publishDir "${params.outdir}/ess/downloaded_data", mode: params.publish_dir_mode

    conda params.qiime_conda_env
    container null

    output:
    path "ncbi_sequences.qza", emit: seqs
    path "ncbi_taxonomy.qza",  emit: taxa
    path "versions.yml",       emit: versions

    script:
    """
    qiime rescript get-ncbi-data \
        --p-query '${params.ess.ncbi_query}' \
        --p-n-jobs ${task.cpus} \
        --o-sequences ncbi_sequences.qza \
        --o-taxonomy ncbi_taxonomy.qza \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "ESS_GET_NCBI_DATA":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}