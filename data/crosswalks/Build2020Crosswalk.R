rm(list = ls())

library(tidyverse)
library(sf)

# block-to-VTD assignments in the 2010 census
block.vtd.2020 <- read_csv("data/block-assignment/MilwaukeeCounty_Block_VTD_2020.csv",
                           col_types = "ccccn")


# wards drawn in 2011
wards.2011 <- st_read("data/ward-shp/MilwaukeeCounty_2011.geojson") %>%
  st_drop_geometry() %>%
  as_tibble() %>%
  mutate(wardsource_row = row_number()) %>%
  select(-county_fips) %>%
  mutate(ward_name_v2 = paste(word(ward_name_v2, 1, -2), str_pad(word(ward_name_v2, -1),
                                                                 pad = "0", width = 4,
                                                                 side = "left")),
         # additional munges to match VTD style
         ward_name_v2 = case_when(
           ward_name_v2 == "Bayside - V 001B" ~ "Bayside - V 001S",
           ward_name_v2 == "Bayside - V 003B" ~ "Bayside - V 003S",
           ward_name_v2 == "Glendale - C 011E" ~ "Glendale - C 011S",
           ward_name_v2 == "Glendale - C 008E" ~ "Glendale - C 008S",
           TRUE ~ ward_name_v2
         ))

# unique VTD names from 2010
vtd.2020 <- block.vtd.2020 %>%
  group_by(vtd_name_2020) %>%
  summarise(pop_2020 = sum(pop_2020))

# confirm that VTDs from the 2020 census match the names of the wards drawn in 2011
compare.VTD2010.with.ward2011 <- wards.2011 %>%
  full_join(vtd.2020, by = c("ward_name_v2" = "vtd_name_2020")) %>%
  rename(ward_2011 = ward_name)

##   check that wards are uniquely matched
n_distinct(compare.VTD2010.with.ward2011$ward_2011) == nrow(compare.VTD2010.with.ward2011)

blocks.to.ward2011 <- block.vtd.2020 %>%
  inner_join(compare.VTD2010.with.ward2011 %>%
               select(vtd_name_2020 = ward_name_v2, ward_2011))
################################################################################

################################################################################
# intersect 2020 blocks with 2022 wards

wards.2022 <- st_read("data/ward-shp/Milwaukeecounty_2022.geojson")

# here are the block polygons, retrieved from the Census API
block.shp.2020 <- tigris::blocks("WI","MILWAUKEE",2020)

# convert the polygons to centroid points
block.point.2020 <- block.shp.2020 %>%
  select(block_2020 = GEOID20) %>%
  st_transform(crs = st_crs(wards.2022)) %>%
  # st_point_on_surface ensures that the center point is WITHIN the polygon(s)
  mutate(geometry = st_point_on_surface(geometry))

# perform the intersection (this may take some time)
block2020.ward2022.int <- block.point.2020 %>%
  st_intersection(wards.2022) %>%
  st_drop_geometry()

# not all the blocks fell within a ward polygon
compare.block.intersections <- block.vtd.2020 %>%
  left_join(block2020.ward2022.int) %>%
  select(block_2020, vtd_2020, ward_2022 = ward_name, pop_2020)

# confirm that all the unmatched blocks have a population of 0
compare.block.intersections %>%
  filter(is.na(ward_2022)) %>%
  group_by(pop_2020) %>%
  summarise(count = n())
################################################################################

################################################################################
# complete the crosswalk
blocks.2020.with.ward.assignments <- blocks.to.ward2011 %>%
  left_join(compare.block.intersections) %>%
  select(block_2020, pop_2020, ward_2011, ward_2022)

# confirm that pop totals match, all cases present, no duplicates
sum(blocks.2020.with.ward.assignments$pop_2020) == sum(block.vtd.2020$pop_2020)

# confirm that all blocks unmatched to a ward are unpopulated
blocks.2020.with.ward.assignments %>%
  filter(is.na(ward_2011)) %>%
  group_by(pop_2020) %>%
  summarise(count = n())

blocks.2020.with.ward.assignments %>%
  filter(is.na(ward_2022)) %>%
  group_by(pop_2020) %>%
  summarise(count = n())

write_csv(blocks.2020.with.ward.assignments, "data/crosswalks/Blocks2020_with_Ward2022_and_Ward2011.csv")
