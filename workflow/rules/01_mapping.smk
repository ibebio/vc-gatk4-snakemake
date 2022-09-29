############################################################
# 1st STEP: CREATE .BAM FILES W/O DUPLICATES
############################################################

localrules: map_all

# Trim reads (PE-only)
rule trim_reads:
    input:
        unpack(get_fastq)
    output:
        fq1=temp("results/trimmed/{sample}.R1.trimmed.fastq.gz"),
        fq2=temp("results/trimmed/{sample}.R2.trimmed.fastq.gz"),
    params:
        output_dir="results/trimmed",
        basename="{sample}"
    threads: 4
    resources:
        n=4,
        time=lambda wildcards, attempt: 2 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 6 * attempt,
    log:
        "results/logs/trim_reads/{sample}.log"
    conda:
        "../envs/trim_reads.yaml"
    shell:
        """
        trim_galore \
        --cores {threads} \
        --gzip \
        --paired \
        --output_dir {params.output_dir} \
        --basename {params.basename} \
        {input} 2> {log} ; \
        mv {params.output_dir}/{params.basename}_val_1.fq.gz {output.fq1} ; \
        mv {params.output_dir}/{params.basename}_val_2.fq.gz {output.fq2}
        """



# Align to reference
rule map_to_reference:
    input:
        fq1="results/trimmed/{sample}.R1.trimmed.fastq.gz",
        fq2="results/trimmed/{sample}.R2.trimmed.fastq.gz",
    output:
        temp("results/mapped/{sample}.sorted.bam")
    params:
        index=config["ref"]["genome"],
        platform=config["read_group"]["platform"],
        library=config["read_group"]["library"]
        # read_group: geat_read_group,
    threads: 10
    resources:
        n=10,
        time=lambda wildcards, attempt: 12 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 4 * attempt,
    log:
        "results/logs/map_to_reference/{sample}.log"
    conda:
        "../envs/global.yaml"
                        
    shell:
        "workflow/scripts/map_to_reference.sh {threads} {params.platform} {wildcards.sample} {params.index} {output} {input} {params.library} 2> {log}"

        
rule remove_duplicates:
    input:
        "results/mapped/{sample}.sorted.bam"
    output:
        bam="results/rmdup/{sample}.rmdup.bam",
        metrics="results/rmdup/{sample}/metrics.txt"
    resources:
        time=lambda wildcards, attempt: 12 * 59 * attempt,
        mem_gb_pt=lambda wildcards, attempt: 18 * attempt,
    log:
        "results/logs/remove_duplicates/{sample}.log"
    conda:
        "../envs/rmdup.yaml"
    shell:
        """
        picard MarkDuplicates \
           REMOVE_DUPLICATES=true \
           VALIDATION_STRINGENCY=LENIENT \
           INPUT={input} \
           METRICS_FILE={output.metrics} \
           OUTPUT={output.bam} \
        ; \
        samtools index \
           {output.bam} 2> {log}
        """

# Aggregate all mapped files
rule map_all:
    input:
        get_all_mapped_files
    output:
        flag=touch("results/rmdup/rmdup.done")
