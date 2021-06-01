#!/usr/bin/env Rscript

# Demo script to subset tree and collect data for Anvio plots

library(readr)
library(dplyr)
library(tidyr)
library(treeio)

# Read the GTDBtk taxonomy table
taxonomy <- read_tsv(
  'data/seminar_04_mark_eva_phylo/gtdbtk.ar122.summary.tsv',
  col_types = cols()
) %>%
  # Rename "user_genome" to "mag" and get rid of leading "d__" etc. prefixes for the ranks
  transmute(
    mag = user_genome,
    classification = stringr::str_remove_all(classification, '[a-z]__')
  ) %>%
  # Separate the classification string into the differently ranked taxa
  separate(classification, c('domain', 'phylum', 'class', 'order', 'family', 'genus', 'species'), sep = ';')

# Read the table with abundances
counts <- read_tsv(
  'data/seminar_04_mark_eva_phylo/mean_tpms_per_sample_type.tsv.gz',
  col_types = cols(.default = col_double(), mag = col_character())
)

# Combine taxonomy and abundances and write to a file with "mag" as the first column.
# The mag name will be used by Anvi'o to combine the tree with the data.
taxonomy %>%
  inner_join(counts, by = 'mag') %>%
  write_tsv('anvio_output/archaeal_mags.tsv')

# Read the GTDBtk tree containing both reference genomes and the project MAGs
phylo <- read.tree('data/seminar_04_mark_eva_phylo/gtdbtk.ar122.classify.tree')

# Subset to contain only project MAGs
phylo <- drop.tip(
  phylo, 
  phylo$tip.label[!phylo$tip.label %in% (taxonomy %>% filter(domain == 'Archaea') %>% pull(mag))]
)

# Write the subset tree to file for later use in Anvi'o
write.tree(phylo, 'anvio_output/archaea.newick')
