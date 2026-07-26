/*
========================================================================================
    ESS SUBWORKFLOW
========================================================================================
*/

include { ESS_GET_NCBI_DATA    } from '../../modules/ESS/ncbi_module.nf'
include { ESS_GET_UNITE_DATA   } from '../../modules/ESS/unite_module.nf'
include { ESS_GET_MIDORI2_DATA } from '../../modules/ESS/midor2_module.nf'
include { ESS_GET_PR2_DATA     } from '../../modules/ESS/pr2_module.nf'
include { ESS_SETUP            } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_ITERATE          } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_TRAIN_CLASSIFIER } from '../../modules/ESS/extract_seqsegs_modules.nf'

workflow ESS {

    main:

    // ======================================================================
    // Obtain input data based on source
    // ======================================================================

    if (params.ess.source == 'custom') {
        // User provides their own files
        if (!params.ess.seqs || !params.ess.taxa) {
            error """
                ==========================================================
                ERROR: --ess.seqs and --ess.taxa are required when
                --ess.source is 'custom'.

                Usage:
                  nextflow run main.nf --pipeline_type ess \\
                      --ess.source custom \\
                      --ess.seqs /path/to/sequences.qza \\
                      --ess.taxa /path/to/taxonomy.qza \\
                      -profile local,docker

                For help:
                  nextflow run main.nf --help ess
                ==========================================================
            """.stripIndent()
        }
        ch_ref_seqs = channel.fromPath(params.ess.seqs, checkIfExists: true)
        ch_ref_taxa = channel.fromPath(params.ess.taxa, checkIfExists: true)

    } else if (params.ess.source == 'ncbi') {
        if (!params.ess.ncbi_query) {
            error """
                ==========================================================
                ERROR: --ess.ncbi_query is required when --ess.source is 'ncbi'.

                Example:
                  nextflow run main.nf --pipeline_type ess \\
                      --ess.source ncbi \\
                      --ess.ncbi_query '"txid35493"[ORGN] AND "trnL"[Gene]' \\
                      -profile local,docker
                ==========================================================
            """.stripIndent()
        }
        ESS_GET_NCBI_DATA(params.ess.ncbi_query)
        ch_ref_seqs = ESS_GET_NCBI_DATA.out.seqs
        ch_ref_taxa = ESS_GET_NCBI_DATA.out.taxa

    } else if (params.ess.source == 'unite') {
        ESS_GET_UNITE_DATA(
            params.ess.unite_version,
            params.ess.unite_taxon_group,
            params.ess.unite_cluster_id,
            params.ess.unite_singletons
        )
        ch_ref_seqs = ESS_GET_UNITE_DATA.out.seqs
        ch_ref_taxa = ESS_GET_UNITE_DATA.out.taxa

    } else if (params.ess.source == 'midori2') {
        ESS_GET_MIDORI2_DATA(
            params.ess.midori2_target_gene,
            params.ess.midori2_version
        )
        ch_ref_seqs = ESS_GET_MIDORI2_DATA.out.seqs
        ch_ref_taxa = ESS_GET_MIDORI2_DATA.out.taxa

    } else if (params.ess.source == 'pr2') {
        ESS_GET_PR2_DATA(params.ess.pr2_version)
        ch_ref_seqs = ESS_GET_PR2_DATA.out.seqs
        ch_ref_taxa = ESS_GET_PR2_DATA.out.taxa

    } else {
        error """
            ==========================================================
            ERROR: --ess.source must be one of: custom, ncbi, unite, midori2, pr2
            Got: '${params.ess.source}'
            ==========================================================
        """.stripIndent()
    }

    // ======================================================================
    // Handle sequence segments
    // ======================================================================

    if (params.ess.seqsegs) {
        ch_seqsegs = channel.fromPath(params.ess.seqsegs, checkIfExists: true)
    } else {
        error """
            ==========================================================
            ERROR: --ess.seqsegs is required.
            Provide the path to initial segment sequences (.qza).

            Usage:
              nextflow run main.nf --pipeline_type ess \\
                  --ess.seqsegs /path/to/segments.qza \\
                  ...
            ==========================================================
        """.stripIndent()
    }

    // ======================================================================
    // Seed the ESS iteration loop
    // ======================================================================

    ESS_SETUP(ch_seqsegs, ch_ref_seqs, ch_ref_taxa)

    // ======================================================================
    // Iterative ESS loop via topic channel
    // ======================================================================

    def parser = new groovy.json.JsonSlurper()

    updates = channel.topic('ess_iteration')
    limit = updates.until { path ->
        parser.parseText(path.text).step >= (params.ess.max_iter as Integer)
    }

    ESS_ITERATE(updates, limit)

    // ======================================================================
    // Train classifier on final output (optional)
    // ======================================================================

    if (params.ess.train_classifier.toString().toBoolean()) {
        ESS_TRAIN_CLASSIFIER(
            ESS_ITERATE.out.culled_seqs.last(),
            ESS_ITERATE.out.derep_taxa.last()
        )
    }

    emit:
    culled_seqs = ESS_ITERATE.out.culled_seqs
    derep_taxa  = ESS_ITERATE.out.derep_taxa
}