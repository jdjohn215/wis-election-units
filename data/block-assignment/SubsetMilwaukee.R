rm(list = ls())

library(tidyverse)
library(tidycensus)

dec.vars.10 <- load_variables(2010, "pl", cache = T)
dec.vars.20 <- load_variables(2020, "pl", cache = T)

block.pop.2010 <- get_decennial(geography = "block",
                                variables = "P001001",
                                year = 2010,
                                state = "WI",
                                county = "MILWAUKEE",
                                sumfile = "pl") %>%
  select(block_2010 = GEOID, pop_2010 = value)
block.pop.2020 <- get_decennial(geography = "block",
                                variables = "P1_001N",
                                year = 2020,
                                state = "WI",
                                county = "MILWAUKEE",
                                sumfile = "pl") %>%
  select(block_2020 = GEOID, pop_2020 = value)


vtd.names.2020 <- vroom::vroom("data/block-assignment/NAMES_ST55_WI_2020/NAMES_ST55_WI_VTD.txt",
                               col_types = "c") %>%
  select(COUNTYFP, DISTRICT, vtd_name_2020 = NAME)

block.vtd.2020 <- vroom::vroom("data/block-assignment/BlockAssign_ST55_WI_2020/BlockAssign_ST55_WI_VTD.txt",
                               col_types = "c") %>%
  inner_join(vtd.names.2020) %>%
  rename(block_2020 = BLOCKID, vtd_2020 = DISTRICT) %>%
  inner_join(block.pop.2020)

vtd.names.2010 <- vroom::vroom("data/block-assignment/NAMES_ST55_WI_2010/NAMES_ST55_WI_VTD.txt",
                               col_types = "c") %>%
  select(COUNTYFP, DISTRICT, vtd_name_2010 = NAME)

block.vtd.2010 <- vroom::vroom("data/block-assignment/BlockAssign_ST55_WI_2010/BlockAssign_ST55_WI_VTD.txt",
                               col_types = "c") %>%
  inner_join(vtd.names.2010) %>%
  rename(block_2010 = BLOCKID, vtd_2010 = DISTRICT) %>%
  inner_join(block.pop.2010)

write_csv(block.vtd.2010, "data/block-assignment/MilwaukeeCounty_Block_VTD_2010.csv")
write_csv(block.vtd.2020, "data/block-assignment/MilwaukeeCounty_Block_VTD_2020.csv")


block.relationship <- vroom::vroom("data/tab2010_tab2020_st55_wi.txt") %>%
  mutate(block_2010 = paste0(STATE_2010, COUNTY_2010, TRACT_2010, BLK_2010),
         block_2020 = paste0(STATE_2020, COUNTY_2020, TRACT_2020, BLK_2020)) %>%
  select(block_2010, block_2020, AREALAND_2010, AREALAND_2020, AREALAND_INT,
         BLOCK_PART_FLAG_O, BLOCK_PART_FLAG_R) %>%
  inner_join(block.pop.2010) %>%
  inner_join(block.pop.2020)
write_csv(block.relationship, "data/block-assignment/MilwaukeeCounty_BlockRelationship_2010to2020.csv")
