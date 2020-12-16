# Snakemake workflow: GATK variant calling using gVCFs and hard filtering



[![Snakemake](https://img.shields.io/badge/snakemake-≥5.28.0-brightgreen.svg)](https://snakemake.bitbucket.io)
[![Build Status](https://travis-ci.org/snakemake-workflows/tiger_analysis_pipeline.svg?branch=master)](https://travis-ci.org/snakemake-workflows/tiger_analysis_pipeline)

<!-- This is the template for a new Snakemake workflow. Replace this text with a comprehensive description covering the purpose and domain.
Insert your code into the respective folders, i.e. `scripts`, `rules`, and `envs`. Define the entry point of the workflow in the `Snakefile` and the main configuration in the `config.yaml` file. -->

## Authors
* Snakemake workflow: Ilja Bezrukov

## Usage
### Step 1: Obtain a copy of this workflow
<!--
1. Create a new github repository using this workflow [as a template](https://help.github.com/en/articles/creating-a-repository-from-a-template).
2. [Clone](https://help.github.com/en/articles/cloning-a-repository) the newly created repository to your local system, into the place where you want to perform the data analysis.

-->
Clone the repository into the place where you want to perform the data analysis.
```
git clone https://github.com/ibebio/vc-gatk4-snakemake.git
```

### Step 2: Configure workflow

Configure the workflow according to your needs via editing the files in the `config/` folder. Adjust `config.yaml` to configure the workflow execution, and `samples.csv` to specify your sample setup.

Run the following command  to make the required scripts executable:
```
$ chmod u+x workflow/scripts/*.*
```

### Step 3: Install Snakemake

Install Snakemake using [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html):

	conda create -c bioconda -c conda-forge -n snakemake snakemake">="5.28.0 python">="3.7
	
For installation details, see the [instructions in the Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).


### Step 4: Execute workflow

For the Weigel lab, set up your SGE cluster profile as follows:

```
git clone https://github.com/ibebio/snakemake_profiles.git
cd snakemake_profiles
mkdir -p ~/.config/snakemake/
chmod u+x sge/*.py
cp -r sge ~/.config/snakemake/
```

Activate the conda environment:

    conda activate snakemake

Test your configuration by performing a dry-run via

    snakemake -n


A helper script `run-workflow.sh`, is included to conveniently run the
workflow, either locally or on the cluster:

	./run-workflow.sh sge

would run the pipeline on the SGE cluster, as set up previously.

	./run-workflow.sh local

would run it on the local maschine.

To customize how many cores and jobs are used, you can either modify
the `run-workflow.sh` script or run the commands required to run the
workflow by hand, as described below.

To clean up all output files and conda environments to rerun the workflow from
scratch, the helper script `clean-all.sh` is included.




##### Run the workflow with custom settings
Execute the workflow locally via

    snakemake --use-conda --cores $N --scheduler greedy

using `$N` cores. 

To run it in a cluster environment, first create all required conda
environments via

    snakemake --use-conda --conda-create-envs-only --cores 4

Then, run the workflow via

    snakemake --use-conda --profile sge --jobs 100 --scheduler greedy

The number of jobs can be adjusted as required. Additional arguments
for Snakemake can also be supplied.


<!-- If you not only want to fix the software stack but also the underlying OS, use

    snakemake --use-conda --use-singularity

in combination with any of the modes above.
-->

### Step 5: Investigate results

All output is stored in the `results/` subfolder.
Logs for each step are stored in `logs/`.

The pipeline produces the following outputs:
#### Filtered variants
`results/variants/filtered/all.vcf` contains SNPs and INDELs for all samples filtered
according to the `variant_filtering` section in the config file.
#### Biallelic SNPs
`results/variants/filtered/biallelic-snps.vcf` contains only biallelic
SNPs. Non-PASS variants are removed, and the requirement of a minimal
missing fraction (default 0.1) is added. This variants are the basis
for further analysis.
#### FASTA files for specific regions for each sample
The directory `results/region_fasta/` contains fasta nucleotid
sequence files for specific regions, e.g. effectors. The files are
generated for each sample separately, and contain the variants from
the previous step (Biallelic SNPs) which are present in this
samples. They are named `{sample}.{region}.fasta`. The regions are
defined in the config file in the section `regions`.


<!--
### Step 5: Investigate results

After successful execution, you can create a self-contained interactive HTML report with all results via:

    snakemake --report report.html

This report can, e.g., be forwarded to your collaborators.
An example (using some trivial test data) can be seen [here](https://cdn.rawgit.com/snakemake-workflows/rna-seq-kallisto-sleuth/master/.test/report.html).

### Step 6: Commit changes

Whenever you change something, don't forget to commit the changes back to your github copy of the repository:

    git commit -a
    git push

-->

### Step 6: Obtain updates from upstream

Whenever you want to synchronize your workflow copy with bugfixes or new developments from the upstream repository, do the following:

1. At the very least, your config files will be different, compared to the example ones from upstream. Therefore, they need to be secured before obtaining the upstream copy: `git stash`
2. Obtain the updates from the Github repository: `git pull`
3. Restore your modifications to the config files: `gut stash pop`

The above steps assume that you did not modify any parts of the
workflow, except the config files. If the config format has changed,
you might need to update them.

The `workflow/` folder contains the Snakemake files and scripts that are needed to run the workflow.
It does not need to be changed unless the workflow has to be modifed.

See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further details.


<!--
1. Once, register the upstream repository in your local copy: `git remote add -f upstream git@github.com:snakemake-workflows/capture_mapping_pipeline.git` or `git remote add -f upstream https://github.com/snakemake-workflows/capture_mapping_pipeline.git` if you do not have setup ssh keys.
2. Update the upstream version: `git fetch upstream`.
3. Create a diff with the current version: `git diff HEAD upstream/master workflow > upstream-changes.diff`.
4. Investigate the changes: `vim upstream-changes.diff`.
5. Apply the modified diff via: `git apply upstream-changes.diff`.
6. Carefully check whether you need to update the config files: `git diff HEAD upstream/master config`. If so, do it manually, and only where necessary, since you would otherwise likely overwrite your settings and samples.
-->
<!--
### Step 8: Contribute back

In case you have also changed or added steps, please consider contributing them back to the original repository:

1. [Fork](https://help.github.com/en/articles/fork-a-repo) the original repo to a personal or lab account.
2. [Clone](https://help.github.com/en/articles/cloning-a-repository) the fork to your local system, to a different place than where you ran your analysis.
3. Copy the modified files from your analysis to the clone of your fork, e.g., `cp -r workflow path/to/fork`. Make sure to **not** accidentally copy config file contents or sample sheets. Instead, manually update the example config files if necessary.
4. Commit and push your changes to your fork.
5. Create a [pull request](https://help.github.com/en/articles/creating-a-pull-request) against the original repository.

## Testing

Test cases are in the subfolder `.test`. They are automatically executed via continuous integration with [Github Actions](https://github.com/features/actions).

-->
