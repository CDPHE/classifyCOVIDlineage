version 1.0

workflow classifyCOVIDlineage {

    input {
        Array[File] assembly_fastas
        Array[File] cov_out_txt
        Array[File] percent_cvg_csv
        File nextclade_json_parser_script
        File concat_results_script
        String seq_run
        String out_dir
    }

    call concatenate {
        input:
            assembly_fastas = assembly_fastas
    }

    call pangolin {
        input:
            cat_fastas = concatenate.cat_fastas
    }

    call nextclade {
        input:
            multifasta = concatenate.cat_fastas
    }

    call parse_nextclade {
      input:
        seq_run = seq_run,
        nextclade_json_parser_script = nextclade_json_parser_script,
        nextclade_json = nextclade.nextclade_json
    }

    call results_table {
      input:
        concat_results_script = concat_results_script,
        cov_out_txt = cov_out_txt,
        percent_cvg_csv = percent_cvg_csv,
        pangolin_lineage_csv = pangolin.lineage,
        pangolin_version = pangolin.pangolin_version,
        nextclade_clades_csv = parse_nextclade.nextclade_clades_csv,
        nextclade_variants_csv = parse_nextclade.nextclade_variants_csv,
        nextclade_version = nextclade.nextclade_version,
        seq_run = seq_run

    }

    call transfer {
      input:
          out_dir = out_dir,
          cat_fastas = concatenate.cat_fastas,
          pangolin_lineage = pangolin.lineage,
          nextclade_json = nextclade.nextclade_json,
          auspice_json = nextclade.auspice_json,
          nextclade_csv = nextclade.nextclade_csv,
          nextclade_clades_csv = parse_nextclade.nextclade_clades_csv,
          nextclade_variants_csv = parse_nextclade.nextclade_variants_csv,
          sequencing_results_csv = results_table.sequencing_results_csv,
          sequence_assembly_metrics_csv = results_table.sequence_assembly_metrics_csv,
          wgs_horizon_report_csv = results_table.wgs_horizon_report_csv
    }

    output {
        File cat_fastas = concatenate.cat_fastas
        String pangolin_version = pangolin.pangolin_version
        File pangolin_lineage = pangolin.lineage
        String nextclade_version = nextclade.nextclade_version
        File nextclade_json = nextclade.nextclade_json
        File auspice_json = nextclade.auspice_json
        File nextclade_csv = nextclade.nextclade_csv
        File nextclade_clades_csv = parse_nextclade.nextclade_clades_csv
        File nextclade_variants_csv = parse_nextclade.nextclade_variants_csv
        File sequencing_results_csv = results_table.sequencing_results_csv
        File sequence_assembly_metrics_csv = results_table.sequence_assembly_metrics_csv
        File wgs_horizon_report_csv = results_table.wgs_horizon_report_csv
    }
}

task concatenate {

    input {
        Array[File] assembly_fastas
    }

    command <<<

        cat ~{sep=" " assembly_fastas} > concatenate_assemblies.fasta

    >>>

    output {

        File cat_fastas = "concatenate_assemblies.fasta"

    }

    runtime {
        docker: "ubuntu"
        memory: "1 GB"
        cpu:    1
        disks: "local-disk 375 LOCAL"
        dx_instance_type: "mem1_ssd1_v2_x2"
    }
}

task pangolin {

    input {

        File cat_fastas
    }

    command {

        pangolin --version > VERSION
        pangolin --outfile pangolin_lineage_report.csv ${cat_fastas}

    }

    output {

        String pangolin_version = read_string("VERSION")
        File lineage = "pangolin_lineage_report.csv"

    }

    runtime {
        cpu:    4
        memory:    "16 GiB"
        disks:    "local-disk 1 HDD"
        bootDiskSizeGb:    10
        preemptible:    0
        maxRetries:    0
        docker:    "staphb/pangolin"
    }
}

task nextclade {

    input {
        File multifasta
    }

    command {
        nextclade --version > VERSION
        nextclade --input-fasta "${multifasta}" --output-json nextclade.json --output-csv nextclade.csv --output-tree nextclade.auspice.json
    }

    output {
        String nextclade_version = read_string("VERSION")
        File nextclade_json = "nextclade.json"
        File auspice_json = "nextclade.auspice.json"
        File nextclade_csv = "nextclade.csv"
    }

    runtime {
        docker: "nextstrain/nextclade:0.13.0"
        memory: "16 GB"
        cpu: 4
        disks: "local-disk 50 HDD"
        dx_instance_type: "mem1_ssd1_v2_x2"
    }
}

task parse_nextclade {

    input {
      File nextclade_json_parser_script
      File nextclade_json
      String seq_run
    }

    command {
      python ~{nextclade_json_parser_script} \
          --nextclade_json ~{nextclade_json} \
          --seq_run ~{seq_run}

    }

    output {
      File nextclade_clades_csv = '${seq_run}_nextclade_results.csv'
      File nextclade_variants_csv = '${seq_run}_nextclade_variant_summary.csv'
    }

    runtime {
        docker: "mchether/py3-bio:v2"
        memory: "16 GB"
        cpu:    4
        disks: "local-disk 375 LOCAL"
        dx_instance_type: "mem1_ssd1_v2_x2"
    }
}

task results_table {

    input {
      File concat_results_script
      Array[File] cov_out_txt
      Array[File] percent_cvg_csv
      File pangolin_lineage_csv
      String pangolin_version
      File nextclade_clades_csv
      File nextclade_variants_csv
      String nextclade_version
      String seq_run
    }

    command {
      python ~{concat_results_script} \
          --bam_file_list ${write_lines(cov_out_txt)} \
          --percent_cvg_file_list ${write_lines(percent_cvg_csv)} \
          --pangolin_lineage_csv ~{pangolin_lineage_csv} \
          --pangolin_version "~{pangolin_version}" \
          --nextclade_clades_csv ~{nextclade_clades_csv} \
          --nextclade_variants_csv ~{nextclade_variants_csv} \
          --nextclade_version "~{nextclade_version}" \
          --seq_run ~{seq_run}
    }

    output {
        File sequencing_results_csv = "${seq_run}_sequencing_results.csv"
        File sequence_assembly_metrics_csv = "${seq_run}_sequence_assembly_metrics.csv"
        File wgs_horizon_report_csv = "${seq_run}_wgs_horizon_report.csv"
    }

    runtime {
        docker: "mchether/py3-bio:v2"
        memory: "16 GB"
        cpu:    4
        disks: "local-disk 375 LOCAL"
        dx_instance_type: "mem1_ssd1_v2_x2"
    }
}

task transfer {
    input {
        String out_dir
        File cat_fastas
        File pangolin_lineage
        File nextclade_json
        File auspice_json
        File nextclade_csv
        File nextclade_clades_csv
        File nextclade_variants_csv
        File sequencing_results_csv
        File sequence_assembly_metrics_csv
        File wgs_horizon_report_csv
    }

    String outdir = sub(out_dir, "/$", "")

    command <<<

        gsutil -m cp ~{cat_fastas} ~{outdir}/multifasta/
        gsutil -m cp ~{pangolin_lineage} ~{outdir}/pangolin_out/
        gsutil -m cp ~{nextclade_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{auspice_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{nextclade_csv} ~{outdir}/nextclade_out/
        gsutil -m cp ~{nextclade_clades_csv} ~{outdir}/nextclade_out/
        gsutil -m cp ~{nextclade_variants_csv} ~{outdir}/summary_results/
        gsutil -m cp ~{sequencing_results_csv} ~{outdir}/summary_results/
        gsutil -m cp ~{sequence_assembly_metrics_csv} ~{outdir}/
        gsutil -m cp ~{wgs_horizon_report_csv} ~{outdir}/summary_results/
    >>>

    runtime {
        docker: "theiagen/utility:1.0"
        memory: "16 GB"
        cpu: 4
        disks: "local-disk 10 SSD"
    }
}
