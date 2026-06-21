/*
========================================================================================
    GTDB MODULES
========================================================================================
    Download and prepare GTDB SSU rRNA gene reference database.

    GTDB (Genome Taxonomy Database) provides a standardised taxonomy
    based on genome phylogeny. This module downloads SSU rRNA gene
    sequences and taxonomy from the specified GTDB release.

    Citation: https://gtdb.ecogenomic.org/about
----------------------------------------------------------------------------------------
*/

process GET_GTDB {

    tag "GTDB ${params.get_gtdb.version}"
    label 'get_gtdb'

    output:
    tuple val('gtdb'), val('full'), path('gtdb_seqs.qza'), emit: gtdb_seqs
    tuple val('gtdb'), val('full'), path('gtdb_taxa.qza'), emit: gtdb_taxa
    path "versions.yml", emit: versions

    script:
    """
    qiime rescript get-gtdb-data \
        --p-version ${params.get_gtdb.version} \
        --p-domain ${params.get_gtdb.domain} \
        --p-db-type ${params.get_gtdb.dbtype} \
        --o-gtdb-sequences gtdb_seqs.qza \
        --o-gtdb-taxonomy gtdb_taxa.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show q2-rescript 2>/dev/null | grep -i version | sed 's/Version: //')
    END_VERSIONS
    """
}

/*
========================================================================================
    THE END
========================================================================================
*/