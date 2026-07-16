/*
========================================================================================
    ESS MODULES
========================================================================================
    Processes for the Extract Sequence Segments (ESS) pipeline.

    The ESS pipeline automates the iterative construction of amplicon
    reference databases using RESCRIPt's extract-seq-segments approach,
    without requiring PCR primer pairs for the iterative extraction step.

    Uses the run-until topic channel pattern for iteration.

    References:
        https://seqera.io/blog/running-until-iterative-loops-in-nextflow/
        https://forum.qiime2.org/t/using-rescripts-extract-seq-segments/23618
        https://github.com/bokulich-lab/RESCRIPt
----------------------------------------------------------------------------------------
*/

/*
----------------------------------------------------------------------------------------
    ESS GET NCBI DATA
----------------------------------------------------------------------------------------
    Download reference sequences and taxonomy from NCBI GenBank.
----------------------------------------------------------------------------------------
*/

process ESS_GET_NCBI_DATA {

    tag "Downloading NCBI data"
    label 'ess_download'

    output:
    tuple val(params.ess.db), val('full'), path("ref_seqs.qza"), emit: seqs
    tuple val(params.ess.db), val('full'), path("ref_tax.qza"), emit: taxa
    path "versions.yml", emit: versions

    script:
    """
    qiime rescript get-ncbi-data \
        --p-query "${params.ess.ncbi_query}" \
        --p-ranks ${params.ess.ranks} \
        --p-rank-propagation \
        --p-n-jobs ${task.cpus} \
        --o-sequences ref_seqs.qza \
        --o-taxonomy ref_tax.qza \
        --verbose

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}

/*
----------------------------------------------------------------------------------------
    ESS DEREPLICATE REFERENCE
----------------------------------------------------------------------------------------
    Dereplicate the downloaded reference sequences to reduce redundancy.
----------------------------------------------------------------------------------------
*/

process ESS_DEREP_REF {

    tag "${db} dereplicate reference"
    label 'derep'

    input:
    tuple val(db), val(amp_reg), path(seqs)
    tuple val(db_tax), val(amp_reg_tax), path(taxa)

    output:
    tuple val(db), val(amp_reg), path("${db}_ref_derep_seqs.qza"), emit: derep_seqs
    tuple val(db), val(amp_reg), path("${db}_ref_derep_taxa.qza"), emit: derep_taxa
    path "versions.yml", emit: versions

    script:
    """
    qiime rescript dereplicate \
        --i-sequences ${seqs} \
        --i-taxa ${taxa} \
        --p-mode ${params.derep.mode} \
        --p-threads ${task.cpus} \
        --o-dereplicated-sequences ${db}_ref_derep_seqs.qza \
        --o-dereplicated-taxa ${db}_ref_derep_taxa.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}

/*
----------------------------------------------------------------------------------------
    ESS EXTRACT SEEDS
----------------------------------------------------------------------------------------
    Extract initial segment sequences using PCR primer pairs.
    These serve as the initial "seeds" for the iterative extraction loop.
----------------------------------------------------------------------------------------
*/

process ESS_EXTRACT_SEEDS {

    tag "${db} extract initial seeds"
    label 'amp_reg_extract'

    input:
    tuple val(db), val(amp_reg), path(seqs)

    output:
    tuple val(db), val(params.ess.amp_seg), path("${db}_${params.ess.amp_seg}_seeds.qza"), emit: seeds
    path "versions.yml", emit: versions

    script:
    """
    qiime feature-classifier extract-reads \
        --i-sequences ${seqs} \
        --p-f-primer ${params.ess.fw_primer} \
        --p-r-primer ${params.ess.rv_primer} \
        --p-n-jobs ${task.cpus} \
        --p-read-orientation 'forward' \
        --o-reads ${db}_${params.ess.amp_seg}_seeds.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        q2-feature-classifier: \$(pip show q2-feature-classifier 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}

/*
----------------------------------------------------------------------------------------
    ESS CLEAN SEEDS
----------------------------------------------------------------------------------------
    Dereplicate and cull the initial seed sequences to remove low-quality
    sequences before entering the iterative loop.
----------------------------------------------------------------------------------------
*/

process ESS_CLEAN_SEEDS {

    tag "Clean seeds"
    label 'cull'

    input:
    path seqs
    path taxa
    path ref_seqs
    path ref_taxa

    output:
    path "state.json", topic: 'ess_iteration'
    path "versions.yml", emit: versions

    script:
    """
    qiime rescript dereplicate \
        --i-sequences ${seqs} \
        --i-taxa ${taxa} \
        --p-mode ${params.derep.mode} \
        --p-threads ${task.cpus} \
        --o-dereplicated-sequences seeds_derep.qza \
        --o-dereplicated-taxa seeds_derep_taxa.qza

    qiime rescript cull-seqs \
        --i-sequences seeds_derep.qza \
        --p-n-jobs ${task.cpus} \
        --p-num-degenerates ${params.cull.degen} \
        --p-homopolymer-length ${params.cull.hpoly} \
        --o-clean-sequences seeds_clean.qza \
        --verbose

    python3 -c "
import json, os
state = {
    'step': 0,
    'seqsegs_path': os.path.abspath('seeds_clean.qza'),
    'ref_seqs': os.path.abspath('${ref_seqs}'),
    'ref_taxa': os.path.abspath('${ref_taxa}')
}
with open('state.json', 'w') as f:
    json.dump(state, f)
"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        rescript: \$(pip show rescript 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}

/*
----------------------------------------------------------------------------------------
    ESS ITERATE
----------------------------------------------------------------------------------------
    Single iteration of the ESS loop:
        1. Extract sequence segments from reference DB using current probes
        2. Dereplicate extracted sequences
        3. Cull sequences (remove degenerates, homopolymers)
        4. Write updated state with new seqsegs path

    Output is published back to the 'ess_iteration' topic channel,
    creating the self-feeding feedback loop.
----------------------------------------------------------------------------------------
*/

process ESS_ITERATE {

    tag "ESS iteration ${task.index}"
    label 'ess_extseqsegs'

    publishDir "${params.outdir}/ess/iterations", mode: params.publish_dir_mode, saveAs: { filename -> "iter_${task.index}/${filename}" }

    input:
    path state_json
    val limiter

    output:
    path "state.json", topic: 'ess_iteration'
    path "*_culled_seqs.qza", emit: culled_seqs
    path "*_derep_taxa.qza", emit: derep_taxa
    path "versions.yml", emit: versions

    script:
    """
    #!/usr/bin/env python3
    import json
    import subprocess
    import os

    # Read current state
    with open('${state_json}') as f:
        state = json.load(f)

    step = state['step'] + 1
    seqsegs_path = state['seqsegs_path']
    db = '${params.ess.db}'
    amp_seg = '${params.ess.amp_seg}'

    print(f"=== ESS Iteration {step} ===", flush=True)
    print(f"Using seqsegs: {seqsegs_path}", flush=True)

    # Step 1: Extract sequence segments
    print("Step 1: Extracting sequence segments...", flush=True)
    subprocess.run([
        'qiime', 'rescript', 'extract-seq-segments',
        '--i-input-sequences', '${params.ess.ref_seqs}',
        '--i-reference-segment-sequences', seqsegs_path,
        '--p-perc-identity', '${params.ess.perc_identity}',
        '--p-min-seq-len', '${params.ess.min_seq_len}',
        '--p-threads', '${task.cpus}',
        '--o-extracted-sequence-segments', f'{db}_{amp_seg}_matched_seqs.qza',
        '--o-unmatched-sequences', f'{db}_{amp_seg}_unmatched_seqs.qza',
        '--verbose'
    ], check=True)

    # Step 2: Dereplicate
    print("Step 2: Dereplicating...", flush=True)
    subprocess.run([
        'qiime', 'rescript', 'dereplicate',
        '--i-sequences', f'{db}_{amp_seg}_matched_seqs.qza',
        '--i-taxa', '${params.ess.ref_taxa}',
        '--p-mode', '${params.derep.mode}',
        '--p-threads', '${task.cpus}',
        '--o-dereplicated-sequences', f'{db}_{amp_seg}_derep_seqs.qza',
        '--o-dereplicated-taxa', f'{db}_{amp_seg}_derep_taxa.qza'
    ], check=True)

    # Step 3: Cull
    print("Step 3: Culling sequences...", flush=True)
    subprocess.run([
        'qiime', 'rescript', 'cull-seqs',
        '--i-sequences', f'{db}_{amp_seg}_derep_seqs.qza',
        '--p-n-jobs', '${task.cpus}',
        '--p-num-degenerates', '${params.cull.degen}',
        '--p-homopolymer-length', '${params.cull.hpoly}',
        '--o-clean-sequences', f'{db}_{amp_seg}_culled_seqs.qza',
        '--verbose'
    ], check=True)

    # Update state - use absolute path of culled seqs for next iteration
    new_state = {
        'step': step,
        'seqsegs_path': os.path.abspath(f'{db}_{amp_seg}_culled_seqs.qza')
    }

    print(f"Iteration {step} complete.", flush=True)

    with open('state.json', 'w') as f:
        json.dump(new_state, f)
    """
}

/*
----------------------------------------------------------------------------------------
    ESS TRAIN CLASSIFIER
----------------------------------------------------------------------------------------
    Train a Naive Bayes classifier on the final iteration output.
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
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
        q2-feature-classifier: \$(pip show q2-feature-classifier 2>/dev/null | grep '^Version' | sed 's/Version: //')
    END_VERSIONS
    """
}

/*
========================================================================================
    THE END
========================================================================================
*/