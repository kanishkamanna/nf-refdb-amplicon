/*
========================================================================================
    CURATE AND TRAIN SUBWORKFLOW
========================================================================================
    Common curation and classifier training logic shared across all 
    SSU reference databases (SILVA, GTDB, RDP).

    This subworkflow performs:
        1. Full-length processing:
           Dereplicate → Cull → Train classifier (optional)

        2. Amplicon-specific processing (optional):
           Extract amplicon region → Dereplicate → Cull → Train classifier

    The same subworkflow is aliased per database in ssu.nf to avoid 
    code duplication.
----------------------------------------------------------------------------------------
*/

include {
    DEREP as FULL_DEREP;
    CULL as FULL_CULL;
    TRAIN_CLASSIFIER as FULL_TRAIN;
    AMP_REG_EXTRACT;
    DEREP as AMP_DEREP;
    CULL as AMP_CULL;
    TRAIN_CLASSIFIER as AMP_TRAIN;
} from '../../modules/SSU/base_modules.nf'

/*
----------------------------------------------------------------------------------------
    WORKFLOW
----------------------------------------------------------------------------------------
*/

workflow CURATE_AND_TRAIN {

    take:
    ch_seqs      // tuple(db, 'full', seqs.qza)
    ch_taxa      // tuple(db, 'full', taxa.qza)
    ch_primers   // channel of tuple(amp_reg, fw_primer, rev_primer)

    main:

    // ==========================================================
    // Full-length: Dereplicate → Cull → Train
    // ==========================================================

    FULL_DEREP(ch_seqs, ch_taxa)
    FULL_CULL(FULL_DEREP.out.derep_seqs)

    if (params.build_full_classifier.toString().toBoolean()) {
        FULL_TRAIN(FULL_CULL.out.culled_seqs, FULL_DEREP.out.derep_taxa)
    }

    // ==========================================================
    // Amplicon: Extract → Dereplicate → Cull → Train
    // ==========================================================

    if (params.build_amplicon_classifier.toString().toBoolean()) {
        AMP_REG_EXTRACT(FULL_DEREP.out.derep_seqs, ch_primers)
        AMP_DEREP(AMP_REG_EXTRACT.out.extract_amp, FULL_DEREP.out.derep_taxa)
        AMP_CULL(AMP_DEREP.out.derep_seqs)
        AMP_TRAIN(AMP_CULL.out.culled_seqs, AMP_DEREP.out.derep_taxa)
    }

    emit:
    full_classifier = params.build_full_classifier.toString().toBoolean() ? FULL_TRAIN.out.classifier : channel.empty()
    amp_classifier  = params.build_amplicon_classifier.toString().toBoolean() ? AMP_TRAIN.out.classifier : channel.empty()
}

/*
========================================================================================
    THE END
========================================================================================
*/