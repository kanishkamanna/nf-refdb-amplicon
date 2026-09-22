/*
----------------------------------------------------------------------------------------
    ESS_TRAIN_CLASSIFIER

    Trains a Naive Bayes taxonomic classifier using curated reference sequences
    and taxonomy
 ----------------------------------------------------------------------------------------
 */

process ESS_TRAIN_CLASSIFIER {

     tag "Train ESS classifier"
     label 'train_classifier'

     publishDir "${params.outdir}/ess/classifier", mode: params.publish_dir_mode

     input:
     path culled_seqs
     path derep_taxa

     output:
     path "ess_classifier.qza", emit: classifier
     path "versions.yml", emit: versions

     script:
     """
     qiime feature-classifier fit-classifier-naive-bayes \
         --i-reference-reads ${culled_seqs} \
         --i-reference-taxonomy ${derep_taxa} \
         --o-classifier ess_classifier.qza

     cat <<-END_VERSIONS > versions.yml
     "ESS_TRAIN_CLASSIFIER":
         qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
         q2-feature-classifier: \$(pip show q2-feature-classifier 2>/dev/null | grep '^Version' | sed 's/Version: //')
     END_VERSIONS
     """
}