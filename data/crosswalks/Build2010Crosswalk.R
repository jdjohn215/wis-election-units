rm(list = ls())

library(tidyverse)
library(sf)

# block-to-VTD assignments in the 2010 census
block.vtd.2010 <- read_csv("data/block-assignment/MilwaukeeCounty_Block_VTD_2010.csv",
                           col_types = "ccccn")

# wards drawn in 2002
wards.2002 <- st_read("data/ward-shp/MilwaukeeCounty_2002.geojson") %>%
  st_drop_geometry() %>%
  as_tibble()

# unique VTD names from 2010
vtd.2010 <- block.vtd.2010 %>%
  group_by(vtd_name_2010) %>%
  summarise(pop_2010 = sum(pop_2010))

# confirm that VTDs from the 2010 census match the names of the wards drawn in 2002
compare.VTD2010.with.ward2002 <- wards.2002 %>%
  full_join(vtd.2010, by = c("ward_name" = "vtd_name_2010")) %>%
  rename(ward_2002 = ward_name)

##   check that wards are uniquely matched
n_distinct(compare.VTD2010.with.ward2002$ward_2002) == nrow(compare.VTD2010.with.ward2002)

##  there are 2 VTDs with no equivalent in the 2002 wards
##  this confirms that they have 0 population
compare.VTD2010.with.ward2002 %>%
  filter(is.na(county_fips))
################################################################################

################################################################################
# intersect 2010 blocks with 2011 wards

wards.2011 <- st_read("data/ward-shp/Milwaukeecounty_2011.geojson")

# here are the block polygons, retrieved from the Census API
block.shp.2010 <- tigris::blocks("WI","MILWAUKEE",2010)

# convert the polygons to centroid points
block.point.2010 <- block.shp.2010 %>%
  select(block_2010 = GEOID10) %>%
  st_transform(crs = st_crs(wards.2011)) %>%
  # st_point_on_surface ensures that the center point is WITHIN the polygon(s)
  mutate(geometry = st_point_on_surface(geometry))

# perform the intersection (this may take some time)
block2010.ward2011.int <- block.point.2010 %>%
  st_intersection(wards.2011) %>%
  st_drop_geometry()

# not all the blocks fell within a ward polygon
compare.block.intersections <- block.vtd.2010 %>%
  left_join(block2010.ward2011.int) %>%
  select(block_2010, vtd_2010, ward_2011 = ward_name, pop_2010)

# confirm that all the unmatched blocks have a population of 0
compare.block.intersections %>%
  filter(is.na(ward_2011)) %>%
  group_by(pop_2010) %>%
  summarise(count = n())
################################################################################

################################################################################
# complete the crosswalk
blocks.2010.with.ward.assignments <- block.vtd.2010 %>%
  left_join(compare.block.intersections) %>%
  select(block_2010, pop_2010, ward_2002 = vtd_name_2010, ward_2011) %>%
  # remove the two 2010 VTDs that aren't matched to 2002 wards
  #   they are unpopulated areas
  mutate(ward_2002 = if_else(ward_2002 %in% c("Bayside - V9999",
                                              "Brown Deer - V 9999"),
                             true = NA,
                             false = ward_2002))

# confirm that pop totals match, all cases present, no duplicates
sum(blocks.2010.with.ward.assignments$pop_2010) == sum(block.vtd.2010$pop_2010)

# confirm that all blocks unmatched to a ward are unpopulated
blocks.2010.with.ward.assignments %>%
  filter(is.na(ward_2002)) %>%
  group_by(pop_2010) %>%
  summarise(count = n())

blocks.2010.with.ward.assignments %>%
  filter(is.na(ward_2011)) %>%
  group_by(pop_2010) %>%
  summarise(count = n())

write_csv(blocks.2010.with.ward.assignments, "data/crosswalks/Blocks2010_with_Ward2002_and_Ward2011.csv")
