rm(list = ls())

library(tidyverse)
library(tidycensus)

blocks.2000 <- read_csv("data/crosswalks/Blocks2000_with_Ward2002.csv",
                        col_types = "ccn")
blocks.2010 <- read_csv("data/crosswalks/Blocks2010_with_Ward2002_and_Ward2011.csv",
                        col_types = "cncc")
blocks.2020 <- read_csv("data/crosswalks/Blocks2020_with_Ward2022_and_Ward2011.csv",
                        col_types = "cncc")

##############################################################################
# block adult population by race and hispanic/latino for the year 2000
dec.vars.2000 <- load_variables(2000, "pl", cache = T)
block.demog.2000 <- get_decennial("block", table = "PL004", year = 2000,
                                  sumfile = "pl", state = "WI", county = "MILWAUKEE")
block.demog.2000.v2 <- block.demog.2000 %>%
  pivot_wider(names_from = variable, values_from = value) %>%
  select(block_2000 = GEOID, vap = PL004001, vap_white = PL004005, vap_black = PL004006,
         vap_hisp = PL004002, vap_aian = PL004007, vap_asian = PL004008,
         vap_nhpi = PL004009, vap_other = PL004010, vap_two = PL004011) %>%
  pivot_longer(cols = starts_with("vap"), names_to = "group", values_to = "count")
sum(block.demog.2000.wide$vap)

##############################################################################
# block adult population by race and hispanic/latino for the year 2010
dec.vars.2010 <- load_variables(2010, "pl", cache = T)
block.demog.2010 <- get_decennial("block", table = "P004", year = 2010,
                                  sumfile = "pl", state = "WI", county = "MILWAUKEE")
block.demog.2010.v2 <- block.demog.2010 %>%
  pivot_wider(names_from = variable, values_from = value) %>%
  select(block_2010 = GEOID, vap = P004001, vap_white = P004005, vap_black = P004006,
         vap_hisp = P004002, vap_aian = P004007, vap_asian = P004008,
         vap_nhpi = P004009, vap_other = P004010, vap_two = P004011) %>%
  pivot_longer(cols = starts_with("vap"), names_to = "group", values_to = "count")
sum(block.demog.2010.wide$vap)

##############################################################################
# block adult population by race and hispanic/latino for the year 2020
dec.vars.2020 <- load_variables(2020, "pl", cache = T)
block.demog.2020 <- get_decennial("block", table = "P4", year = 2020,
                                  sumfile = "pl", state = "WI", county = "MILWAUKEE")
block.demog.2020.v2 <- block.demog.2020 %>%
  pivot_wider(names_from = variable, values_from = value) %>%
  select(block_2020 = GEOID, vap = P4_001N, vap_white = P4_005N, vap_black = P4_006N,
         vap_hisp = P4_002N, vap_aian = P4_007N, vap_asian = P4_008N,
         vap_nhpi = P4_009N, vap_other = P4_010N, vap_two = P4_011N) %>%
  pivot_longer(cols = starts_with("vap"), names_to = "group", values_to = "count")
sum(block.demog.2020.wide$vap)

##############################################################################
##############################################################################
# Aggregate the demographics for each vintage of wards and the beginning at end of
#   each decade.
#   Linearly interpolate the population for the intervening election years.

wards.2002 <- inner_join(
  # calculate 2002 ward demographics in 2000
  blocks.2000 %>%
    inner_join(block.demog.2000.v2) %>%
    group_by(ward_2002, group) %>%
    summarise(count_2000 = sum(count)) %>%
    ungroup(),
  # calculate 2002 ward demographics in 2010
  blocks.2010 %>%
    inner_join(block.demog.2010.v2) %>%
    group_by(ward_2002, group) %>%
    summarise(count_2010 = sum(count)) %>%
    ungroup()
) %>%
  mutate(change_decade = count_2010 - count_2000) %>%
  mutate(est_2002 = count_2000 + (change_decade*0.2),
         est_2004 = count_2000 + (change_decade*0.4),
         est_2006 = count_2000 + (change_decade*0.6),
         est_2008 = count_2000 + (change_decade*0.8)) %>%
  select(ward_2002, group, count_2000, est_2002, est_2004, est_2006, est_2008, count_2010)
write_csv(wards.2002, "data/ward-demographics/Wards2002_VAP_2000to2010.csv")

##################################################################
wards.2011 <- inner_join(
  # calculate 2011 ward demographics in 2010
  blocks.2010 %>%
    inner_join(block.demog.2010.v2) %>%
    group_by(ward_2011, group) %>%
    summarise(count_2010 = sum(count)) %>%
    ungroup(),
  # calculate 2011 ward demographics in 2020
  blocks.2020 %>%
    inner_join(block.demog.2020.v2) %>%
    group_by(ward_2011, group) %>%
    summarise(count_2020 = sum(count)) %>%
    ungroup()
) %>%
  mutate(change_decade = count_2020 - count_2010) %>%
  mutate(est_2012 = count_2010 + (change_decade*0.2),
         est_2014 = count_2010 + (change_decade*0.4),
         est_2016 = count_2010 + (change_decade*0.6),
         est_2018 = count_2010 + (change_decade*0.8)) %>%
  select(ward_2011, group, count_2010, est_2012, est_2014, est_2016, est_2018, count_2020)
write_csv(wards.2011, "data/ward-demographics/Wards2011_VAP_2010to2020.csv")

##################################################################
wards.2022 <- blocks.2020 %>%
  inner_join(block.demog.2020.v2) %>%
  group_by(ward_2022, group) %>%
  summarise(count_2020 = sum(count)) %>%
  ungroup()
write_csv(wards.2022, "data/ward-demographics/Wards2022_VAP_2020.csv")

