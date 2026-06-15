# nf-refdb-amplicon
Nextflow pipeline for generating reference databases for amplicon sequences.

:construction: *Caution, this package is still under development and has not been thoroughly tested. Workflow commands and modes of operation may change.* :construction:

## Requirements

- [Nextflow](https://www.nextflow.io/) (_>= 23.04_)
- [Cond-forge](https://conda-forge.org/) (_Miniforge/Mambaforge recommended_)

The pipeline will automatically download and create the required QIIME 2 conda environment on first run. No manual QIIME 2 installation is needed.

## How to install and run

### Install nextflow

Nextflow can be installed as standalone or via conda.

**Standalone installation (recommended)**

```bash
java -version
curl -s https://get.nextflow.io | bash
mv nextflow ~/bin/
```

**Conda installation**

```bash
conda create -n nextflow -c conda-forge -c bioconda -c defaults nextflow
conda activate nextflow
```

>[!TIP]
> For more info on nextflow please visit [Nextflow documentation](https://docs.seqera.io/nextflow/?__hstc=247481240.43f4da109a9544f90ea47ec4dba6e0f8.1767891341744.1781221442473.1781497907630.12&__hssc=247481240.1.1781497907630&__hsfp=7c1ebc5cd52a44b32f139dab9b7844fb)


### Clone the Pipeline Repo

```bash
git clone https://github.com/mikerobeson/nf-refdb-amplicon
```

> [!NOTE]
> Depending on the development cycle you may also need to clone and install the latest repo version of RESCRIPt into your QIIME 2 environment. 
> You can comment the lines under `Detected system environment` and uncomment and modify the lines under `Existing environment` within the `nextflow.config` file.*

```bash
conda activate qiime2-amplicon-2024.10
git clone https://github.com/bokulich-lab/RESCRIPt
cd RESCRIPt
pip install .
```

**Run nextflow pipeline**:
Then change to the `nf-refdb-amplicon` directory:
```
cd nf-refdb-amplicon
```

### Then sun either the SSU (16S/18S rRNA gene) or the "extract sequence segments" (ess) pipeline:

- Use `-profile local` if running locally, or `-profile cluster` if running on HPC.
- Then set either `ssu` or `ess` for `params.pipeline_type` parameter within the `nextflow.config` file prior to running one of the pipelines outlined below.


```
nextflow run main.nf -profile <profile>
```

*Note: the `ess` pipeline is currently in alpha development. You'll have to provide files using the `params.segseqs`, `params.seqs`, and `params.taxa` parameters in the config file.*



## Cite
If you make use of this pipeline please cite RESCRIPt:

- Michael S Robeson II, Devon R O'Rourke, Benjamin D Kaehler, Michal Ziemski, Matthew R Dillon, Jeffrey T Foster, Nicholas A Bokulich. (2021) RESCRIPt: Reproducible sequence taxonomy reference database management. PLoS Computational Biology 17 (11): e1009581. doi: [10.1371/journal.pcbi.1009581](http://dx.doi.org/10.1371/journal.pcbi.1009581). [GitHub](https://github.com/bokulich-lab/RESCRIPt).

Please be sure to cite the following as well:

- **If using the SILVA data** : Versions are released under different licenses. Refer to the [current SILVA release license information](https://www.arb-silva.de/silva-license-information/) for more details. [How to cite SILVA](https://www.arb-silva.de/contact/).
- **If using GTDB data** : See the [GTDB "about" page](https://gtdb.ecogenomic.org/about) for more details. [How to cite GTDB](https://gtdb.ecogenomic.org/about).
- **If using RDP data** : See the [main RDP GitHub page](https://github.com/rdpstaff) and the [RDP sourceforge page](https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/) for more details. Please cite the following RDP aritcles: [Wang *et al*. 2007](http://dx.doi.org/10.1128/AEM.00062-07) & [Wang *et al*. 2024](https://doi.org/10.1128/mra.01063-23).
- **If using NCBI Genbank data** : See the [NCBI disclaimer and copyright notice](https://www.ncbi.nlm.nih.gov/home/about/policies/) for more details. [How to cite NCBI](https://support.nlm.nih.gov/knowledgebase/article/KA-03391/en-us).

---

*Note: an older Snakemake variant of this pipeline is available [here](https://github.com/mikerobeson/snake-ref-amplicon-pipe).*