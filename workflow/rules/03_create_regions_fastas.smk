rule create_sample_vcf_from_biallelic:
    input:
        vcf="results/variants/filtered/biallelic-snps.vcf"
    output:
        vcf=temp("results/variants/filtered_samples/{sample}.biallelic-snps.vcf"),
    params:
        index=config["ref"]["genome"],
	sample="{sample}",
        java_options=config["variant_calling"]["java_options"]
    resources:
        n=1,
        time=lambda wildcards, attempt: 12 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 48 * attempt
    log:
        "results/logs/create_sample_vcf_from_biallelic/{sample}.log"
    conda:
        "../envs/gatk4.yaml"
    shell:
        """
        gatk SelectVariants \
             -R {params.index} \
             -V {input.vcf} \
	     --sample-expressions {params.sample} \
	     --remove-unused-alternates \
	     --exclude-non-variants \
             -O {output.vcf}  2> {log}
        """

rule create_region_fasta:
    input:
        vcf="results/variants/filtered_samples/{sample}.biallelic-snps.vcf"
    output:
        fasta="results/region_fasta/{sample}.{region}.fasta"
    params:
        index=config["ref"]["genome"],
	interval=lambda wildcards: "{position}".format(position=[c["position"] for c in config["regions"] if c["name"] == wildcards.region][0]),
        java_options=config["variant_calling"]["java_options"]
    resources:
        n=1,
        time=lambda wildcards, attempt: 12 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 48 * attempt
    log:
        "results/logs/create_region_fasta/{sample}.{region}.log"
    conda:
        "../envs/gatk4.yaml"
    shell:
        """
        gatk FastaAlternateReferenceMaker \
             -R {params.index} \
             -V {input.vcf} \
	     -L {params.interval} \
             -O {output.fasta}  2> {log} \
        """