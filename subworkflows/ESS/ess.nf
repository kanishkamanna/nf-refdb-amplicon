/*
========================================================================================
    ESS SUBWORKFLOW
========================================================================================
*/

include { ESS_SETUP            } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_ITERATE          } from '../../modules/ESS/extract_seqsegs_modules.nf'
include { ESS_TRAIN_CLASSIFIER } from '../../modules/ESS/extract_seqsegs_modules.nf'

workflow ESS {

    main:

    // Get input files
    ch_seqsegs = channel.fromPath(params.ess.seqsegs)
    ch_ref_seqs = channel.fromPath(params.ess.seqs)
    ch_ref_taxa = channel.fromPath(params.ess.taxa)

    // Seed the iteration loop
    ESS_SETUP(ch_seqsegs, ch_ref_seqs, ch_ref_taxa)

    // Iterative loop via topic channel
    def parser = new groovy.json.JsonSlurper()

    updates = channel.topic('ess_iteration')
    limit = updates.until { path -> parser.parseText(path.text).step >= params.ess.max_iter as Integer }

    ESS_ITERATE(updates, limit)

    // Train classifier on final output
    if (params.ess.train_classifier.toString().toBoolean()) {
         ESS_TRAIN_CLASSIFIER(
             ESS_ITERATE.out.culled_seqs.last(),
             ESS_ITERATE.out.derep_taxa.last()
         )
     }

    emit:
    culled_seqs = ESS_ITERATE.out.culled_seqs
    derep_taxa = ESS_ITERATE.out.derep_taxa
}