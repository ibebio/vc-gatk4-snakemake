rule call_variants:
    input:
        bam="results/rmdup/{sample}.rmdup.bam"
    output:
        gvcf=temp("results/variants/gvcf/{sample}.g.vcf.gz"),
    params:
        index=config["ref"]["genome"],
        java_options=config["variant_calling"]["java_options"],
        extra=config["variant_calling"]["extra"]
    threads: 4
    resources:
        n=4,
        time=lambda wildcards, attempt: 48 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 12 * attempt
    log:
        "results/logs/call_variants/{sample}.log"
    conda:
        "../envs/gatk4.yaml"
    shell:
        """
        gatk --java-options "{params.java_options}" HaplotypeCaller \
            {params.extra} \
            -ERC GVCF \
            -R {params.index} \
            -I {input.bam} \
            -O {output.gvcf} 2> {log}
        """



rule combine_calls:
    input:
        gvcfs=expand("results/variants/gvcf/{sample}.g.vcf.gz", sample=samples.index)
    output:
        gvcf=temp("results/variants/gvcf/all.g.vcf.gz"),
    params:
        index=config["ref"]["genome"],
        java_options=config["variant_calling"]["java_options"],
    threads: 4
    resources:
        n=4,
        time=lambda wildcards, attempt: 24 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 12 * attempt
    log:
        "results/logs/combine_calls/all.log"
    conda:
        "../envs/gatk4.yaml"
    shell:
        """
        gatk --java-options "{params.java_options}" CombineGVCFs \
            -V $(echo "{input.gvcfs}" | sed 's/ / -V /g') \
            -R {params.index} \
            -O {output.gvcf} 2> {log}
        """


rule genotype_variants:
    input:
        gvcf="results/variants/gvcf/all.g.vcf.gz",
    output:
        vcf="results/variants/raw/all.vcf.gz",
    params:
        index=config["ref"]["genome"],
        java_options=config["variant_calling"]["java_options"],
    threads: 4
    resources:
        n=4,
        time=lambda wildcards, attempt: 24 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 12 * attempt
    log:
        "results/logs/genotype_variants/all.log"
    conda:
        "../envs/gatk4.yaml"
    shell:
        """
        gatk --java-options "{params.java_options}" GenotypeGVCFs \
            -V {input.gvcf} \
            -R {params.index} \
            -O {output.vcf} 2> {log}
        """


rule filter_variants:
    input:
        vcf="results/variants/raw/all.vcf.gz",
    output:
        snps=temp("results/variants/parental/raw/all.snps.vcf"),
        indels=temp("results/variants/parental/raw/all.indels.vcf"),
        filtered_snps=temp("results/variants/filtered/all.snps.vcf"),
        filtered_indels=temp("results/variants/filtered/all.indels.vcf"),
        filtered_vcf="results/variants/filtered/all.vcf",
    params:
        index=config["ref"]["genome"],
        snp_filter=config["variant_filtering"]["snps_filter"],
        indel_filter=config["variant_filtering"]["indels_filter"],
        java_options=config["variant_calling"]["java_options"],
    resources:
        n=1,
        time=lambda wildcards, attempt: 12 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 48 * attempt
    log:
        "results/logs/filter_variants/all.log"
    conda:
        "../envs/gatk4.yaml"
    shell:
        """
        gatk --java-options "{params.java_options}" SelectVariants \
             -R {params.index} \
             -V {input.vcf} \
             --select-type-to-include SNP \
             -O {output.snps} \
        ; \
        gatk --java-options "{params.java_options}" VariantFiltration \
             -R {params.index} \
             -V {output.snps} \
             --filter-name "snps-hard-filter" \
             --filter-expression "{params.snp_filter}" \
             -O {output.filtered_snps} \
        ; \
        gatk --java-options "{params.java_options}" SelectVariants \
             -R {params.index} \
             -V {input.vcf} \
             --select-type-to-include INDEL \
             -O {output.indels} \
        ; \
        gatk --java-options "{params.java_options}" VariantFiltration \
             -R {params.index} \
             -V {output.indels} \
             --filter-name "indels-hard-filter" \
             --filter-expression "{params.indel_filter}" \
             -O {output.filtered_indels} \
        ; \
        picard MergeVcfs \
               INPUT={output.filtered_snps} \
               INPUT={output.filtered_indels} \
               OUTPUT={output.filtered_vcf} 2> {log}
        """


rule extract_strict_biallelic_snps:
    input:
        vcf="results/variants/filtered/all.vcf"
    output:
        snps=temp("results/variants/filtered/biallelic-snps.raw.vcf"),
        vcf="results/variants/filtered/biallelic-snps.vcf"
    params:
        index=config["ref"]["genome"],
        filter=config["biallelic_snps"]["filter"],
        allowed_missing_fraction=config["biallelic_snps"]["allowed_missing_fraction"],
        java_options=config["variant_calling"]["java_options"]
    resources:
        n=1,
        time=lambda wildcards, attempt: 12 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 48 * attempt
    log:
        "results/logs/extract_strict_biallelic_snps/all.log"
    conda:
        "../envs/gatk4.yaml"
    shell:
        """
        gatk SelectVariants \
             -R {params.index} \
             -V {input.vcf} \
             --exclude-filtered \
             --select-type-to-include SNP \
             --select-type-to-exclude INDEL \
             --restrict-alleles-to BIALLELIC \
             --max-nocall-fraction {params.allowed_missing_fraction} \
             -O {output.snps}  2> {log} ;\
        if [[ "{params.filter}" != "" ]] ; then \
           gatk VariantFiltration \
                -R {params.index} \
                -V {output.snps} \
                --filter-name "biallelic-snps-filter" \
                --filter-expression "{params.filter}" \
                -O {output.vcf} 2>> {log} \;
        else \
           cp {output.snps} {output.vcf} 2>> {log} ;\
        fi
        """
