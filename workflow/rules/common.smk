from snakemake.utils import validate
import pandas as pd
import itertools

# this container defines the underlying OS for each job when using the workflow
# with --use-conda --use-singularity
singularity: "docker://continuumio/miniconda3"

##### load config and sample sheets #####

configfile: "config/config.yaml"
# validate(config, schema="../schemas/config.schema.yaml")

samples = pd.read_csv(config["samples"], sep="\t|;|,").set_index("sample", drop=False)
samples.index.names = ["sample_id"]
# validate(samples, schema="../schemas/samples.schema.yaml")


##### Wildcard constraints #####
wildcard_constraints:
    sample="|".join(samples.index),

##### Helper functions #####
def get_fastq(wildcards):
    """Get fastq files of given sample."""
    fastqs = samples.loc[(wildcards.sample), ["fq1", "fq2"]].dropna()
    if len(fastqs) == 2:
        return {"r1": fastqs.fq1, "r2": fastqs.fq2}
    return {"r1": fastqs.fq1}


def get_all_mapped_files(wildcards):
    """ return the names of all rmdup files (output of 01_mapping.smk) """
    mapped_files = ['results/rmdup/{}.rmdup.bam'.format(s) for s in samples.index]
    return mapped_files
