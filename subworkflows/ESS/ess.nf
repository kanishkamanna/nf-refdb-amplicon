/*
========================================================================================
    ESS SUBWORKFLOW
========================================================================================
*/

include { ESS_GET_NCBI_DATA    } from '../../modules/ESS/ncbi_module.nf'
include { ESS_GET_UNITE_DATA   } from '../../modules/ESS/unite_module.nf'
include { ESS_GET_MIDORI2_DATA } from '../../modules/ESS/midor2_module.nf'
include { ESS_EXTRACT_FROM_COLLECTION } from '../../modules/ESS/extract_collect_module.nf'
include { ESS_GET_PR2_DATA     } from '../../modules/ESS/pr2_module.nf'
include { DEREP as ESS_DEREP   } from '../../modules/SSU/base_modules.nf'
include { ESS_EXTRACT_READS    } from '../../modules/ESS/extract_seqsegs_module.nf'
include { ESS_SETUP            } from '../../modules/ESS/iterate_modules.nf'
include { ESS_ITERATE          } from '../../modules/ESS/iterate_modules.nf'
include { ESS_TRAIN_CLASSIFIER } from '../../modules/ESS/train_classifier_module.nf'

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
                      -profile local,conda
                ==========================================================
            """.stripIndent()
        }
        ESS_GET_NCBI_DATA()
        ch_ref_seqs = ESS_GET_NCBI_DATA.out.seqs
        ch_ref_taxa = ESS_GET_NCBI_DATA.out.taxa

    } else if (params.ess.source == 'unite') {
        ESS_GET_UNITE_DATA()
        ch_ref_seqs = ESS_GET_UNITE_DATA.out.seqs
        ch_ref_taxa = ESS_GET_UNITE_DATA.out.taxa

    } else if (params.ess.source == 'midori2') {
        ESS_GET_MIDORI2_DATA(params.ess.midori2_target_gene)
        
        ESS_EXTRACT_FROM_COLLECTION(
            ESS_GET_MIDORI2_DATA.out.sequences_collection,
            ESS_GET_MIDORI2_DATA.out.taxonomy_collection,
            params.ess.midori2_target_gene
        )
        
        ch_ref_seqs = ESS_EXTRACT_FROM_COLLECTION.out.sequences
        ch_ref_taxa  = ESS_EXTRACT_FROM_COLLECTION.out.taxonomy

    } else if (params.ess.source == 'pr2') {
        ESS_GET_PR2_DATA()
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
    // Dereplicate acquired reference sequences
    // ======================================================================

    // Wrap flat ESS channels into the tuple format that DEREP expects: tuple(db, amp_reg, path)
    ch_derep_seqs_in = ch_ref_seqs.map { seqs ->
        tuple(params.ess.db, 'full', seqs)
    }

    ch_derep_taxa_in = ch_ref_taxa.map { taxa ->
        tuple(params.ess.db, 'full', taxa)
    }

    ESS_DEREP(ch_derep_seqs_in, ch_derep_taxa_in)

    // Unwrap the tupled DEREP outputs back to flat paths for downstream ESS processes that expect plain path channels.
    // This adaptor will be redesigned/changed once ESS processes are updated to accept tupled channels.
    ch_derep_seqs = ESS_DEREP.out.derep_seqs.map { _db, _amp_reg, seqs -> seqs }
    ch_derep_taxa = ESS_DEREP.out.derep_taxa.map { _db, _amp_reg, taxa -> taxa }

    // ======================================================================
    // Handle sequence segments
    // ======================================================================

    if (params.ess.seqsegs) {
        // User provided pre-existing segment sequences
        ch_seqsegs = channel.fromPath(params.ess.seqsegs, checkIfExists: true)

    } else if (params.ess.fwd_primer && params.ess.rev_primer) {
        // Generate initial segments via primer extraction from downloaded data
        ESS_EXTRACT_READS(ch_ref_seqs)
        ch_seqsegs = ESS_EXTRACT_READS.out.seqsegs

    } else {
        error """
            ==========================================================
            ERROR: Either --ess.seqsegs must be provided, OR both
            --ess.fwd_primer and --ess.rev_primer must be specified
            to generate initial segments via primer extraction.

            Usage:
              # Provide pre-existing segments:
              nextflow run main.nf --pipeline_type ess \\
                  --ess.seqsegs /path/to/segments.qza ...

              # Or provide primers for automatic extraction:
              nextflow run main.nf --pipeline_type ess \\
                  --ess.fwd_primer GGGCAATCCTGAGCCAA \\
                  --ess.rev_primer CCATTGAGTCTCTGCACCTATC ...
            ==========================================================
        """.stripIndent()
    }

    // ======================================================================
    // Seed the ESS iteration loop
    // ======================================================================

    ESS_SETUP(ch_seqsegs, ch_derep_seqs, ch_derep_taxa)

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
    // Train classifier on final output
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