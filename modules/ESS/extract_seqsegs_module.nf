process ESS_EXTRACT_READS {

    tag "Extracting initial sequence segments via primer search"
    label 'ess_iterate'

    publishDir "${params.outdir}/ess/initial_segments", mode: params.publish_dir_mode

    input:
    path seqs

    output:
    path "initial_seq_segments.qza", emit: seqsegs
    path "versions.yml",            emit: versions

    script:
    def max_len_param = params.ess.extract_max_length ? "--p-max-length ${params.ess.extract_max_length}" : ''
    """
    qiime feature-classifier extract-reads \
        --i-sequences ${seqs} \
        --p-f-primer ${params.ess.fwd_primer} \
        --p-r-primer ${params.ess.rev_primer} \
        --p-min-length ${params.ess.extract_min_length} \
        ${max_len_param} \
        --p-n-jobs ${task.cpus} \
        --p-read-orientation 'both' \
        --o-reads initial_seq_segments.qza \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        q2-feature-classifier: \$(pip show q2-feature-classifier 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}