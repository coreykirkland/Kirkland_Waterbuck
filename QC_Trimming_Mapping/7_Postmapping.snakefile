import os
import fnmatch

samples = []
for filename in os.listdir("input"):
    if filename.endswith(".bam"):
        samples.append(filename.rsplit(".", 1)[0])


rule all:
    input:
        expand("output/{sample}.bam", sample=samples),
        expand("output/{sample}.idxstats.txt", sample=samples),
        expand("output/{sample}.stats.txt", sample=samples)


rule filter_bam:
    input:
        "input/{sample}.bam"
    output:
        bam="output/{sample}.bam",
        junk="output/{sample}.junk.bam",
        json="output/{sample}.json"
    threads: 4
    shell:
        """
        python3 ./scripts/finalize_bam.py \
            {input} \
            --threads {threads} \
            --strict-mate-alignments \
            --allow-improper-pairs \
            --min-paired-insert-size 50 \
            --max-paired-insert-size 1000 \
            --min-mapped-bases 50 \
            --min-mapped-fraction 0.5 \
            --out-passed {output.bam} \
            --out-failed {output.junk} \
            --out-json {output.json}
        """


rule samtools_stats:
    input:
        "{filename}.bam"
    output:
        "{filename}.stats.txt"
    threads: 3
    shell:
        "samtools stats --threads {threads} {input} > {output}"


rule samtools_idx:
    input:
        "{filename}.bam"
    output:
        "{filename}.bam.bai"
    threads: 3
    shell:
        "samtools index -@ {threads} {input} > {output}"


rule samtools_idxstats:
    input:
        bam="{filename}.bam",
        bai="{filename}.bam.bai"
    output:
        "{filename}.idxstats.txt"
    threads: 3
    shell:
        "samtools idxstats --threads {threads} {input.bam} > {output}"
