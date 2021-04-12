# classifyCOVIDlineage

Takes the consensus fasta SARS-CoV-2 genome assembly outputs of IlluminaPreprocessAssembly.wdl and NanoporeGuppyAssembly.wdl and:
1. uses Pangolin to assign PangoLineages
2. uses Nextclade to assign clade
3. exports the outputs to your chosen google bucket
4. Generates data summary tables using Molly's python scripts

The google bucket to which the outpus should be sent should be set as a Terra input as a String in double quotes
