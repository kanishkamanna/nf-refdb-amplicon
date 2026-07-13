/*
========================================================================================
    RDP MODULES
========================================================================================
    Download and prepare RDP (Ribosomal Database Project) reference database.

    RDP provides ribosomal RNA gene sequence data and analysis tools.
    Unlike SILVA and GTDB, RDP data is downloaded as flat files and
    imported into QIIME 2 artifact format.

    Citation: Wang et al. 2007 (doi:10.1128/AEM.00062-07)
              Wang et al. 2024 (doi:10.1128/mra.01063-23)
    Source:   https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/
----------------------------------------------------------------------------------------
*/

process GET_RDP {

    tag 'RDP trainset 19'
    label 'get_rdp'

    output:
    path('RDPClassifier_16S_trainsetNo19_QiimeFormat/RefOTUs.fa'), emit: rdp_fasta
    path('RDPClassifier_16S_trainsetNo19_QiimeFormat/Ref_taxonomy.txt'), emit: rdp_tax_tsv
    path "versions.yml", emit: versions

    script:
    """
    wget https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/RDPClassifier_16S_trainsetNo19_QiimeFormat.zip

    python -c "
import zipfile
import os

with zipfile.ZipFile('RDPClassifier_16S_trainsetNo19_QiimeFormat.zip', 'r') as zf:
    for member in zf.infolist():
        # Fix Windows backslash paths
        member.filename = member.filename.replace('\\\\\\\\', '/')
        zf.extract(member, '.')
"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(wget --version 2>&1 | head -1 | sed 's/GNU Wget //' | sed 's/ .*//')
        python: \$(python --version | sed 's/Python //')
    END_VERSIONS
    """
}

process IMPORT_RDP {

    tag 'Importing RDP data'
    label 'get_rdp'

    input:
    path(rdp_fasta)
    path(rdp_tax_tsv)

    output:
    tuple val('rdp'), val('full'), path('rdp_seqs.qza'), emit: rdp_seqs
    tuple val('rdp'), val('full'), path('rdp_taxa.qza'), emit: rdp_taxa
    path "versions.yml", emit: versions

    script:
    """
    qiime tools import \
        --input-path '${rdp_fasta}' \
        --type 'FeatureData[Sequence]' \
        --input-format 'MixedCaseDNAFASTAFormat' \
        --output-path rdp_seqs.qza

    qiime tools import \
        --input-path '${rdp_tax_tsv}' \
        --type 'FeatureData[Taxonomy]' \
        --input-format 'HeaderlessTSVTaxonomyFormat' \
        --output-path rdp_taxa.qza

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$(qiime --version | head -1 | sed 's/q2cli version //')
    END_VERSIONS
    """
}

/*
========================================================================================
    THE END
========================================================================================
*/