# classifyCOVIDlineage

Takes the consensus fasta SARS-CoV-2 genome assembly outputs of IlluminaPreprocessAssembly.wdl and NanoporeGuppyAssembly.wdl and:
1. uses Pangolin to assign PangoLineages
2. uses Nextclade to assign clade
3. exports the outputs to your chosen google bucket
4. Generates data summary tables using Molly's python scripts

The google bucket to which the outputs should be sent should be set as a Terra input as a String in double quotes

External tools used in this workflow were from publicly available Docker images:
1. General utilities docker images: ubuntu, mchether/py3-bio:v2, theiagen/utility:1.0
2. Pangolin: 9.	Rambaut A, Holmes EC, O’Toole Á, Hill V, McCron JT, Ruis C, du Plessis L, Pybus OG. A dynamic nomenclature proposal for SARS-CoV-2 lineages to assist genomic epidemiology. Nat Microbiol 5, 1403–1407 (2020). https://doi.org/10.1038/s41564-020-0770-5
  docker image: staphb/pangolin
3. Nextclade: 10.	Hadfield J, Megill C, Bell SM, Huddleston J, Potter J, Callender C, Sagulenko P, Bedford T, Neher RA, Nextstrain: real-time tracking of pathogen evolution, Bioinformatics, Volume 34, Issue 23, 01 December 2018, Pages 4121–4123, https://doi.org/10.1093/bioinformatics/bty407
  docker image: nextstrain/nextclade:0.13.0
