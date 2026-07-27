#!/usr/bin/env nextflow

/*
========================================================================================
    nf-refdb-amplicon
========================================================================================
    Nextflow pipeline for generating reference databases for amplicon sequences.
    
    GitHub : https://github.com/mikerobeson/nf-refdb-amplicon
    Website: https://github.com/bokulich-lab/RESCRIPt
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    IMPORT SUBWORKFLOWS
========================================================================================
*/

include { SSU } from './subworkflows/SSU/ssu.nf'
include { ESS } from './subworkflows/ESS/ess.nf'

/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {

    // Pipeline information
    log.info """
    ===================================================================

    ███╗  ██╗███████╗    ██████╗ ███████╗███████╗██████╗ ██████╗ 
    ████╗ ██║██╔════╝    ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗
    ██╔██╗██║█████╗  ─── ██████╔╝█████╗  █████╗  ██║  ██║██████╔╝
    ██║╚████║██╔══╝      ██╔══██╗██╔══╝  ██╔══╝  ██║  ██║██╔══██╗
    ██║ ╚███║██║         ██║  ██║███████╗██║     ██████╔╝██████╔╝
    ╚═╝  ╚══╝╚═╝         ╚═╝  ╚═╝╚══════╝╚═╝     ╚═════╝ ╚═════╝ 
     █████╗ ███╗   ███╗██████╗ ██╗     ██╗ ██████╗  ██████╗ ███╗  ██╗
    ██╔══██╗████╗ ████║██╔══██╗██║     ██║██╔════╝ ██╔═══██╗████╗ ██║
    ███████║██╔████╔██║██████╔╝██║     ██║██║      ██║   ██║██╔██╗██║
    ██╔══██║██║╚██╔╝██║██╔═══╝ ██║     ██║██║      ██║   ██║██║╚████║
    ██║  ██║██║ ╚═╝ ██║██║     ███████╗██║╚██████╗ ╚██████╔╝██║ ╚███║
    ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚══╝

    nf-refdb-amplicon v${workflow.manifest.version}
    ===================================================================
    Pipeline type   : ${params.pipeline_type ?: 'not set'}
    Output directory: ${params.outdir}
    ===================================================================
    """.stripIndent()


    // Help messages
    if (params.help) {

                // --help ssu
        if (params.help == 'ssu') {
            log.info """
            ===================================================================
            SSU Pipeline Help (--pipeline_type ssu)
            ===================================================================

            The SSU pipeline builds reference databases for Small Subunit
            ribosomal RNA (16S/18S) from supported public repositories.

            Usage:
                nextflow run main.nf --pipeline_type ssu [options] -profile <local,docker|local,conda>

            SSU Parameters:
                --ssu_databases             Databases to build (comma-separated) [default: silva,rdp,gtdb]
                                            Available: silva, rdp, gtdb
                --build_full_classifier     Build full-length classifier [default: true]
                --build_amplicon_classifier Build amplicon classifier [default: true]

            Primer Pairs:
                --primer_pairs              List of primer pairs for amplicon region extraction [default: null]
                                            Format: [[name, forward_primer, reverse_primer], ...]

                                            Do not use 'full' as a primer pair name — it is reserved.

                                            Note: Some primer-pair combinations may not work if a
                                            primer is towards the end of the full-length SSU sequence,
                                            as the primer sequence may not be present at that location.
                                            For these cases, use the ESS pipeline instead.

                                            Available primer pairs (uncomment in conf/ssu.config):
                                              27F338R   : AGAGTTTGATYMTGGCTCAG / GCTGCCTCCCGTAGGAGT
                                              27F534R   : AGAGTTTGATYMTGGCTCAG / ATTACCGCGGCTGCTGG
                                              357wF805R : CCTACGGGNGGCWGCAG    / GACTACHVGGGTATCTAATCC
                                              357wF806R : CCTACGGGNGGCWGCAG    / GGACTACHVGGGTWTCTAAT
                                              515F806R  : GTGYCAGCMGCCGCGGTAA  / GGACTACNVGGGTWTCTAAT
                                              515F926R  : GTGYCAGCMGCCGCGGTAA  / CCGYCAATTYMTTTRAGTTT
                                              515F944R  : GTGCCAGCMGCCGCGGTAA  / GAATTAAACCACATGCTC
                                              939F1378R : GAATTGACGGGGGCCCGCACAAG / CGGTGTGTACAAGGCCCGGGAACG

            Examples:
                # Build RDP and GTDB only, no classifiers:
                nextflow run main.nf --pipeline_type ssu \\
                    --ssu_databases 'rdp,gtdb' \\
                    --build_full_classifier false \\
                    --build_amplicon_classifier false \\
                    -profile local,conda

                # Build all databases with default amplicon classifier (515F806R):
                nextflow run main.nf --pipeline_type ssu \\
                    --ssu_databases 'silva,rdp,gtdb' \\
                    -profile local,conda

                # To change primer pairs, edit conf/ssu.config directly
            ===================================================================
            """.stripIndent()
            return
        }

        // --help ess
        if (params.help == 'ess') {
            log.info """
            ===================================================================
            ESS Pipeline Help (--pipeline_type ess)
            ===================================================================

            The ESS pipeline performs iterative Evaluate, Select, Subset
            curation of reference sequences. Supports local files or
            downloading from public databases via RESCRIPt.

            Usage:
                nextflow run main.nf --pipeline_type ess [options] -profile <local,docker|local,conda>

            Data Source:
                --ess.source                Data source [default: ${params.ess.source}]
                                            Options: local, ncbi, unite, midori2, pr2

            Local Input (when --ess.source local):
                --ess.seqs                  Path to sequences (.qza) [default: ${params.ess.seqs ?: 'null (required)'}]
                --ess.taxa                  Path to taxonomy (.qza) [default: ${params.ess.taxa ?: 'null (required)'}]
                --ess.seqsegs               Path to sequence segments (.qza, optional) [default: ${params.ess.seqsegs ?: 'null'}]

            ESS Iteration Parameters:
                --ess.max_iter              Max iterations [default: ${params.ess.max_iter}]
                --ess.num_degenerates       Degenerates per iteration [default: ${params.ess.num_degenerates}]
                --ess.num_mismatch          Max primer mismatches [default: ${params.ess.num_mismatch}]
                --ess.build_classifier      Build classifier from output [default: ${params.ess.build_classifier}]

            NCBI Parameters (when --ess.source ncbi):
                --ess.ncbi_query            NCBI Entrez query string [default: ${params.ess.ncbi_query ?: 'none'}]
                --ess.ncbi_ranks            Taxonomic ranks [default: ${params.ess.ncbi_ranks}]

            UNITE Parameters (when --ess.source unite):
                --ess.unite_version         UNITE version [default: ${params.ess.unite_version}]
                --ess.unite_taxon_group     Taxon group [default: ${params.ess.unite_taxon_group}]

            MIDORI2 Parameters (when --ess.source midori2):
                --ess.midori2_version       MIDORI2 version [default: ${params.ess.midori2_version ?: 'latest'}]
                --ess.midori2_target_gene   Target gene [default: ${params.ess.midori2_target_gene}]

            PR2 Parameters (when --ess.source pr2):
                --ess.pr2_version           PR2 version [default: ${params.ess.pr2_version ?: 'latest'}]

            Examples:
                # Local files with 2 iterations:
                nextflow run main.nf --pipeline_type ess \\
                    --ess.source local \\
                    --ess.seqs sequences.qza \\
                    --ess.taxa taxonomy.qza \\
                    --ess.max_iter 2 \\
                    -profile local,docker

                # Download from NCBI (plant trnL):
                nextflow run main.nf --pipeline_type ess \\
                    --ess.source ncbi \\
                    --ess.ncbi_query '"txid33090"[Organism] AND "trnL"[Gene]' \\
                    --ess.max_iter 3 \\
                    -profile local,docker

                # Download from UNITE:
                nextflow run main.nf --pipeline_type ess \\
                    --ess.source unite \\
                    --ess.unite_taxon_group fungi \\
                    --ess.max_iter 2 \\
                    -profile local,docker
            ===================================================================
            """.stripIndent()
            return
        }

        // --help (general)
        log.info """
        ===================================================================
        nf-refdb-amplicon v${workflow.manifest.version}
        Nextflow pipeline for generating reference databases
        for amplicon sequences using RESCRIPt 🧬
        ===================================================================

        Usage:
            nextflow run main.nf --pipeline_type <ssu|ess> -profile <local,docker|local,conda|cluster,conda>

        Required:
            --pipeline_type         Pipeline to run: 'ssu' or 'ess'

        Conda (required with conda profile):
            --qiime_conda_env       Path to QIIME 2 conda environment or YAML file [default: ${params.qiime_conda_env ?: 'null'}]

        Output:
            --outdir                Output directory [default: ${params.outdir}]

        Resource limits:
            --max_memory            Max memory per process [default: ${params.max_memory}]
            --max_cpus              Max CPUs per process [default: ${params.max_cpus}]
            --max_time              Max time per process [default: ${params.max_time}]

        Profiles (combine executor + engine):
            -profile local,docker       Run locally with Docker (recommended for macOS)
            -profile local,conda        Run locally with Conda
            -profile cluster,conda      Submit to SLURM HPC with Conda

        Workflow-specific help:
            --help ssu              Show SSU pipeline parameters
            --help ess              Show ESS pipeline parameters

        Other:
            --help                  Show this help message
            -resume                 Resume previous run from cache

        Examples:
            nextflow run main.nf --pipeline_type ssu -profile local,docker
            nextflow run main.nf --pipeline_type ess -profile local,docker

        Documentation:
            https://github.com/mikerobeson/nf-refdb-amplicon
        ===================================================================
        """.stripIndent()
        return
    }

    // Validate pipeline type parameter
    if (!params.pipeline_type) {
        error '''
            ==========================================================
            ERROR: --pipeline_type is required.
            Valid options: "ssu" or "ess"
            
            Usage:
              nextflow run main.nf --pipeline_type ssu -profile local,docker
              nextflow run main.nf --pipeline_type ess -profile local,docker

            For help:
              nextflow run main.nf --help
              nextflow run main.nf --help ssu
              nextflow run main.nf --help ess
            ==========================================================
        '''.stripIndent()
    }

    // Run selected pipeline
    if (params.pipeline_type == 'ssu') {
        SSU()
    } else if (params.pipeline_type == 'ess') {
        ESS()
    } else {
        error """
            ==========================================================
            ERROR: --pipeline_type must be 'ssu' or 'ess'.
            Got: '${params.pipeline_type}'
            ==========================================================
        """.stripIndent()
    }
}

/*
========================================================================================
    THE END
========================================================================================
*/