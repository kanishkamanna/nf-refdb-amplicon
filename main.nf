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
//nextflow.preview.recursion=true

/*
========================================================================================
    IMPORT SUBWORKFLOWS
========================================================================================
*/

include { SSU } from './subworkflows/SSU/ssu.nf'
include { ESS } from './subworkflows/ESS/ess.nf'

// ESS subworkflow is currently under active development and not yet available.
// Uncomment the line below once the ESS pipeline is ready.

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


    // nf-refdb-amplicon help message
    if (params.help) {
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
            --qiime_conda_env           Path to QIIME 2 conda environment or YAML file [default: ${params.qiime_conda_env}]

        Output:
            --outdir                Output directory [default: ${params.outdir}]

        SSU pipeline (conf/ssu.config):
            --ssu_databases             Databases to build [default: ${params.ssu_databases}]
            --build_full_classifier     Build full-length classifier [default: ${params.build_full_classifier}]
            --build_amplicon_classifier Build amplicon classifier [default: ${params.build_amplicon_classifier}]

        Resource limits:
            --max_memory            Max memory per process [default: ${params.max_memory}]
            --max_cpus              Max CPUs per process [default: ${params.max_cpus}]
            --max_time              Max time per process [default: ${params.max_time}]

        Profiles (combine executor + engine):
            -profile local,docker       Run locally with Docker (recommended for macOS)
            -profile local,conda        Run locally with Conda
            -profile cluster,conda      Submit to SLURM HPC with Conda

        Other:
            --help                  Show this help message
            -resume                 Resume previous run from cache

        Examples:
            # Local with Docker (recommended):
            nextflow run main.nf --pipeline_type ssu --ssu_databases rdp -profile local,docker

            # Local with Conda:
            nextflow run main.nf --pipeline_type ssu --ssu_databases rdp \\
                --qiime_conda_env /path/to/env -profile local,conda

            # HPC with all databases:
            nextflow run main.nf --pipeline_type ssu --max_memory 64.GB --max_cpus 16 \\
                -profile cluster,conda

            # Multiple databases:
            nextflow run main.nf --pipeline_type ssu --ssu_databases rdp,gtdb -profile local,docker

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
              nextflow run main.nf --pipeline_type ssu -profile local
              nextflow run main.nf --pipeline_type ess -profile local
            ==========================================================
        '''.stripIndent()
    }

    // Run selected pipeline
    if (params.pipeline_type == 'ssu') {
        SSU()
    } else if (params.pipeline_type == 'ess') {
        ESS()
        //error 'ESS pipeline is under development. Not yet available.'
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