/*
========================================================================================
    ESS SUBWORKFLOW
========================================================================================
    Build classifiers using RESCRIPt's iterative extract-seq-segments approach.

    Uses the run-until topic channel pattern for iteration:
        1. Download reference data from NCBI
        2. Dereplicate reference sequences
        3. Extract initial segments using primer pairs (seeds)
        4. Clean seeds (derep + cull)
        5. Iterate: extract-seq-segments → derep → cull (feedback loop)
        6. Train classifier on final refined sequences

    The iteration loop uses a topic channel for feedback — no
    nextflow.preview.recursion flag needed. Works with Nextflow >= 24.04.

    References:
        https://seqera.io/blog/running-until-iterative-loops-in-nextflow/
        https://forum.qiime2.org/t/using-rescripts-extract-seq-segments/23618

    Configuration: conf/ess.config
----------------------------------------------------------------------------------------
*/

include { ESS_GET_NCBI_DATA    } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_DEREP_REF        } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_EXTRACT_SEEDS    } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_CLEAN_SEEDS      } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_ITERATE          } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_TRAIN_CLASSIFIER } from '../../modules/ESS/extract_seqsegs_modules.nf'

/*
----------------------------------------------------------------------------------------
    WORKFLOW
----------------------------------------------------------------------------------------
*/

workflow ESS {

    main:

    // ==========================================================
    // Step 1: Download reference data
    // ==========================================================

    ESS_GET_NCBI_DATA()

    // ==========================================================
    // Step 2: Dereplicate reference sequences
    // ==========================================================

    ESS_DEREP_REF(
        ESS_GET_NCBI_DATA.out.seqs,
        ESS_GET_NCBI_DATA.out.taxa
    )

    // ==========================================================
    // Step 3: Extract initial seeds using primers
    // ==========================================================

    ESS_EXTRACT_SEEDS(ESS_DEREP_REF.out.derep_seqs)

    // ==========================================================
    // Step 4: Clean seeds (derep + cull) and seed the loop
    // ==========================================================

    ESS_CLEAN_SEEDS(
        ESS_EXTRACT_SEEDS.out.seeds,
        ESS_DEREP_REF.out.derep_taxa,
        ESS_DEREP_REF.out.derep_seqs,
        ESS_DEREP_REF.out.derep_taxa
    )

    // ==========================================================
    // Step 5: Iterative loop via topic channel
    //
    // ESS_CLEAN_SEEDS publishes state.json to 'ess_iteration' topic.
    // ESS_ITERATE reads from the topic, does extract→derep→cull,
    // and publishes updated state.json back to the same topic.
    // .until() closes the loop when max iterations are reached.
    // ==========================================================

    def parser = new groovy.json.JsonSlurper()
    updates = channel.topic('ess_iteration')
    limit = updates.until { path ->
        parser.parseText(path.text).step >= params.ess.max_iter
    }

    ESS_ITERATE(updates, limit)

    // ==========================================================
    // Step 6: Train classifier on final output
    // ==========================================================

    if (params.ess.train_classifier.toString().toBoolean()) {
        ESS_TRAIN_CLASSIFIER(
            ESS_ITERATE.out.culled_seqs.last(),
            ESS_ITERATE.out.derep_taxa.last()
        )
    }
}

/*
========================================================================================
    THE END
========================================================================================
*/