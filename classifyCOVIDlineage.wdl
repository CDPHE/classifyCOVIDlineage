version 1.0

workflow classifyCOVIDlineage {

    input {
        Array[File] assembly_fastas
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

    call transfer_outputs {
        input:
            out_dir = out_dir,
            cat_fastas = concatenate.cat_fastas,
            pangolin_lineage = pangolin.lineage,
            nextclade_json = nextclade.nextclade_json,
            auspice_json = nextclade.auspice_json,
            nextclade_csv = nextclade.nextclade_csv,
    }

    output {
        File cat_fastas = concatenate.cat_fastas
        String pangolin_version = pangolin.pangolin_version
        File pangolin_lineage = pangolin.lineage
        String nextclade_version = nextclade.nextclade_version
        File nextclade_json = nextclade.nextclade_json
        File auspice_json = nextclade.auspice_json
        File nextclade_csv = nextclade.nextclade_csv
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
        cpu:    2
        memory:    "8 GiB"
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
        memory: "3 GB"
        cpu: 2
        disks: "local-disk 50 HDD"
        dx_instance_type: "mem1_ssd1_v2_x2"
    }
}

task transfer_outputs {
    input {
        String out_dir
        File cat_fastas
        File pangolin_lineage
        File nextclade_json
        File auspice_json
        File nextclade_csv
    }

    String outdir = sub(out_dir, "/$", "")

    command <<<
        
        gsutil -m cp ~{cat_fastas} ~{outdir}/multifasta/
        gsutil -m cp ~{pangolin_lineage} ~{outdir}/pangolin_out/
        gsutil -m cp ~{nextclade_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{auspice_json} ~{outdir}/nextclade_out/
        gsutil -m cp ~{nextclade_csv} ~{outdir}/nextclade_out/
       
       transferdate=`date`
        echo $transferdate | tee TRANSFERDATE
        
    >>>

    output {
        String transfer_date = read_string("TRANSFERDATE")
    }

    runtime {
        docker: "theiagen/utility:1.0"
        memory: "1 GB"
        cpu: 1
        disks: "local-disk 10 SSD"
    }
}
