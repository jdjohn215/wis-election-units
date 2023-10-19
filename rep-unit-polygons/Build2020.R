rm(list = ls())

library(tidyverse)
library(sf)

pres20 <- readxl::read_excel("election-data/President_2020_ReportingUnits_AfterRecount.xlsx") %>%
  janitor::clean_names() %>%
  mutate(total = rowSums(.[7:19])) %>%
  filter(county_name == "MILWAUKEE") %>%
  select(reporting_unit, total, biden = joseph_r_biden_kamala_d_harris,
         trump = donald_j_trump_michael_r_pence)

# expand a list of numbers including dashes into full list
expand_dash <- function(wardstring){
  wardstring.elements <- unlist(str_split(wardstring, ","))
  wardstring.list <- lapply(
    X = wardstring.elements,
    FUN = function(text){
      if(str_detect(text, "-")){
        limits <- as.numeric(unlist(strsplit(text, '-')))
        paste(seq(limits[1], limits[2]), collapse = ", ")
      } else {
        text
      }
    }
  )
  str_remove_all(paste(wardstring.list, collapse = ","), " ")
}


rep.units.to.wards <- pres20 %>%
  select(reporting_unit) %>%
  separate(reporting_unit, into = c("municipality", "wards"), 
           sep = " Wards | Ward ", remove = F) %>%
  separate(municipality, into = c("ctv", "muni"), sep = " of ") %>%
  mutate(ctv = str_sub(ctv, 1, 1)) %>%
  rowwise() %>%
  mutate(wards = expand_dash(wards)) %>%
  ungroup() %>%
  separate(col = wards, into = c("w1","w2","w3","w4","w5"), sep = ",") %>%
  pivot_longer(cols = starts_with("w"), names_to = "wardcount", values_to = "ward") %>%
  filter(!is.na(ward)) %>%
  select(-wardcount)

ward.shp.2020 <- st_read("data/ward-shp/Milwaukeecounty_2011.geojson")

d <- rep.units.to.wards %>%
  mutate(ward_name = paste(str_to_title(muni), "-", ctv, ward),
         # additional munges to match ward LTSB style
         ward_name = case_when(
           ward_name == "Bayside - V 1S" ~ "Bayside - V 1B",
           ward_name == "Bayside - V 3S" ~ "Bayside - V 3B",
           ward_name == "Glendale - C 11S" ~ "Glendale - C 11E",
           ward_name == "Glendale - C 8S" ~ "Glendale - C 8E",
           TRUE ~ ward_name)) %>%
  select(reporting_unit, ward_name) %>%
  full_join(ward.shp.2020)



