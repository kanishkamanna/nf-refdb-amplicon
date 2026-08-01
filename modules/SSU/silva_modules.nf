/*
----------------------------------------------------------------------------------------
    SILVA MODULES

    Download and prepare SILVA SSU rRNA gene reference database
----------------------------------------------------------------------------------------
*/

process GET_SILVA {

    tag "SILVA ${params.get_silva.version}"
    label 'get_silva'

    output:
    tuple val('silva'), val('full'), path('silva_seqs.qza'), emit: silva_seqs
    tuple val('silva'), val('full'), path('silva_taxa.qza'), emit: silva_taxa
    path "versions.yml", emit: versions

    script:
    """
    qiime rescript get-silva-data \
        --p-version ${params.get_silva.version} \
        --p-target ${params.get_silva.target} \
        --p-ranks ${params.get_silva.ranks} \
        --p-rank-propagation \
        --o-silva-sequences silva_rna_seqs.qza \
        --o-silva-taxonomy silva_taxa.qza

    qiime rescript reverse-transcribe \
        --i-rna-sequences silva_rna_seqs.qza \
        --o-dna-sequences silva_seqs.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}
