# nf-refdb-amplicon
Nextflow pipeline for generating reference databases for amplicon sequences.

:construction: *Caution, this package is still under development and has not been thoroughly tested. Workflow commands and modes of operation may change.* :construction:

---

## Requirements

- [Nextflow](https://www.nextflow.io/) (_>= 23.04_)
- [Conda](https://conda-forge.org/) (_Miniforge/Mambaforge recommended_)
- [Docker](https://www.docker.com/)

---

## Installation

### 1. Install nextflow

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


### 2. Clone the Pipeline

```bash
git clone https://github.com/mikerobeson/nf-refdb-amplicon
cd nf-refdb-amplicon
```


### 3. Set Up QIIME 2 Environment

> [!IMPORTANT]
> Choose the setup method based on your operating system and execution profile.

#### 🍎 macOS — Docker (recommended)

Make sure [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed and **running**. The pipeline will **automatically** pull the correct QIIME 2 Docker image — no manual setup required.

```bash
nextflow run main.nf \
    --pipeline_type ssu \
    -profile local,docker
```


#### 🍎 macOS — Conda

> [!NOTE]
> Nextflow **cannot** automatically set `CONDA_SUBDIR=osx-64` when creating environments. You must **manually** create the QIIME 2 environment first, then point to it using `--qiime_conda_env`.

**Step 1:** Create the QIIME 2 environment manually:

```bash
# Required for Apple Silicon (M1/M2/M3) Macs
CONDA_SUBDIR=osx-64 conda env create \
    --name rachis-qiime2-2026.4 \
    --file https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2026.4/qiime2/released/rachis-qiime2-osx-64-conda.yml
```

**Step 2:** Get the path to your environment:

```bash
conda env list | grep rachis-qiime2-2026.4
```

**Step 3:** Run the pipeline pointing to the existing environment:

```bash
nextflow run main.nf \
    --pipeline_type ssu \
    --qiime_conda_env /path/to/conda/envs/rachis-qiime2-2026.4 \
    -profile local,conda
```


#### 🐧 Linux — Conda (auto-install)

On Linux, the pipeline will **automatically** create the QIIME 2 environment from the YAML files provided in the `assets/` folder. Simply point `--qiime_conda_env` to the YAML file:

```bash
nextflow run main.nf \
    --pipeline_type ssu \
    --qiime_conda_env assets/rachis-qiime2-linux-64-conda.yml \
    -profile local,conda
```

> [!NOTE]
> Depending on the development cycle you may also need to install the latest version of RESCRIPt manually into your QIIME 2 environment:

```bash
conda activate qiime2-amplicon-2024.10
git clone https://github.com/bokulich-lab/RESCRIPt
cd RESCRIPt
pip install .
```

---

## Quick start

**All databases:**
```bash
nextflow run main.nf --pipeline_type ssu -profile local,docker
```

**Multiple databases:**
```bash
nextflow run main.nf --pipeline_type ssu --ssu_databases silva,rdp -profile local,docker
```

**Single database:**
```bash
nextflow run main.nf --pipeline_type ssu --ssu_databases rdp -profile local,docker
```

**Skip classifiers:**
```bash
nextflow run main.nf --pipeline_type ssu \
    --build_full_classifier false \
    --build_amplicon_classifier false \
    -profile local,docker
```

**Resume a previous run:**
```bash
nextflow run main.nf --pipeline_type ssu -profile local,docker -resume
```

**Show help:**
```bash
nextflow run main.nf --help
```

---

## Usage

### Pipeline Types

| Type | Description |
|------|-------------|
| `ssu` | Build Naive Bayes classifiers from SSU rRNA gene reference databases (SILVA, GTDB, RDP) |
| `ess` | Build classifiers using iterative `extract-seq-segments` approach (under development) |

### Profiles

Combine an executor profile with an engine profile:

| Executor | Engine | Usage | Description |
|----------|--------|-------|-------------|
| `local` | `docker` | `-profile local,docker` | Run locally with Docker (recommended for macOS/Linux desktops) |
| `local` | `conda` | `-profile local,conda` | Run locally with Conda |
| `cluster` | `conda` | `-profile cluster,conda` | Submit to SLURM HPC with Conda |

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--pipeline_type` | — | Required. `ssu` or `ess` |
| `--ssu_databases` | `silva,gtdb,rdp` | Databases to build classifiers from |
| `--build_full_classifier` | `true` | Build full-length reference classifier |
| `--build_amplicon_classifier` | `true` | Build amplicon-specific classifier |
| `--qiime_conda_env` | YAML in assets/ | Path to existing QIIME 2 conda environment (for conda profile) |
| `--outdir` | `results` | Output directory |
| `--max_memory` | `16.GB` | Max memory per process |
| `--max_cpus` | `4` | Max CPUs per process |
| `--max_time` | `48.h` | Max time per process |
| `--help` | `false` | Show help message |


> [!WARNING]
> The `ess` pipeline is currently **under active development** and is not yet available.
> The relevant code has been commented out in `main.nf`:
> ```nextflow
> // include { ESS } from './subworkflows/ESS/ess.nf'
> ```
> Only `--pipeline_type ssu` is supported at this time.

*Note: the `ess` pipeline is currently in alpha development. You'll have to provide files using the `params.segseqs`, `params.seqs`, and `params.taxa` parameters in the config file.*

---

## Cite
If you make use of this pipeline please cite RESCRIPt:

- Michael S Robeson II, Devon R O'Rourke, Benjamin D Kaehler, Michal Ziemski, Matthew R Dillon, Jeffrey T Foster, Nicholas A Bokulich. (2021) RESCRIPt: Reproducible sequence taxonomy reference database management. PLoS Computational Biology 17 (11): e1009581. doi: [10.1371/journal.pcbi.1009581](http://dx.doi.org/10.1371/journal.pcbi.1009581). [GitHub](https://github.com/bokulich-lab/RESCRIPt).

Please be sure to cite the following as well:

- **If using the SILVA data** : Versions are released under different licenses. Refer to the [current SILVA release license information](https://www.arb-silva.de/silva-license-information/) for more details. [How to cite SILVA](https://www.arb-silva.de/contact/).
- **If using GTDB data** : See the [GTDB "about" page](https://gtdb.ecogenomic.org/about) for more details. [How to cite GTDB](https://gtdb.ecogenomic.org/about).
- **If using RDP data** : See the [main RDP GitHub page](https://github.com/rdpstaff) and the [RDP sourceforge page](https://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/) for more details. Please cite the following RDP aritcles: [Wang *et al*. 2007](http://dx.doi.org/10.1128/AEM.00062-07) & [Wang *et al*. 2024](https://doi.org/10.1128/mra.01063-23).
- **If using NCBI Genbank data** : See the [NCBI disclaimer and copyright notice](https://www.ncbi.nlm.nih.gov/home/about/policies/) for more details. [How to cite NCBI](https://support.nlm.nih.gov/knowledgebase/article/KA-03391/en-us).

---

> [!NOTE] 
> An older Snakemake variant of this pipeline is available [here](https://github.com/mikerobeson/snake-ref-amplicon-pipe).