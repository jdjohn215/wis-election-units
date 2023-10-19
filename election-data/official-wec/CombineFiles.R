rm(list = ls())

library(tidyverse)

###########################################################################
pres.12 <- readxl::read_excel("election-data/official-wec/2012-11-06_Ward_by_Ward.xls",
                                 sheet = 2,
                                 skip = 10) %>%
  select(county = 1, rep_unit = 2, total = 3, rep = 4, dem = 5) %>%
  mutate(across(.cols = where(is.character), .fns = str_to_upper)) %>%
  mutate(county = zoo::na.locf(county),
         rep_unit = str_to_upper(rep_unit),
         year = 2012,
         office = "president") %>%
  filter(str_detect(county, "TOTAL", negate = T),
         str_detect(rep_unit, "TOTAL", negate = T))
sum(pres.12$total)
###########################################################################

gov.14 <- readxl::read_excel("election-data/official-wec/2014_GeneralElection_GovernorContest.xlsx") %>%
  # create total column because WEC didn't include one
  mutate(total = rowSums(.[,7:17])) %>%
  select(county = 1, rep_unit = 3, total, dem = 7, rep = 8) %>%
  mutate(county = zoo::na.locf(county),
         rep_unit = str_to_upper(rep_unit),
         year = 2014,
         office = "governor")
sum(gov.14$total)
###########################################################################

pres.16 <- readxl::read_excel("election-data/official-wec/President_2016_ReportingUnits_AfterRecount.xlsx",
                              skip = 10) %>%
  select(county = 1, rep_unit = 2, total = 3, dem = 5, rep = 4) %>%
  mutate(county = zoo::na.locf(county),
         rep_unit = str_to_upper(rep_unit),
         year = 2016,
         office = "president") %>%
  filter(str_detect(county, "TOTAL", negate = T),
         str_detect(rep_unit, "TOTAL", negate = T))
sum(pres.16$total)
###########################################################################

gov.18 <- readxl::read_excel("election-data/official-wec/Ward_by_Ward_Report-Statewide-Constitution-Offices_2018.xlsx",
                              sheet = 2, skip = 10) %>%
  select(county = 1, rep_unit = 2, total = 3, dem = 5, rep = 4) %>%
  mutate(county = zoo::na.locf(county),
         rep_unit = str_to_upper(rep_unit),
         year = 2018,
         office = "governor") %>%
  filter(str_detect(county, "TOTAL", negate = T),
         str_detect(rep_unit, "TOTAL", negate = T))
sum(gov.18$total)
###########################################################################

pres.20 <- readxl::read_excel("election-data/official-wec/President_2020_ReportingUnits_AfterRecount.xlsx") %>%
  # create total column because WEC didn't include one
  mutate(total = rowSums(.[,7:19])) %>%
  select(county = 1, rep_unit = 3, total, dem = 7, rep = 8) %>%
  mutate(county = zoo::na.locf(county),
         rep_unit = str_to_upper(rep_unit),
         year = 2020,
         office = "president") %>%
  filter(str_detect(county, "TOTAL", negate = T),
         str_detect(rep_unit, "TOTAL", negate = T))
sum(pres.20$total)
###########################################################################

gov.22 <- readxl::read_excel("election-data/official-wec/Ward by Ward Report_Governor_2022.xlsx",
                             sheet = 2, skip = 10) %>%
  select(county = 1, rep_unit = 2, total = 3, dem = 4, rep = 5) %>%
  mutate(county = zoo::na.locf(county),
         rep_unit = str_to_upper(rep_unit),
         year = 2022,
         office = "governor") %>%
  filter(str_detect(county, "TOTAL", negate = T),
         str_detect(rep_unit, "TOTAL", negate = T))
sum(gov.22$total)
###########################################################################

###########################################################################
all.races.rep.units <- bind_rows(pres.12, gov.14, pres.16, gov.18,
                                 pres.20, gov.22)
# verify
all.races.rep.units %>%
  group_by(year, office) %>%
  summarise(across(.cols = where(is.numeric), .fns = sum))

write_csv(all.races.rep.units, "election-data/OriginalWEC_Pres-GOV_2012-2022_ReportingUnits.csv")
